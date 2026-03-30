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
use IEEE.MATH_REAL.ALL;

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
        ZERO_PADDING_SIZE :natural;
        RAM_ADDRESS_SIZE :positive := 3
    );
    port (
        CLK      : in  std_logic;
        RST      : in  std_logic;

        START    : out std_logic := '0';
        DATA_OUT  : out std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0):= (others => '0');
        TESTER_DATA_STORED :out std_logic := '0';

        DATA_IN : in  std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0);
        DONE         : in  std_logic;
        RECEIVER_DATA_STORED :in std_logic;
        
        RECEIVER_FULL :in std_logic
    );
end Tester;

architecture Behavioral of Tester is
    constant CYCLES_BETWEEN_WRITING :positive := 70;
    signal cycles_left_unitl_writing :natural range 0 to CYCLES_BETWEEN_WRITING := 0;

    type WRITE_STATE_TYPE is (WRITE_IDLE_STATE, WRITE_RAM_STATE_SENDING, WRITE_STATE_WAITING, WRITE_STATE_SWITCHING);
    signal write_state : WRITE_STATE_TYPE := WRITE_IDLE_STATE;
    
    type READ_STATE_TYPE is (READ_IDLE_STATE, READ_RAM_STATE_RECEIVING);
    signal read_state : READ_STATE_TYPE := READ_IDLE_STATE;

    signal has_just_read_data :std_logic := '0';
    
    signal received_data :std_logic_vector((PARALLEL_BUS_WIDTH*PARALLEL_FRAMES_PER_MESSAGE)-1 downto 0) := (others => '0');
    signal number_of_received_parallel_messages :natural range 0 to PARALLEL_FRAMES_PER_MESSAGE := 0;
    
    constant RAM_word_size :positive := PARALLEL_BUS_WIDTH - RAM_ADDRESS_SIZE - 1;
    type ram_type is array (0 to 255) of std_logic_vector(RAM_word_size-1 downto 0);
    signal mem : ram_type := (others => (others => '0'));
    
begin

    process(CLK, RST)
        variable ram_max_address :positive := (2 ** RAM_ADDRESS_SIZE) - 1;
        variable ram_current_write_address :natural := 0;
        variable ram_current_read_address :natural := 0;
        variable ram_read_value :natural := 0;
        variable actual_ram_value :natural := 0;
        variable seed1, seed2 : positive := 1;
        variable rand         : real;
        variable int_rand     : integer;
        variable RAM_MAX_VALUE :positive := (2 ** RAM_word_size)-1; -- = 15
        variable read_or_write :std_logic := '1'; -- 1 is write
        variable buffer_data_out  : std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0):= (others => '0');
    begin
        if RST = '1' then
            START    <= '0';
            DATA_OUT  <= (others => '0');
            TESTER_DATA_STORED <= '0';
            write_state    <= WRITE_IDLE_STATE;
            has_just_read_data <= '0';
            read_or_write := '1';
            ram_current_write_address := 0;
            ram_current_read_address := 0;
            ram_read_value := 0;
            buffer_data_out := (others => '0');
        elsif rising_edge(CLK) then
            START <= '0';
            DATA_OUT <= (others => '0');
            TESTER_DATA_STORED <= '0';
            has_just_read_data <= '0';
            case write_state is
                when WRITE_IDLE_STATE =>
                    if RECEIVER_FULL = '0' then
                        write_state <= WRITE_RAM_STATE_SENDING;
                    end if;
                when WRITE_RAM_STATE_SENDING =>
                    buffer_data_out(0) := '0';
                    if read_or_write = '1' then
                        buffer_data_out(0) := '1';
                        uniform(seed1, seed2, rand); -- 1 and 2 are seeds
                        int_rand := integer(rand * real(RAM_MAX_VALUE));
                        buffer_data_out(PARALLEL_BUS_WIDTH-1 downto RAM_ADDRESS_SIZE+1) := std_logic_vector(to_unsigned(int_rand, RAM_word_size));
                        mem(ram_current_write_address)
                            <= std_logic_vector(to_unsigned(int_rand, RAM_WORD_SIZE));
                    end if;
                    
                    buffer_data_out(RAM_ADDRESS_SIZE downto 1) 
                        := std_logic_vector(to_unsigned(ram_current_write_address, RAM_ADDRESS_SIZE));
                    START <= '1';
                    write_state <= WRITE_STATE_WAITING;
                    DATA_OUT <= buffer_data_out;
                    
                    if read_or_write = '1' then
                        report "TESTER: Sending: 0x" &
                           to_hstring(to_unsigned(int_rand, RAM_word_size)) &
                           " to adr: 0x" &
                           to_hstring(to_unsigned(ram_current_write_address, RAM_ADDRESS_SIZE)) &
                           "; we: 0x" & std_logic'image(read_or_write) &
                           " -> frame: 0x" & to_hstring(buffer_data_out) &
                           " @ time: " & time'image(now);
                    else
                        report "TESTER: Reading: " &
                           to_hstring(to_unsigned(int_rand, RAM_word_size)) &
                           " from adr: " &
                           to_hstring(to_unsigned(ram_current_write_address, RAM_ADDRESS_SIZE)) &
                           " -> frame: 0x" & to_hstring(buffer_data_out) &
                           " @ time: " & time'image(now);
                    end if;
                    
                when WRITE_STATE_WAITING =>
                    START <= '1';
                    if RECEIVER_DATA_STORED = '1' then
                        if ram_current_write_address = ram_max_address then
                            ram_current_write_address := 0;
                            read_or_write := not read_or_write;
                        else
                            ram_current_write_address := ram_current_write_address + 1;
                        end if;
                        START <= '0';
                        write_state <= WRITE_STATE_SWITCHING;
                        cycles_left_unitl_writing <= CYCLES_BETWEEN_WRITING;
                    end if;
                when WRITE_STATE_SWITCHING =>
                    cycles_left_unitl_writing <= cycles_left_unitl_writing - 1;
                    if cycles_left_unitl_writing = 1 then
                        write_state <= WRITE_IDLE_STATE;
                    end if;
            end case;
            
            case read_state is
                when READ_IDLE_STATE =>
                    if DONE = '1' and has_just_read_data = '0' then -- Input data ready
                        received_data(((number_of_received_parallel_messages+1)
                                *(PARALLEL_BUS_WIDTH-ZERO_PADDING_SIZE))-1 
                            downto (number_of_received_parallel_messages)
                                *(PARALLEL_BUS_WIDTH-ZERO_PADDING_SIZE)) 
                            <= DATA_IN(PARALLEL_BUS_WIDTH-ZERO_PADDING_SIZE-1 downto 0); -- Store input, ignoring leading zeros
                        number_of_received_parallel_messages <= number_of_received_parallel_messages + 1;
                        TESTER_DATA_STORED <= '1';
                        has_just_read_data <= '1';
                    else
                        if number_of_received_parallel_messages = PARALLEL_FRAMES_PER_MESSAGE then -- Whole message received
                            read_state <= READ_RAM_STATE_RECEIVING;
                            number_of_received_parallel_messages <= 0;
                        end if;
                    end if;
                    
                when READ_RAM_STATE_RECEIVING =>
                    ram_current_read_address := to_integer(unsigned(received_data(RAM_ADDRESS_SIZE downto 1)));
                    ram_read_value := to_integer(unsigned(received_data(PARALLEL_BUS_WIDTH-1 downto RAM_ADDRESS_SIZE+1)));
                    actual_ram_value := to_integer(unsigned(mem(ram_current_read_address)));
                    assert ram_read_value = actual_ram_value
                        report "TESTER: >-----ASSERTING-----<: reference is: " &
                               to_hstring(to_unsigned(actual_ram_value, RAM_word_size)) &
                               " @ adr: " &
                               to_hstring(to_unsigned(ram_current_read_address, RAM_ADDRESS_SIZE)) &
                               " -> got: 0x" & to_hstring(to_unsigned(ram_read_value, RAM_word_size)) &
                               " - ERROR! Stop simulation" &
                               " @ time: " & time'image(now)
                        severity failure;
                        
                    report "TESTER: >-----ASSERTING-----<: reference is: " &
                           to_hstring(to_unsigned(actual_ram_value, RAM_word_size)) &
                           " @ adr: " &
                           to_hstring(to_unsigned(ram_current_read_address, RAM_ADDRESS_SIZE)) &
                           " -> got: 0x" & to_hstring(to_unsigned(ram_read_value, RAM_word_size)) &
                           " - OK" &
                           " @ time: " & time'image(now);
                    
                    
--                    report "TESTER: READ FROM RAM ADDRESS: " & integer'image(ram_current_read_address);
--                    report "TESTER: RECEIVED RAM VALUE= " & integer'image(ram_read_value);
--                    report "TESTER: ACTUAL RAM VALUE= " & integer'image(actual_ram_value);
                    received_data <= (others => '0');
                    read_state <= READ_IDLE_STATE;
            end case;
        end if;
    end process;
end Behavioral;
