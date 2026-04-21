----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 11:25:59
-- Design Name: 
-- Module Name: testbench - Behavioral
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

entity testbench is
end testbench;

architecture Behavioral of testbench is
    -- Process parameters
    constant CLOCK_FREQ :positive := 100_000_000;
    constant BAUD_RATE :positive := 5_000_000;
    
    -- UART parameters
    constant MIN_BAUD_RATE :positive := 110;				
    constant NUMBER_OF_WORD_BITS :positive := 8;			
    constant NUMBER_OF_PARITY_BITS  :natural := 1;
    constant NUMBER_OF_STOP_BITS    :positive := 2; 
    constant PARITY_TYPE    :std_logic := '0'; -- 1 is odd 0 is even
    
    -- Parallel parameters
    constant PARALLEL_BUS_WIDTH     :positive := 8;
    constant TESTER_ZERO_PADDING_SIZE :natural := 
        (PARALLEL_BUS_WIDTH - NUMBER_OF_WORD_BITS) when (PARALLEL_BUS_WIDTH > NUMBER_OF_WORD_BITS) else 0;
    
    -- RAM
    constant RAM_ADDRESS_SIZE :positive := 3;
    
    -- Clock and reset
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    -- Parallel interface signals between Tester and Master_Interface
    signal parallel_start    : std_logic;
    signal parallel_master_data_in  : std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0);
    signal parallel_master_data_out : std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0);
    signal parallel_done     : std_logic;

    -- UART signals for Master and Slave RAM
    signal master_tx : std_logic;
    signal master_rx : std_logic;
    signal slave_tx  : std_logic;
    signal slave_rx  : std_logic;

    signal parallel_receiver_full :std_logic;
    signal parallel_receiver_stored_data :std_logic;
    signal parallel_tester_data_stored :std_logic;
begin

    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    -- Reset process
    rst_process : process
    begin
        rst <= '1';
        wait for 50 ns;
        rst <= '0';
        wait;
    end process;

    -- Instantiate Tester
    uut_tester : entity work.Tester
        generic map (
            PARALLEL_BUS_WIDTH => PARALLEL_BUS_WIDTH,
            PARALLEL_FRAMES_PER_MESSAGE => (PARALLEL_BUS_WIDTH + NUMBER_OF_WORD_BITS - 1)/NUMBER_OF_WORD_BITS,
            ZERO_PADDING_SIZE => TESTER_ZERO_PADDING_SIZE,
            RAM_ADDRESS_SIZE => RAM_ADDRESS_SIZE
        )
        port map (
            CLK      => clk,
            RST      => rst,
            
            START    => parallel_start,
            DATA_OUT => parallel_master_data_in,
            DATA_IN => parallel_master_data_out,
            DONE        => parallel_done,
            TESTER_DATA_STORED => parallel_tester_data_stored,
        
            RECEIVER_FULL => parallel_receiver_full,
            RECEIVER_DATA_STORED => parallel_receiver_stored_data
        );

    -- Instantiate Master_Interface
    uut_master : entity work.Master_Interface
        generic map(
            CLOCK_FREQ	=> CLOCK_FREQ,
            BAUD_RATE   => BAUD_RATE,
            MIN_BAUD_RATE => MIN_BAUD_RATE,				
            NUMBER_OF_WORD_BITS => NUMBER_OF_WORD_BITS,			
            NUMBER_OF_PARITY_BITS   => NUMBER_OF_PARITY_BITS,                    
            NUMBER_OF_STOP_BITS     => NUMBER_OF_STOP_BITS,                     
            PARITY_TYPE     => PARITY_TYPE,
          
            PARALLEL_BUS_WIDTH => PARALLEL_BUS_WIDTH,
            
            FIFO_NUMBER_OF_WORDS => 5
          )
        port map (
            CLK      => clk,
            RST      => rst,
            
            PARALLEL_START => parallel_start,
            PARALLEL_DATA_IN  => parallel_master_data_in,
            PARALLEL_DATA_OUT => parallel_master_data_out,
            PARALLEL_DONE   => parallel_done,
            
            UART_TX       => master_tx,
            UART_RX       => master_rx,
            
            PARALLEL_RECEIVER_FULL => parallel_receiver_full,
            PARALLEL_DATA_STORED => parallel_receiver_stored_data,
            PARALLEL_TESTER_DATA_STORED => parallel_tester_data_stored
        );

    -- Instantiate Slave RAM
    uut_slave : entity work.UART_Slave_RAM
        generic map (
            CLOCK_FREQ	=> CLOCK_FREQ,
            BAUD_RATE   => BAUD_RATE,
            MIN_BAUD_RATE => MIN_BAUD_RATE,			
            NUMBER_OF_WORD_BITS => NUMBER_OF_WORD_BITS,			
            NUMBER_OF_PARITY_BITS   => NUMBER_OF_PARITY_BITS,                     
            NUMBER_OF_STOP_BITS     => NUMBER_OF_STOP_BITS,                     
            PARITY_TYPE     => PARITY_TYPE,
            UART_FRAMES_PER_MESSAGE => ((PARALLEL_BUS_WIDTH + NUMBER_OF_WORD_BITS - 1)/NUMBER_OF_WORD_BITS),
            RESPONSE_MESSAGE_WIDTH => PARALLEL_BUS_WIDTH,
            RAM_ADDRESS_SIZE => RAM_ADDRESS_SIZE
        )
        port map (
            CLK      => clk,
            RST      => rst,
            UART_RX => slave_rx,
            UART_TX => slave_tx
        );

    master_rx <= slave_tx;
    slave_rx  <= master_tx;
    
end Behavioral;
