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
        CLK   : in std_logic;
        RST   : in std_logic;

        START : in std_logic;
        DATA_IN  : in std_logic_vector(7 downto 0);
        DATA_OUT : out std_logic_vector(7 downto 0) := (others => '0');
        DONE  : out std_logic := '0';
        
        READING_COMPLETE : out std_logic := '0';
        DATA_RECEIVED : out std_logic_vector(7 downto 0)
    );
end Parallel_Interface;

architecture rt1 of Parallel_Interface is
    type state_type is (IDLE_STATE, WRITE_STATE, READ_STATE);
    signal state : state_type := IDLE_STATE;
    
    signal last_registered_start : std_logic := '0';
    
begin
    process(clk, rst)
    begin
        if RST = '1' then
            DATA_OUT <= (others => '0');
            state    <= IDLE_STATE;
            DONE <= '0';
            last_registered_start <= '0';
            
        elsif rising_edge(CLK) then
            last_registered_start <= START;
            case state is
                when IDLE_STATE =>
                    if (start = '0') and (last_registered_start = '1') then
                        DATA_RECEIVED <= DATA_IN;
                        READING_COMPLETE <= '1';
                        state <= READ_STATE;
                    end if;
                    
                when WRITE_STATE =>
                    null;
                    
                when READ_STATE =>
                    READING_COMPLETE <= '0'; 
            end case;
        end if;
     end process;
end rt1;
