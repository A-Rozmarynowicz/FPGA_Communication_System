----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 12:09:46
-- Design Name: 
-- Module Name: Tester - Behavioral
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

entity Tester is
 port (
        clk      : in  std_logic;
        rst      : in  std_logic;

        -- Outputs to Master_Interface (inputs from Tester perspective)
        start    : out std_logic := '0';
        rw       : out std_logic := '0';
        data_to_send  : out std_logic_vector(7 downto 0):= (others => '0');

        -- Inputs from Master_Interface (outputs from Tester perspective)
        data_received : in  std_logic_vector(7 downto 0);
        done     : in  std_logic
    );
end Tester;

architecture Behavioral of Tester is
    type state_type is (IDLE_TYPE, WRITE_TYPE, WAIT_WRITE_TYPE,
                            READ_TYPE, WAIT_READ_TYPE, DONE_TYPE);
    signal state : state_type := IDLE_TYPE;

    -- For storing expected data
    signal expected_data : std_logic_vector(7 downto 0) := (others => '0');

begin
    process(clk, rst)
    begin
        if rst = '1' then
            start    <= '0';
            rw       <= '0';
            data_to_send  <= (others => '0');
            state    <= IDLE_TYPE;
            expected_data <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE_TYPE =>
                    data_to_send <= x"AA";
                    rw <= '0';  -- write
                    start <= '1';
                    expected_data <= x"AA";
                    state <= WRITE_TYPE;

                when WRITE_TYPE =>
                    start <= '0'; -- pulse off
                    state <= WAIT_WRITE_TYPE;

                when WAIT_WRITE_TYPE =>
                    if done = '1' then
                        rw <= '1'; -- read
                        start <= '1';
                        state <= READ_TYPE;
                    end if;

                when READ_TYPE =>
                    start <= '0';
                    state <= WAIT_READ_TYPE;

                when WAIT_READ_TYPE =>
                    if done = '1' then
                        if data_received = expected_data then
                            report "Test passed: Read data matches written data" severity note;
                        else
                            report "Test failed: Read data mismatch" severity error;
                        end if;
                        state <= DONE_TYPE;
                    end if;

                when DONE_TYPE =>
                    -- Test complete, do nothing or loop
                    null;
            end case;
        end if;
    end process;
end Behavioral;
