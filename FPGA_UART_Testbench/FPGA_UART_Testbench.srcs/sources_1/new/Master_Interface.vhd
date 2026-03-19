----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2026 11:59:25
-- Design Name: 
-- Module Name: Master_Interface - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Master_Interface is
    generic (
        CLOCK_FREQ		: positive := 20_000_000;			-- czestotliwosc zegata w [Hz]
        BAUD_RATE       : positive := 9600;
        MIN_BAUD_RATE		:positive := 110;				-- minimalna predkosc nadawania w [bodach]
        NUMBER_OF_WORD_BITS		:natural range 5 to 8 := 8;			-- liczba bitow slowa danych (5-8)
        NUMBER_OF_PARITY_BITS       :natural range 0 to 1 := 1;                     -- liczba bitow parzystosci (0-1)
        NUMBER_OF_STOP_BITS            :natural range 0 to 2 := 2                     -- liczba bitow stopu (1-2)
      );
    Port (
        CLK   : in std_logic;
        RST   : in std_logic;

        PARALLEL_START : in std_logic;
        PARALLEL_DATA_IN  : in std_logic_vector(7 downto 0);
        PARALLEL_DATA_OUT : out std_logic_vector(7 downto 0) := (others => '0');
        PARALLEL_DONE  : out std_logic := '0';

        -- UART
        UART_TX : out std_logic;
        UART_RX : in  std_logic
    );
end Master_Interface;

architecture rtl of Master_Interface is
    -- Signals between internal logic and UART modules
    signal rx_data   : std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    signal rx_receive_complete  : std_logic;
    signal rx_error : std_logic;

    signal tx_data   : std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    signal tx_transmit_complete : std_logic;
    signal tx_error : std_logic;
    
    signal parallel_reading_complete : std_logic;
    
begin

    -- Instantiate UART Transmitter
    uart_tx_inst : entity work.UART_TX_Master
        port map (
            clk   => CLK,
            rst   => RST,

            tx    => UART_TX,
            data_to_send => tx_data, -- Tutaj może w drugą strone strzałka
            transmit_complete => tx_transmit_complete
        );

    uart_rx_inst: entity work.UART_RX_Master
        generic map (
          CLOCK_FREQ      => CLOCK_FREQ,
          MIN_BAUD_RATE   => MIN_BAUD_RATE,
          NUMBER_OF_WORD_BITS       => NUMBER_OF_WORD_BITS,
          NUMBER_OF_PARITY_BITS     => NUMBER_OF_PARITY_BITS,
          NUMBER_OF_STOP_BITS      => NUMBER_OF_STOP_BITS
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
       
       
    -- Instantiate Parallel Interface
    parallel_interface_inst : entity work.Parallel_Interface
        port map (
            clk      => CLK,
            rst      => RST,
            
            start   => PARALLEL_START,
            data_in  => parallel_data_in,
            
            data_out => parallel_data_out,
            done    => parallel_done,
            
            reading_complete => parallel_reading_complete
        );
     
end rtl;
