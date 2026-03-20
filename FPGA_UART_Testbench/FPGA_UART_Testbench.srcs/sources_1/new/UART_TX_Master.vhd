library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.std_logic_misc.all;

entity UART_TX_Master is
  generic (
    CLOCK_FREQ		:positive;			-- czestotliwosc zegata w [Hz]
    MIN_BAUD_RATE		:positive;				-- minimalna predkosc nadawania w [bodach]
    NUMBER_OF_WORD_BITS		:natural range 5 to 8;			-- liczba bitow slowa danych (5-8)
    NUMBER_OF_PARITY_BITS       :natural range 0 to 1;                     -- liczba bitow parzystosci (0-1)
    NUMBER_OF_STOP_BITS            :natural range 0 to 2;                     -- liczba bitow stopu (1-2)
    PARITY_TYPE         :std_logic -- 0 to even, 1 to odd
  );
  
  port (
    CLK	            :in  std_logic;					-- zegar taktujacy
    RST		        :in  std_logic;					-- sygnal resetowania
    CYCLES_PER_BIT	:in  natural range 0 to CLOCK_FREQ/MIN_BAUD_RATE;	-- liczba taktow zegara dla jednego bodu
    WORD	        :in std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);	-- odebrane slowo danych
    WORD_READY      :in std_logic;
    
    TX		        :out  std_logic;					-- odebrany sygnal szeregowy
    BUSY            :out std_logic;					-- flaga potwierdzenia odbioru
    TX_ERROR	    :out std_logic					-- flaga wykrycia bledu w odbiorze
  );
end UART_TX_Master;

architecture RTL of UART_TX_Master is

  signal   output_word_buffer: std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);			-- podwojny rejestr sygnalu RX

  type     STATES_TYPE		is (IDLE_WAIT, TRANSMITTING_START, TRANSMITTING_WORD, TRANSMITTING_PARITY, TRANSMITTING_STOP);	-- lista etapow pracy odbiornika
  signal   state		:STATES_TYPE;						-- rejestr maszyny stanow odbiornika

  constant MAX_CYCLES_FOR_BIT	:positive := CLOCK_FREQ/MIN_BAUD_RATE;		-- czas jednego bodu - liczba taktow zegara
  signal   cycles_in_current_bit  	:natural range 0 to MAX_CYCLES_FOR_BIT-1;		-- licznik czasu jednego bodu
  signal   number_of_bits_transmitted  	:natural range 0 to NUMBER_OF_WORD_BITS-1;			-- licznik odebranych bitow danych lub stopu

  signal   internal_error	:std_logic;					-- rejestr (flaga) wykrytego bledu odbioru

begin
    -- badanie poprawnosci ustawien zegarow
    assert (CLOCK_FREQ >= 2 * MIN_BAUD_RATE)
    report "SERIAL_TX: nieprawidlowa wartosc parametru CLOCK_FREQ"
    severity error;

   process (RST, CLK) is							-- proces odbiornika
   begin								-- cialo procesu odbiornika

     if (RST='1') then							-- asynchroniczna inicjalizacja rejestrow
       output_word_buffer	<= (others => '0');					-- wyzerowanie rejestru sygnalu RX
       state	<= IDLE_WAIT;						-- poczatkowy stan pracy odbiornika
       cycles_in_current_bit  <= 0;							-- wyzerowanie licznika czasu bodu
       number_of_bits_transmitted  <= 0;							-- wyzerowanie licznika odebranych bitow
       
       internal_error 	<= '0';							-- wyzerowanie rejestru bledu odbioru
       
       TX <= '0';
       BUSY	<= '0';							-- wyzerowanie flagi potwierdzenia odbioru
       TX_ERROR	<= '0';							-- wyzerowanie flagi wykrycia bledu w odbiorze

     elsif (rising_edge(CLK)) then					-- synchroniczna praca odbiornika

       BUSY     <= '0';						-- defaultowe skasowanie flagi potwierdzenia odbioru
       TX_ERROR       <= '0';						-- defaultowe skasowanie flagi wykrycia bledu w odbiorze
       TX <= '0';
        
       case state is							-- badanie aktualnego stanu maszyny stanow

         when IDLE_WAIT =>						-- obsluga stanu IDLE_WAIT
            BUSY <= '0';
            if (WORD_READY = '1') then
                output_word_buffer <= WORD;
                BUSY <= '1';
                state <= TRANSMITTING_START;
            end if;
            
         when TRANSMITTING_START =>							-- obsluga stanu RECEIVING_START
            BUSY <= '1';
            if (cycles_in_current_bit /= CYCLES_PER_BIT/2) then				-- badanie odliczania pol okresu bodu
                cycles_in_current_bit <= cycles_in_current_bit + 1;
                TX <= '1';					-- zwiekszenie o 1 stanu licznika czasu
            else								-- zakonczenie odliczania polowy okresu bodu
                cycles_in_current_bit <= 0;
                TX <= '0';						-- wyzerowanie licznika czasu bodu
                state    <= TRANSMITTING_WORD;						-- przejscie do stanu DANA
           end if;							-- zakonczenie instukcji warunkowej

         when TRANSMITTING_WORD =>							-- obsluga stanu DANA
            BUSY <= '1';
            if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then
                cycles_in_current_bit <= cycles_in_current_bit + 1;
        
            else
                cycles_in_current_bit <= 0;
        
                -- SHIFT OUT CURRENT BIT (LSB first or MSB first depending on design)
                TX <= output_word_buffer(0);  -- example: LSB first
        
                output_word_buffer <= '0' & output_word_buffer(output_word_buffer'left downto 1);
        
                -- bit counter
                if (number_of_bits_transmitted /= NUMBER_OF_WORD_BITS-1) then
                    number_of_bits_transmitted <= number_of_bits_transmitted + 1;
                else
                    number_of_bits_transmitted <= 0;
                    if (NUMBER_OF_PARITY_BITS = 1) then
                        state <= TRANSMITTING_PARITY;
                    else
                        state <= TRANSMITTING_STOP;
                    end if;
                end if;
                
            end if;

         when TRANSMITTING_PARITY =>						-- obsluga stanu PARZYSTOSC
            BUSY <= '1';
            if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then
                cycles_in_current_bit <= cycles_in_current_bit + 1;
        
            else
                cycles_in_current_bit <= 0;
        
                -- transmit parity bit (even parity example)
                -- even parity = XOR of all bits in word
                if (PARITY_TYPE = '0') then
                    TX <= XOR_REDUCE(output_word_buffer);
                else
                    TX <= not XOR_REDUCE(output_word_buffer);
                end if;
        
                -- after parity bit -> go to STOP state
                state <= TRANSMITTING_STOP;
            end if;

         when TRANSMITTING_STOP =>							-- obsluga stanu STOP
            BUSY <= '1';
            if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then
                cycles_in_current_bit <= cycles_in_current_bit + 1;
        
            else
                cycles_in_current_bit <= 0;
        
                -- transmit STOP bit = logic '1' (UART idle level)
                TX <= '1';
        
                -- handle multiple stop bits
                if (number_of_bits_transmitted /= NUMBER_OF_STOP_BITS-1) then
                    number_of_bits_transmitted <= number_of_bits_transmitted + 1;
                else
                    -- finished frame
                    number_of_bits_transmitted <= 0;
                    -- go back to IDLE or ready state
                    state <= IDLE_WAIT;
                end if;
            end if;

       end case;							-- zakonczenie instukcji warunkowego wyboru

     end if;								-- zakonczenie instukcji warunkowej porcesu

   end process;								-- zakonczenie ciala procesu

end RTL;
