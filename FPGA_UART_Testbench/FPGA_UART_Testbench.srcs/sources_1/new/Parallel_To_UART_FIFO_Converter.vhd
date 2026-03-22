----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.03.2026 22:16:52
-- Design Name: 
-- Module Name: Parallel_To_UART_FIFO_Converter - Behavioral
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

entity Parallel_To_UART_FIFO_Converter is
    Generic (
        NUMBER_OF_WORD_BITS		:natural range 5 to 8 := 6;
        PARALLEL_BUS_WIDTH :positive range 4 to 10 := 10;
        FIFO_NUMBER_OF_WORDS :positive range 1 to 10 := 5
    );
    Port (
        PARALLEL_DATA :in std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0) := (others => '0');
        UART_FRAME :out std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0) := (others => '0');
        UART_READY :out std_logic := '0'
    );
end Parallel_To_UART_FIFO_Converter;

architecture RTL of Parallel_To_UART_FIFO_Converter is

begin
    
    process(CLK, RST)
    begin
        if RST = '1' then
            fifo_buffer <= (others => '0');
            buffer_pointer <= 0;
        elsif rising_edge(CLK) then
            if parallel_reading_complete = '1' then
                if buffer_pointer = FIFO_SINGLE_FRAME_SIZE then
                    null;
                else
                    buffer_pointer <= buffer_pointer + 1;
                    
                    fifo_buffer((buffer_pointer-1+1)*FIFO_SINGLE_FRAME_SIZE + PARALLEL_BUS_WIDTH + buffer_zero_padding_size - 1 
                        downto (buffer_pointer - 1+1)*FIFO_SINGLE_FRAME_SIZE + PARALLEL_BUS_WIDTH) <= (others => '0');
                    fifo_buffer((buffer_pointer-1+1)*FIFO_SINGLE_FRAME_SIZE + PARALLEL_BUS_WIDTH - 1 
                        downto (buffer_pointer-1+1)*FIFO_SINGLE_FRAME_SIZE ) <= parallel_received_data;
                    null;
                end if;
            end if;
            
            if tx_busy = '0' then 
                if buffer_pointer = 0 then
                    null;
                else
                    if current_uart_frame_pointer = UART_FRAMES_PER_SINGLE_FRAME then
                        fifo_buffer <= fifo_buffer(FIFO_BUFFER_SIZE - FIFO_SINGLE_FRAME_SIZE - 1 downto 0)
                            & (FIFO_SINGLE_FRAME_SIZE - 1 downto 0 => '0');
                        buffer_pointer <= buffer_pointer - 1;
                        current_uart_frame_pointer <= 0;
                        tx_word_ready <= '1';
                    else
                        tx_data <= fifo_buffer((current_uart_frame_pointer+1)*NUMBER_OF_WORD_BITS - 1
                            downto (current_uart_frame_pointer)*NUMBER_OF_WORD_BITS);
                        current_uart_frame_pointer <= current_uart_frame_pointer + 1;
                        tx_word_ready <= '1';
                    end if;
                end if;
            else
                tx_word_ready <= '0';
            end if;
        end if;
    end process;
    
end RTL;
