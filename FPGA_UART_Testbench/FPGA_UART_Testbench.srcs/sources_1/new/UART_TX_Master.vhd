library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.std_logic_misc.all;

entity UART_TX_Master is
  generic (
    CLOCK_FREQ		:positive := 20_000_000;			-- czestotliwosc zegata w [Hz]
    MIN_BAUD_RATE		:positive := 110;				-- minimalna predkosc nadawania w [bodach]
    NUMBER_OF_WORD_BITS		:natural range 5 to 8 := 8;			-- liczba bitow slowa danych (5-8)
    NUMBER_OF_PARITY_BITS       :natural range 0 to 1 := 1;                     -- liczba bitow parzystosci (0-1)
    NUMBER_OF_STOP_BITS            :natural range 0 to 2 := 2                     -- liczba bitow stopu (1-2)
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

  type     STATES_TYPE		is (IDLE_WAIT, RECEIVING_START, RECEIVING_WORD, RECEIVING_PARITY, RECEIVING_STOP);	-- lista etapow pracy odbiornika
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
            if (WORD_READY = '1') then
                TX <= '1';
            end if;
         when RECEIVING_START =>							-- obsluga stanu RECEIVING_START
           null;

         when RECEIVING_WORD =>							-- obsluga stanu DANA
            null;

         when RECEIVING_PARITY =>						-- obsluga stanu PARZYSTOSC
            null;

         when RECEIVING_STOP =>							-- obsluga stanu STOP
           null;

       end case;							-- zakonczenie instukcji warunkowego wyboru

     end if;								-- zakonczenie instukcji warunkowej porcesu

   end process;								-- zakonczenie ciala procesu

end RTL;
