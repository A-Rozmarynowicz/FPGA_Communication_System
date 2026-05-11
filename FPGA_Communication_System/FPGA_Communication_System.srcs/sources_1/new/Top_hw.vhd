----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.05.2026 19:53:59
-- Design Name: 
-- Module Name: Top_hw - Behavioral
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

entity Top_hw is(
    Port (
        clk      : in  std_logic;
        rst_btn  : in  std_logic;

        parallel_start : in std_logic;
        parallel_data_in  : in std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0);
        parallel_data_out: out std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0) := (others => '0');
        parallel_done : out std_logic := '0';
        parallel_receiver_full :out std_logic := '0';
        parallel_data_stored :out std_logic := '0';
        parallel_tester_data_stored :in std_logic;

        uart_rx  : in  std_logic;
        uart_tx  : out std_logic;

        led      : out std_logic
    );
end Top_hw;

architecture Behavioral of Top_hw is

    signal rst : std_logic;

begin

    rst <= rst_btn;

    Master_Interface : entity work.Master_Interface
    port map (
        CLK      => clk,
        RST      => rst,

        PARALLEL_START => parallel_start,
        PARALLEL_DATA_IN  => parallel_data_in,
        PARALLEL_DATA_OUT => parallel_data_out,
        PARALLEL_DONE  => parallel_done,
        PARALLEL_RECEIVER_FULL => parallel_receiver_full,
        PARALLEL_DATA_STORED => parallel_data_stored,
        PARALLEL_TESTER_DATA_STORED => parallel_tester_data_stored,
        
        UART_RX  => uart_rx,
        UART_TX  => uart_tx
    );


end Behavioral;
