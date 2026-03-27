----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 11:44:03
-- Design Name: 
-- Module Name: UART_Slave_RAM - Behavioral
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
use     ieee.std_logic_1164.all;
use     ieee.std_logic_unsigned.all;
use     ieee.std_logic_misc.all;
use     ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_Slave_RAM is
Generic (
        CLOCK_FREQ		: positive;			
        BAUD_RATE       : positive;
        MIN_BAUD_RATE		:positive;				
        NUMBER_OF_WORD_BITS		:positive range 5 to 8;
        NUMBER_OF_PARITY_BITS       :natural range 0 to 1;                     
        NUMBER_OF_STOP_BITS            :natural range 0 to 2;                  
        PARITY_TYPE         :std_logic; -- 0 is even, 1 is odd
        UART_FRAMES_PER_MESSAGE :positive;
        RESPONSE_MESSAGE_WIDTH :positive := 8;
        RAM_ADDRESS_SIZE :positive := 3
);
Port (
        CLK   : in std_logic;
        RST   : in std_logic;
        
        UART_RX : in std_logic;
        UART_TX : out std_logic := '0'
    );
end UART_Slave_RAM;

architecture Behavioral of UART_Slave_RAM is
    constant FIFO_NUMBER_OF_WORDS :positive := 1;
    
    signal rx_data   : std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    signal rx_receive_complete  : std_logic;
    signal rx_error : std_logic;

    signal tx_data   : std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    signal tx_word_ready : std_logic;
    signal tx_busy : std_logic;
    signal tx_error : std_logic;
    
    signal final_received_data :std_logic_vector((NUMBER_OF_WORD_BITS*UART_FRAMES_PER_MESSAGE)-1 downto 0);
    signal number_of_received_uart_frames :natural range 0 to UART_FRAMES_PER_MESSAGE := 0;
    signal interpret_received_data :std_logic := '0';
    
    signal response_message :std_logic_vector(RESPONSE_MESSAGE_WIDTH-1 downto 0);
    signal response_ready :std_logic := '0';
    
    signal buffer_converter_full :std_logic := '0';
    
    constant RAM_word_size :positive := RESPONSE_MESSAGE_WIDTH - RAM_ADDRESS_SIZE - 1;
    
    type ram_type is array (0 to 255) of std_logic_vector(RAM_word_size-1 downto 0);
    signal mem : ram_type := (others => (others => '0'));
begin
    uart_rt_inst: entity work.UART_TX_Master
        generic map (
          CLOCK_FREQ      => CLOCK_FREQ,
          MIN_BAUD_RATE   => MIN_BAUD_RATE,
          NUMBER_OF_WORD_BITS       => NUMBER_OF_WORD_BITS,
          NUMBER_OF_PARITY_BITS     => NUMBER_OF_PARITY_BITS,
          NUMBER_OF_STOP_BITS      => NUMBER_OF_STOP_BITS,
          PARITY_TYPE => PARITY_TYPE
        )
        
        port map (
          CLK             => CLK,
          RST            => RST,
          CYCLES_PER_BIT  => CLOCK_FREQ/BAUD_RATE,
          WORD         => tx_data,
          WORD_READY    => tx_word_ready,
          TX            => UART_TX,
          BUSY          => tx_busy,
          TX_ERROR      => tx_error
       );

    uart_rx_inst: entity work.UART_RX_Master
        generic map (
          CLOCK_FREQ      => CLOCK_FREQ,
          MIN_BAUD_RATE   => MIN_BAUD_RATE,
          NUMBER_OF_WORD_BITS       => NUMBER_OF_WORD_BITS,
          NUMBER_OF_PARITY_BITS     => NUMBER_OF_PARITY_BITS,
          NUMBER_OF_STOP_BITS      => NUMBER_OF_STOP_BITS,
          PARITY_TYPE => PARITY_TYPE
        )
        
        port map (
          CLK             => CLK,
          RST            => RST,
          CYCLES_PER_BIT  => CLOCK_FREQ/BAUD_RATE,
          RX            => UART_RX,
          WORD         => rx_data,
          READY        => rx_receive_complete,
          RX_ERROR          => rx_error
       );
       
       buffer_size_universal_converter : entity work.Buffer_Size_Universal_Converter
        generic map (
            OUTPUT_WORD_SIZE => NUMBER_OF_WORD_BITS,
            INPUT_WORD_SIZE => RESPONSE_MESSAGE_WIDTH,
            FIFO_NUMBER_OF_WORDS => FIFO_NUMBER_OF_WORDS
        )
        port map (
            CLK      => CLK,
            RST      => RST,
            
            INPUT_DATA => response_message,
            INPUT_READY => response_ready,
            OUTPUT_DATA => tx_data,
            OUTPUT_READY => tx_word_ready,
            OUTPUT_BUSY => tx_busy,
            
            BUFFER_FULL => buffer_converter_full
        );
    
    process(CLK, RST)
        variable RAM_address :std_logic_vector(2 downto 0) := (others => '0');
    begin
        if RST = '1' then
            interpret_received_data <= '0';
            -- TODO
        elsif rising_edge(CLK) then
            if rx_receive_complete = '1' then
                final_received_data(((number_of_received_uart_frames+1)*NUMBER_OF_WORD_BITS-1) 
                    downto ((number_of_received_uart_frames)*NUMBER_OF_WORD_BITS)) <= rx_data;
                number_of_received_uart_frames <= number_of_received_uart_frames + 1;
            else
                if number_of_received_uart_frames = UART_FRAMES_PER_MESSAGE then
                    report "RAM Slave: received message: " & integer'image(to_integer(unsigned(final_received_data)));
                    number_of_received_uart_frames <= 0;
                    interpret_received_data <= '1';
                end if;
            end if;
            
            if interpret_received_data = '1' then
                RAM_address := final_received_data(3 downto 1);
                if final_received_data(0) = '1' then --WRITING
                    mem(to_integer(unsigned(final_received_data(RAM_ADDRESS_SIZE downto 1))))
                        <= final_received_data(RESPONSE_MESSAGE_WIDTH-1 downto RAM_ADDRESS_SIZE+1);
                    report "WRITING TO RAM: ADDRESS: " & integer'image(to_integer(unsigned(RAM_address)));
                    report "WRITING TO RAM: VALUE: " & integer'image(to_integer(unsigned(final_received_data(RESPONSE_MESSAGE_WIDTH-1 downto RAM_ADDRESS_SIZE+1))));
                else -- READING
                    response_ready <= '1';
                    response_message(RESPONSE_MESSAGE_WIDTH-1) = '0';
                    response_message(RAM_ADDRESS_SIZE-1 downto 0) <= RAM_address;
                    response_message(RESPONSE_MESSAGE_WIDTH-2 downto RAM_ADDRESS_SIZE) <= mem(to_integer(unsigned(RAM_address)));
                    report "READING RAM: ADDRESS: " & integer'image(to_integer(unsigned(final_received_data(RAM_ADDRESS_SIZE downto 1))));
                    report "READING RAM: VALUE: " & integer'image(to_integer(unsigned(response_message)));
                end if;
                
                interpret_received_data <= '0';
            --    final_received_data <= (others => '0');
            else
                response_ready <= '0';
            end if;
            
           
        end if;
    end process;
end Behavioral;
