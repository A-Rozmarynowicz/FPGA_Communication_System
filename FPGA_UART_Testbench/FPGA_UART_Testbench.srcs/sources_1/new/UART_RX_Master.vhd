library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.std_logic_misc.all;
use     ieee.numeric_std.all;

entity UART_RX_Master is
  generic (
    CLOCK_FREQ		:positive;			-- czestotliwosc zegata w [Hz]
    MIN_BAUD_RATE		:positive;				-- minimalna predkosc nadawania w [bodach]
    NUMBER_OF_WORD_BITS		:natural range 5 to 8;			-- liczba bitow slowa danych (5-8)
    NUMBER_OF_PARITY_BITS       :natural range 0 to 1;                     -- liczba bitow parzystosci (0-1)
    NUMBER_OF_STOP_BITS            :natural range 0 to 2;                     -- liczba bitow stopu (1-2)
    PARITY_TYPE         :std_logic -- 0 to even, 1 to odd
  );
  
  port (
    CLK	        :in  std_logic;					-- zegar taktujacy
    RST		        :in  std_logic;					-- sygnal resetowania
    CYCLES_PER_BIT	:in  natural range 0 to CLOCK_FREQ/MIN_BAUD_RATE;	-- liczba taktow zegara dla jednego bodu
    RX		        :in  std_logic;					-- odebrany sygnal szeregowy
    WORD	        :out std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);	-- odebrane slowo danych
    READY	        :out std_logic;					-- flaga potwierdzenia odbioru
    RX_ERROR	    :out std_logic					-- flaga wykrycia bledu w odbiorze
  );
end UART_RX_Master;

architecture RTL of UART_RX_Master is

  signal   input_rx_buffer	:std_logic_vector(0 to 1);			-- podwojny rejestr sygnalu RX

  type     STATES_TYPE		is (IDLE_WAIT, RECEIVING_START, RECEIVING_WORD, RECEIVING_PARITY, RECEIVING_STOP);	-- lista etapow pracy odbiornika
  signal   state		:STATES_TYPE;						-- rejestr maszyny stanow odbiornika

  constant MAX_CYCLES_FOR_BIT	:positive := CLOCK_FREQ/MIN_BAUD_RATE;		-- czas jednego bodu - liczba taktow zegara
  signal   cycles_in_current_bit  	:natural range 0 to MAX_CYCLES_FOR_BIT-1;		-- licznik czasu jednego bodu
  signal   number_of_bits_received  	:natural range 0 to NUMBER_OF_WORD_BITS-1;			-- licznik odebranych bitow danych lub stopu

  signal   final_word_buffer	:std_logic_vector(WORD'range);			-- rejestr kolejno odebranych bitow danych
  signal   internal_error	:std_logic;					-- rejestr (flaga) wykrytego bledu odbioru

begin
    -- badanie poprawnosci ustawien zegarow
    assert (CLOCK_FREQ >= 2 * MIN_BAUD_RATE)
    report "SERIAL_RX: nieprawidlowa wartosc parametru CLOCK_FREQ"
    severity error;

   process (RST, CLK) is							-- proces odbiornika
   begin								-- cialo procesu odbiornika

     if (RST='1') then							-- asynchroniczna inicjalizacja rejestrow
       input_rx_buffer	<= (others => '0');					-- wyzerowanie rejestru sygnalu RX
       state	<= IDLE_WAIT;						-- poczatkowy stan pracy odbiornika
       cycles_in_current_bit  <= 0;							-- wyzerowanie licznika czasu bodu
       number_of_bits_received  <= 0;							-- wyzerowanie licznika odebranych bitow
       final_word_buffer	<= (others => '0');					-- wyzerowanie bufora bitow danych
       internal_error 	<= '0';							-- wyzerowanie rejestru bledu odbioru
       WORD	<= (others => '0');					-- wyzerowanie wyjsciowego slowa danych
       READY	<= '0';							-- wyzerowanie flagi potwierdzenia odbioru
       RX_ERROR	<= '0';							-- wyzerowanie flagi wykrycia bledu w odbiorze

     elsif (rising_edge(CLK)) then					-- synchroniczna praca odbiornika

       READY     <= '0';						-- defaultowe skasowanie flagi potwierdzenia odbioru
       RX_ERROR       <= '0';						-- defaultowe skasowanie flagi wykrycia bledu w odbiorze
       input_rx_buffer(0) <= RX;						-- zarejestrowanie synchroniczne stanu sygnalu RX
       input_rx_buffer(1) <= input_rx_buffer(0);					-- zarejestrowanie dwoch kolejnych stanow sygnalu RX

       case state is							-- badanie aktualnego stanu maszyny stanow

         when IDLE_WAIT =>						-- obsluga stanu IDLE_WAIT
           cycles_in_current_bit <= 0;						-- wyzerowanie licznika czasu bodu
           number_of_bits_received <= 0;						-- wyzerowanie licznika odebranych bitow
           final_word_buffer   <= (others => '0');					-- wyzerowanie bufora bitow danych
           internal_error <= '0';						-- wyzerowanie rejestru bledu odbioru
           if (input_rx_buffer(1)='1' and input_rx_buffer(0)='0' and CYCLES_PER_BIT/=0) then	-- wykrycie poczatku bitu START
             state   <= RECEIVING_START;						-- przejscie do stanu START
           end if;							-- zakonczenie instukcji warunkowej

         when RECEIVING_START =>							-- obsluga stanu RECEIVING_START
           if (cycles_in_current_bit /= CYCLES_PER_BIT/2) then				-- badanie odliczania pol okresu bodu
             cycles_in_current_bit <= cycles_in_current_bit + 1;					-- zwiekszenie o 1 stanu licznika czasu
           else								-- zakonczenie odliczania polowy okresu bodu
             cycles_in_current_bit <= 0;						-- wyzerowanie licznika czasu bodu
             state    <= RECEIVING_WORD;						-- przejscie do stanu DANA
             if (input_rx_buffer(1) = '0') then					-- badanie nieprawidlowego stanu bitu START
	           report "SERIAL_RX: nieprawidlowa wartosc bitu startu"	-- informacja o bledzie odbioru
	           severity warning;
               internal_error <= '1';						-- ustawienie rejestru bledu odbioru
             end if;							-- zakonczenie instukcji warunkowej
           end if;							-- zakonczenie instukcji warunkowej

         when RECEIVING_WORD =>							-- obsluga stanu DANA
           if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then				-- badanie odliczania okresu bodu
             cycles_in_current_bit <= cycles_in_current_bit + 1;					-- zwiekszenie o 1 stanu licznika czasu
           else								-- zakonczenie odliczania okresu bodu
             final_word_buffer(final_word_buffer'left) <= input_rx_buffer(1);				-- zapamietanie stanu bitu danych
             final_word_buffer(final_word_buffer'left-1 downto 0) <= final_word_buffer(final_word_buffer'left downto 1);-- przesuniecie bitow w buforze
             cycles_in_current_bit <= 0;						-- wyzerowanie licznika czasu bodu

             if (number_of_bits_received /= NUMBER_OF_WORD_BITS-1) then				-- badanie odliczania bitow danych
               number_of_bits_received <= number_of_bits_received + 1;					-- zwiekszenie o 1 liczby bitow danych
             else							-- zakonczenie odliczania bitow danych
               number_of_bits_received <= 0;						-- wyzerowanie licznika odebranych bitow
               if (NUMBER_OF_PARITY_BITS = 1) then				-- badanie odbioru bitu parzystosci
                 state <= RECEIVING_PARITY;					-- przejscie do stanu PARZYSTOSC
               else							-- brak odbioru bitu parzystosci
                 state <= RECEIVING_STOP;						-- przejscie do stanu STOP
               end if;							-- zakonczenie instukcji warunkowej
             end if; 							-- zakonczenie instukcji warunkowej

           end if;							-- zakonczenie instukcji warunkowej

         when RECEIVING_PARITY =>						-- obsluga stanu PARZYSTOSC
           if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then					-- badanie odliczania okresu bodu
             cycles_in_current_bit <= cycles_in_current_bit + 1;					-- zwiekszenie o 1 stanu licznika czasu
           else								-- zakonczenie odliczania okresu bodu
             cycles_in_current_bit <= 0;						-- wyzerowanie licznika czasu bodu
             state    <= RECEIVING_STOP;						-- przejscie do stanu STOP
             if (PARITY_TYPE = '0') and ((input_rx_buffer(1) xor XOR_REDUCE(final_word_buffer)) = '0') then 	-- badanie nieprawidlowej parzystosci bitow
               null;
             elsif (PARITY_TYPE = '1') and ((input_rx_buffer(1) xor not XOR_REDUCE(final_word_buffer)) = '0') then
                null;
             else
                internal_error <= '1';						-- ustawienie rejestru bledu odbioru
                report "SERIAL_RX: nieprawidlowa wartosc bitu parzystosci" -- informacja o bledzie odbioru
                severity warning;
             end if; 							-- zakonczenie instukcji warunkowej
           end if;							-- zakonczenie instukcji warunkowej

         when RECEIVING_STOP =>							-- obsluga stanu STOP
           if (cycles_in_current_bit /= CYCLES_PER_BIT-1) then					-- badanie odliczania okresu bodu
             cycles_in_current_bit <= cycles_in_current_bit + 1;					-- zwiekszenie o 1 stanu licznika czasu
           else								-- zakonczenie odliczania okresu bodu
             cycles_in_current_bit <= 0;						-- wyzerowanie licznika czasu bodu

             if (number_of_bits_received /= NUMBER_OF_STOP_BITS-1) then				-- badanie odliczania bitow stopu
               number_of_bits_received <= number_of_bits_received + 1;					-- zwiekszenie o 1 liczby bitow stopu
               if (input_rx_buffer(1) = '0') then				-- badanie nieprawidlowego stanu bitu STOP
                   internal_error <= '1';					-- ustawienie rejestru bledu odbioru
	               report "SERIAL_RX: nieprawidlowa wartosc bitu stopu"	-- informacja o bledzie odbioru
	               severity warning;   
               end if; 							-- zakonczenie instukcji warunkowej
             else							-- zakonczenie odliczania bitow stopu
                if (internal_error = '0' and input_rx_buffer(1) = '1') then		-- badanie prawidlowego odbioru szeregowego
                 WORD <= final_word_buffer;					-- ustawienie na wyjsciu WORD odebranego slowa
                 READY <= '1';						-- ustawienie na wyjsciu flagi potwierdzenia
                else							-- wykryto nieprawidlowy odbioru szeregowy
                 WORD <= (others => '0');				-- wyzerowanie wyjscia danych
                 RX_ERROR <= '1';						-- ustawienie na wyjsciu flagi bledu odbioru
                end if;							-- zakonczenie instukcji warunkowej
                state <= IDLE_WAIT;					-- przejscie do stanu IDLE_WAIT
                report "Value = " & integer'image(to_integer(unsigned(final_word_buffer)));
             end if;							-- zakonczenie instukcji warunkowej

           end if;							-- zakonczenie instukcji warunkowej

       end case;							-- zakonczenie instukcji warunkowego wyboru

     end if;								-- zakonczenie instukcji warunkowej porcesu

   end process;								-- zakonczenie ciala procesu

end RTL;
