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
    generic (
        PARALLEL_BUS_WIDTH  :positive range 4 to 10
    );
    
    Port (
        CLK   : in std_logic;
        RST   : in std_logic;

        START : in std_logic;
        DATA_IN  : in std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0);
        DATA_OUT : out std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0) := (others => '0');
        DONE  : out std_logic := '0';
        
        READING_COMPLETE : out std_logic := '0';
        DATA_RECEIVED : out std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0);
        
        INPUT_DATA_WORD :in std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0);
        INPUT_DATA_READY :in std_logic;
        BUSY :out std_logic
    );
end Parallel_Interface;

architecture rt1 of Parallel_Interface is
    type READ_STATE_TYPE is (IDLE_READ_STATE, READ_PARALLEL_STATE);
    signal read_state : READ_STATE_TYPE := IDLE_READ_STATE;

    type WRITE_STATE_TYPE is (IDLE_WRITE_STATE, WRITE_PARALLEL_STATE);
    signal write_state : WRITE_STATE_TYPE := IDLE_WRITE_STATE;
begin
    process(clk, rst)
    begin
        if RST = '1' then
            read_state    <= IDLE_READ_STATE;
            write_state <= IDLE_WRITE_STATE;
            BUSY <= '0';
            DATA_OUT <= (others => '0');
            DONE <= '0';
            READING_COMPLETE <= '0';
            DATA_RECEIVED <= (others => '0');
        elsif rising_edge(CLK) then
            BUSY <= '0';
            DATA_OUT <= (others => '0');
            DONE <= '0';
            READING_COMPLETE <= '0';
            DATA_RECEIVED <= (others => '0');
            case read_state is
                when IDLE_READ_STATE =>
                    if (start = '1') then
                        DATA_RECEIVED <= DATA_IN;
                        READING_COMPLETE <= '1';
                        read_state <= READ_PARALLEL_STATE;
                    end if;
                when READ_PARALLEL_STATE =>
                    READING_COMPLETE <= '0'; 
                    read_state <= IDLE_READ_STATE;
            end case;
        
            case write_state is
                when IDLE_WRITE_STATE =>
                    if INPUT_DATA_READY = '1' then
                        DATA_OUT <= INPUT_DATA_WORD;
                        DONE <= '1';
                        BUSY <= '1';
                        write_state <= WRITE_PARALLEL_STATE;
                    end if;
                when WRITE_PARALLEL_STATE =>
                    DONE <= '0';
                    write_state <= IDLE_WRITE_STATE;
            end case;
        end if;
     end process;
end rt1;
