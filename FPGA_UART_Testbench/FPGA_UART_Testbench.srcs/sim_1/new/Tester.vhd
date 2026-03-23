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
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Tester is
    generic (
        PARALLEL_BUS_WIDTH :positive range 4 to 10;
        PARALLEL_FRAMES_PER_MESSAGE :positive;
        ZERO_PADDING_SIZE :natural
    );
    port (
        CLK      : in  std_logic;
        RST      : in  std_logic;

        START    : out std_logic := '0';
        DATA_OUT  : out std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0):= (others => '0');

        DATA_IN : in  std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0);
        DONE         : in  std_logic
    );
end Tester;

architecture Behavioral of Tester is
    constant CYCLES_BETWEEN_WRITING :positive := 5;
    signal cycles_left_unitl_writing :natural range 0 to CYCLES_BETWEEN_WRITING := 0;

    type WRITE_STATE_TYPE is (WRITE_IDLE_STATE, WRITE_RAM_STATE_SENDING, WRITE_STATE_WAITING);
    signal write_state : WRITE_STATE_TYPE := WRITE_IDLE_STATE;
    
    type READ_STATE_TYPE is (READ_IDLE_STATE, READ_RAM_STATE_RECEIVING);
    signal read_state : READ_STATE_TYPE := READ_IDLE_STATE;
    
    signal received_data :std_logic_vector((PARALLEL_BUS_WIDTH*PARALLEL_FRAMES_PER_MESSAGE)-1 downto 0) := (others => '0');
    signal number_of_received_parallel_messages :natural range 0 to PARALLEL_FRAMES_PER_MESSAGE := 0;
begin

    process(CLK, RST)
    begin
        if RST = '1' then
            START    <= '0';
            DATA_OUT  <= (others => '0');
            write_state    <= WRITE_IDLE_STATE;
        elsif rising_edge(CLK) then
            START <= '0';
            case write_state is
                when WRITE_IDLE_STATE =>
                    write_state <= WRITE_RAM_STATE_SENDING;
                when WRITE_RAM_STATE_SENDING =>
                    DATA_OUT <= std_logic_vector(to_unsigned(29, DATA_OUT'length));
                    START <= '1';
                    write_state <= WRITE_STATE_WAITING;
                    cycles_left_unitl_writing <= CYCLES_BETWEEN_WRITING;
                when WRITE_STATE_WAITING =>
                    cycles_left_unitl_writing <= cycles_left_unitl_writing - 1;
                    if cycles_left_unitl_writing = 1 then
                        write_state <= WRITE_IDLE_STATE;
                    end if;
            end case;
            
            case read_state is
                when READ_IDLE_STATE =>
                    if DONE = '1' then -- Input data ready
                        received_data(((number_of_received_parallel_messages+1)
                                *(PARALLEL_BUS_WIDTH-ZERO_PADDING_SIZE))-1 
                            downto (number_of_received_parallel_messages)
                                *(PARALLEL_BUS_WIDTH-ZERO_PADDING_SIZE)) 
                            <= DATA_IN(PARALLEL_BUS_WIDTH-ZERO_PADDING_SIZE-1 downto 0); -- Store input, ignoring leading zeros
                        number_of_received_parallel_messages <= number_of_received_parallel_messages + 1;
                    else
                        if number_of_received_parallel_messages = PARALLEL_FRAMES_PER_MESSAGE then -- Whole message received
                            read_state <= READ_RAM_STATE_RECEIVING;
                            number_of_received_parallel_messages <= 0;
                        end if;
                    end if;
                when READ_RAM_STATE_RECEIVING =>
                    report "OSTATECZNY TESTER = " & integer'image(to_integer(unsigned(received_data)));
                    received_data <= (others => '0');
                    read_state <= READ_IDLE_STATE;
            end case;
        end if;
    end process;
end Behavioral;
