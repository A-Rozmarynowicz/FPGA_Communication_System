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
--  Port ( );
end testbench;

architecture Behavioral of testbench is

    -- Clock and reset
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    -- Parallel interface signals between Tester and Master_Interface
    signal start    : std_logic;
    signal rw       : std_logic;
    signal addr     : std_logic_vector(7 downto 0);
    signal master_data_in  : std_logic_vector(7 downto 0);
    signal master_data_out : std_logic_vector(7 downto 0);
    signal done     : std_logic;

    -- UART signals connecting Master and Slave RAM
    signal master_tx : std_logic;
    signal master_rx : std_logic;
    signal slave_tx  : std_logic;
    signal slave_rx  : std_logic;

begin

    -- Clock generation: 100MHz clock (10 ns period)
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

    -- Instantiate Tester (generates commands on parallel interface)
    uut_tester : entity work.Tester -- uut means Unit Under Test
        port map (
            clk      => clk,
            rst      => rst,
            start    => start,
            rw       => rw,
            addr     => addr,
            data_to_send  => master_data_in,
            data_received => master_data_out,
            done     => done
        );

    -- Instantiate Master_Interface (UART Master)
    uut_master : entity work.Master_Interface
        port map (
            clk      => clk,
            rst      => rst,
            start    => start,
            rw       => rw,
            addr     => addr,
            data_in  => master_data_in,
            data_out => master_data_out,
            done     => done,
            tx       => master_tx,
            rx       => master_rx
        );

    -- Instantiate Slave RAM (UART_Slave_RAM)
    uut_slave : entity work.UART_Slave_RAM
        port map (
            rx => slave_rx,
            tx => slave_tx
        );

    -- Cross UART signals between Master and Slave
    master_rx <= slave_tx;
    slave_rx  <= master_tx;

end Behavioral;
