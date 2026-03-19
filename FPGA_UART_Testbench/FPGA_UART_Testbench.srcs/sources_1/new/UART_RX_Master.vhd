library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.std_logic_misc.all;

entity UART_RX_Master is
  generic (
    CLOCK_FREQ		:positive := 20_000_000;			-- czestotliwosc zegata w [Hz]
    MIN_NUMBER_OF_BAUDS		:positive := 110;				-- minimalna predkosc nadawania w [bodach]
    NUMBER_OF_WORD_BITS		:natural range 5 to 8 := 8;			-- liczba bitow slowa danych (5-8)
    NUMBER_OF_PARITY_BITS       :natural range 0 to 1 := 1;                     -- liczba bitow parzystosci (0-1)
    NUMBER_OF_STOP_BITS            :natural range 0 to 2 := 2;                     -- liczba bitow stopu (1-2)
    NOT_RX		:boolean := FALSE;				-- negacja logiczna sygnalu szeregowego
    NOT_WORD		:boolean := FALSE				-- negacja logiczna slowa danych
  );
  port (
    C		        :in  std_logic;					-- zegar taktujacy
    R		        :in  std_logic;					-- sygnal resetowania
    CYCLES_PER_BAUD	        :in  natural range 0 to CLOCK_FREQ/MIN_NUMBER_OF_BAUDS;	-- liczba taktow zegara dla jednego bodu
    RX		        :in  std_logic;					-- odebrany sygnal szeregowy
    WORD	        :out std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);	-- odebrane slowo danych
    READY	        :out std_logic;					-- flaga potwierdzenia odbioru
    ERROR	        :out std_logic					-- flaga wykrycia bledu w odbiorze
  );
end UART_RX_Master;

architecture RTL of UART_RX_Master is

  signal   input_rx_buffer	:std_logic_vector(0 to 1);			-- podwojny rejestr sygnalu RX

  type     ETAP		is (CZEKANIE, START, DANA, PARZYSTOSC, STOP);	-- lista etapow pracy odbiornika
  signal   stan		:ETAP;						-- rejestr maszyny stanow odbiornika

  constant T_MAX_BODU	:positive := CLOCK_FREQ/MIN_NUMBER_OF_BAUDS;		-- czas jednego bodu - liczba takt w zegara
  signal   l_czasu  	:natural range 0 to T_MAX_BODU-1;		-- licznik czasu jednego bodu
  signal   l_bitow  	:natural range 0 to NUMBER_OF_WORD_BITS-1;			-- licznik odebranych bitow danych lub stopu

  signal   bufor	:std_logic_vector(WORD'range);			-- rejestr kolejno odebranych bitow danych
  signal   problem	:std_logic;					-- rejestr (flaga) wykrytego bledu odbioru

begin

   assert (CLOCK_FREQ>=2*MIN_NUMBER_OF_BAUDS)					-- badanie poprawnosci ustawien zegarow
     report   "SERIAL_RX: nieprawidlowa wartosc parametru CLOCK_FREQ = " & integer'image(CLOCK_FREQ)
              & "i/lub parametru MIN_NUMBER_OF_BAUDS = "&integer'image(MIN_NUMBER_OF_BAUDS)
     severity error;

   process (R, C) is							-- proces odbiornika
   begin								-- cialo procesu odbiornika

     if (R='1') then							-- asynchroniczna inicjalizacja rejestrow
       input_rx_buffer	<= (others => '0');					-- wyzerowanie rejestru sygnalu RX
       stan	<= CZEKANIE;						-- poczatkowy stan pracy odbiornika
       l_czasu  <= 0;							-- wyzerowanie licznika czasu bodu
       l_bitow  <= 0;							-- wyzerowanie licznika odebranych bitow
       bufor	<= (others => '0');					-- wyzerowanie bufora bitow danych
       problem 	<= '0';							-- wyzerowanie rejestru bledu odbioru
       WORD	<= (others => '0');					-- wyzerowanie wyjsciowego slowa danych
       READY	<= '0';							-- wyzerowanie flagi potwierdzenia odbioru
       ERROR	<= '0';							-- wyzerowanie flagi wykrycia bledu w odbiorze

     elsif (rising_edge(C)) then					-- synchroniczna praca odbiornika

       READY     <= '0';						-- defaultowe skasowanie flagi potwierdzenia odbioru
       ERROR       <= '0';						-- defaultowe skasowanie flagi wykrycia bledu w odbiorze
       input_rx_buffer(0) <= RX;						-- zarejestrowanie synchroniczne stanu sygnalu RX
       if (NOT_RX = TRUE) then						-- badanie warunku zanegowania sygnalu szeregowego
         input_rx_buffer(0) <= not(RX);						-- zarejestrowanie synchroniczne zanegowanego sygnalu RX
       end if;								-- zakonczenie instukcji warunkowej
       input_rx_buffer(1) <= input_rx_buffer(0);					-- zarejestrowanie dwoch kolejnych stanow sygnalu RX

       case stan is							-- badanie aktualnego stanu maszyny stanow

         when CZEKANIE =>						-- obsluga stanu CZEKANIE
           l_czasu <= 0;						-- wyzerowanie licznika czasu bodu
           l_bitow <= 0;						-- wyzerowanie licznika odebranych bitow
           bufor   <= (others => '0');					-- wyzerowanie bufora bitow danych
           problem <= '0';						-- wyzerowanie rejestru bledu odbioru
           if (input_rx_buffer(1)='0' and input_rx_buffer(0)='1' and CYCLES_PER_BAUD/=0) then	-- wykrycie poczatku bitu START
             stan   <= START;						-- przejscie do stanu START
           end if;							-- zakonczenie instukcji warunkowej

         when START =>							-- obsluga stanu START
           if (l_czasu /= CYCLES_PER_BAUD/2) then				-- badanie odliczania pol okresu bodu
             l_czasu <= l_czasu + 1;					-- zwiekszenie o 1 stanu licznika czasu
           else								-- zakonczenie odliczania polowy okresu bodu
             l_czasu <= 0;						-- wyzerowanie licznika czasu bodu
             stan    <= DANA;						-- przejscie do stanu DANA
             if (input_rx_buffer(1) = '0') then					-- badanie nieprawidlowego stanu bitu START
	       report "SERIAL_RX: nieprawidlowa wartosc bitu startu"	-- informacja o bledzie odbioru
	         severity warning;
               problem <= '1';						-- ustawienie rejestru bledu odbioru
             end if;							-- zakonczenie instukcji warunkowej
           end if;							-- zakonczenie instukcji warunkowej

         when DANA =>							-- obsluga stanu DANA
           if (l_czasu /= CYCLES_PER_BAUD-1) then				-- badanie odliczania okresu bodu
             l_czasu <= l_czasu + 1;					-- zwiekszenie o 1 stanu licznika czasu
           else								-- zakonczenie odliczania okresu bodu
             bufor(bufor'left) <= input_rx_buffer(1);				-- zapamietanie stanu bitu danych
             bufor(bufor'left-1 downto 0) <= bufor(bufor'left downto 1);-- przesuniecie bitow w buforze
             l_czasu <= 0;						-- wyzerowanie licznika czasu bodu

             if (l_bitow /= NUMBER_OF_WORD_BITS-1) then				-- badanie odliczania bitow danych
               l_bitow <= l_bitow + 1;					-- zwiekszenie o 1 liczby bitow danych
             else							-- zakonczenie odliczania bitow danych
               l_bitow <= 0;						-- wyzerowanie licznika odebranych bitow
               if (NUMBER_OF_PARITY_BITS = 1) then				-- badanie odbioru bitu parzystosci
                 stan <= PARZYSTOSC;					-- przejscie do stanu PARZYSTOSC
               else							-- brak odbioru bitu parzystosci
                 stan <= STOP;						-- przejscie do stanu STOP
               end if;							-- zakonczenie instukcji warunkowej
             end if; 							-- zakonczenie instukcji warunkowej

           end if;							-- zakonczenie instukcji warunkowej

         when PARZYSTOSC =>						-- obsluga stanu PARZYSTOSC
           if (l_czasu /= CYCLES_PER_BAUD-1) then					-- badanie odliczania okresu bodu
             l_czasu <= l_czasu + 1;					-- zwiekszenie o 1 stanu licznika czasu
           else								-- zakonczenie odliczania okresu bodu
             l_czasu <= 0;						-- wyzerowanie licznika czasu bodu
             stan    <= STOP;						-- przejscie do stanu STOP
             if ((input_rx_buffer(1) xor XOR_REDUCE(bufor)) = '1') then 	-- badanie nieprawidlowej parzystosci bitow
               problem <= '1';						-- ustawienie rejestru bledu odbioru
	       report "SERIAL_RX: nieprawidlowa wartosc bitu parzystosci" -- informacja o bledzie odbioru
	         severity warning;
             end if; 							-- zakonczenie instukcji warunkowej
           end if;							-- zakonczenie instukcji warunkowej

         when STOP =>							-- obsluga stanu STOP
           if (l_czasu /= CYCLES_PER_BAUD-1) then					-- badanie odliczania okresu bodu
             l_czasu <= l_czasu + 1;					-- zwiekszenie o 1 stanu licznika czasu
           else								-- zakonczenie odliczania okresu bodu
             l_czasu <= 0;						-- wyzerowanie licznika czasu bodu

             if (l_bitow /= NUMBER_OF_STOP_BITS-1) then				-- badanie odliczania bitow stopu
               l_bitow <= l_bitow + 1;					-- zwiekszenie o 1 liczby bitow stopu
               if (input_rx_buffer(1) = '1') then				-- badanie nieprawidlowego stanu bitu STOP
                 problem <= '1';					-- ustawienie rejestru bledu odbioru
	       report "SERIAL_RX: nieprawidlowa wartosc bitu stopu"	-- informacja o bledzie odbioru
	         severity warning;
               end if; 							-- zakonczenie instukcji warunkowej
             else							-- zakonczenie odliczania bitow stopu
               if (problem = '0' and input_rx_buffer(1) = '0') then		-- badanie prawidlowego odbioru szeregowego
                 WORD <= bufor;					-- ustawienie na wyjsciu WORD odebranego slowa
                 if (NOT_WORD = TRUE) then				-- badanie warunku zanegowania odebranego slowa
                   WORD <= not(bufor);					-- ustawienie na wyjsciu WORD odebranego slowa
                 end if;						-- zakonczenie instukcji warunkowej
                 READY <= '1';						-- ustawienie na wyjsciu flagi potwierdzenia
               else							-- wykryto nieprawidlowy odbioru szeregowy
                 WORD <= (others => '0');				-- wyzerowanie wyjscia danych
                 ERROR <= '1';						-- ustawienie na wyjsciu flagi bledu odbioru
               end if;							-- zakonczenie instukcji warunkowej
               stan <= CZEKANIE;					-- przejscie do stanu CZEKANIE
             end if;							-- zakonczenie instukcji warunkowej

           end if;							-- zakonczenie instukcji warunkowej

       end case;							-- zakonczenie instukcji warunkowego wyboru

     end if;								-- zakonczenie instukcji warunkowej porcesu

   end process;								-- zakonczenie ciala procesu

end RTL;
