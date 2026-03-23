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
        RESPONSE_MESSAGE_WIDTH :positive := 8
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
            OUTPUT_BUSY => tx_busy
        );
    
    process(CLK, RST)
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
                    report "DUPA = " & integer'image(to_integer(unsigned(final_received_data)));
                    number_of_received_uart_frames <= 0;
                    interpret_received_data <= '1';
                end if;
            end if;
            
            if interpret_received_data = '1' then
                response_message <= std_logic_vector(to_unsigned(28, response_message'length));
                response_ready <= '1';
                interpret_received_data <= '0';
                final_received_data <= (others => '0');
            else
                response_ready <= '0';
            end if;
            
           
        end if;
    end process;
end Behavioral;
