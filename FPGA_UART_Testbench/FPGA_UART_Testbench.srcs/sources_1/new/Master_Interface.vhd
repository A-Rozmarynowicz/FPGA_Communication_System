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
    Port (
        clk   : in std_logic;
        rst   : in std_logic;

        start : in std_logic;
        rw   : in std_logic;
        addr  : in std_logic_vector(7 downto 0);
        data_in  : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0) := (others => '0');
        done  : out std_logic := '0';

        -- UART
        tx : out std_logic := '0';
        rx : in  std_logic
    );
end Master_Interface;

architecture rtl of Master_Interface is
    -- Signals between internal logic and UART modules
    signal tx_busy   : std_logic;
    signal rx_data   : std_logic_vector(7 downto 0);
    signal rx_ready  : std_logic;

    -- Optional: control signals for TX
    signal tx_start  : std_logic;
    signal tx_data   : std_logic_vector(7 downto 0);

begin

    -- Instantiate UART Transmitter
    uart_tx_inst : entity work.UART_TX_Master
        port map (
            clk   => clk,
            rst   => rst,
            
            start => tx_start,
            data_to_send => tx_data,
            tx    => tx,
            busy  => tx_busy
        );

    -- Instantiate UART Receiver
    uart_rx_inst : entity work.UART_RX_Master
        port map (
            clk      => clk,
            rst      => rst,
            
            rx       => rx,
            data_received => rx_data,
            ready    => rx_ready
        );
end rtl;
