----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 14:52:37
-- Design Name: 
-- Module Name: Parallel_Interface - Behavioral
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

entity Parallel_Interface is
    Port (
        clk   : in std_logic;
        rst   : in std_logic;

        start : in std_logic;
        rw   : in std_logic;
        data_in  : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0) := (others => '0');
        done  : out std_logic := '0';
        
        reading_complete : out std_logic := '0'
    );
end Parallel_Interface;

architecture rt1 of Parallel_Interface is
    type state_type is (IDLE_STATE, WRITE_STATE);
    signal state : state_type := IDLE_STATE;
    
    signal last_registered_start : std_logic := '0';
begin
    process(clk, rst)
    begin
        if rst = '1' then
            data_out <= (others => '0');
            state    <= IDLE_STATE;
            done <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE_STATE =>
                    if (start = '0') and (last_registered_start = '1')
                                                    and (rw = '0') then -- reading
                       reading_complete <= '1';
                    end if;        
                when WRITE_STATE =>
                    null;
            end case;
        end if;
        
        last_registered_start <= start;
     end process;
end rt1;
