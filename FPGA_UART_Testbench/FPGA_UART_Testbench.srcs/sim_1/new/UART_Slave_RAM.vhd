----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 11:44:03
-- Design Name: 
-- Module Name: UART_Slave_RAM - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.std_logic_misc.all;
use     ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_Slave_RAM is
Generic (
        CLOCK_FREQ		: positive := 100_000_000;			-- czestotliwosc zegata w [Hz]
        BAUD_RATE       : positive := 20_000_000;
        MIN_BAUD_RATE		:positive := 110;				-- minimalna predkosc nadawania w [bodach]
        NUMBER_OF_WORD_BITS		:natural range 5 to 8 := 6;			-- liczba bitow slowa danych (5-8)
        NUMBER_OF_PARITY_BITS       :natural range 0 to 1 := 1;                     -- liczba bitow parzystosci (0-1)
        NUMBER_OF_STOP_BITS            :natural range 0 to 2 := 2;                     -- liczba bitow stopu (1-2)
        PARITY_TYPE         :std_logic := '0'; -- 0 to even, 1 to odd
        UART_FRAMES_PER_MESSAGE :positive
);
Port (
        CLK   : in std_logic;
        RST   : in std_logic;
        
        UART_RX : in std_logic;
        UART_TX : out std_logic := '0'
    );
end UART_Slave_RAM;

architecture Behavioral of UART_Slave_RAM is

    signal rx_data   : std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    signal rx_receive_complete  : std_logic;
    signal rx_error : std_logic;

    signal tx_data   : std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    signal tx_word_ready : std_logic;
    signal tx_busy : std_logic;
    signal tx_error : std_logic;
    
    signal final_received_data :std_logic_vector((NUMBER_OF_WORD_BITS*UART_FRAMES_PER_MESSAGE)-1 downto 0);
    signal number_of_received_uart_frames :natural range 0 to UART_FRAMES_PER_MESSAGE := 0;
begin
    uart_rt_inst: entity work.UART_TX_Master
        generic map (
          CLOCK_FREQ      => CLOCK_FREQ,
          MIN_BAUD_RATE   => MIN_BAUD_RATE,
          NUMBER_OF_WORD_BITS       => NUMBER_OF_WORD_BITS,
          NUMBER_OF_PARITY_BITS     => NUMBER_OF_PARITY_BITS,
          NUMBER_OF_STOP_BITS      => NUMBER_OF_STOP_BITS,
          PARITY_TYPE => PARITY_TYPE
        )
        
        port map (
          CLK             => CLK,
          RST            => RST,
          CYCLES_PER_BIT  => CLOCK_FREQ/BAUD_RATE,
          WORD         => tx_data,
          WORD_READY    => tx_word_ready,
          TX            => UART_TX,
          BUSY          => tx_busy,
          TX_ERROR          => tx_error
       );

    uart_rx_inst: entity work.UART_RX_Master
        generic map (
          CLOCK_FREQ      => CLOCK_FREQ,
          MIN_BAUD_RATE   => MIN_BAUD_RATE,
          NUMBER_OF_WORD_BITS       => NUMBER_OF_WORD_BITS,
          NUMBER_OF_PARITY_BITS     => NUMBER_OF_PARITY_BITS,
          NUMBER_OF_STOP_BITS      => NUMBER_OF_STOP_BITS,
          PARITY_TYPE => PARITY_TYPE
        )
        
        port map (
          CLK             => CLK,
          RST            => RST,
          CYCLES_PER_BIT  => CLOCK_FREQ/BAUD_RATE,
          RX            => UART_RX,
          WORD         => rx_data,
          READY        => rx_receive_complete,
          RX_ERROR          => rx_error
       );
    
    process(CLK, RST)
    begin
        if RST = '1' then
            null;
        elsif rising_edge(CLK) then
            if rx_receive_complete = '1' then
                final_received_data(((number_of_received_uart_frames+1)*NUMBER_OF_WORD_BITS-1) 
                    downto ((number_of_received_uart_frames)*NUMBER_OF_WORD_BITS)) <= rx_data;
                number_of_received_uart_frames <= number_of_received_uart_frames + 1;
            else
                null;
            end if;
            if number_of_received_uart_frames = UART_FRAMES_PER_MESSAGE then
                report "DUPA = " & integer'image(to_integer(unsigned(final_received_data)));
--                    final_received_data <= (others => '0');
--                    number_of_received_uart_frames = 0;
            end if;
        end if;
    end process;
end Behavioral;
