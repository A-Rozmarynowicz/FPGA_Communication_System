----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.03.2026 23:22:31
-- Design Name: 
-- Module Name: Buffer_Size_Universal_Converter - Behavioral
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
use     ieee.std_logic_unsigned.all;
use     ieee.std_logic_misc.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Buffer_Size_Universal_Converter is
    Generic (
        OUTPUT_WORD_SIZE		:positive;
        INPUT_WORD_SIZE         :positive;
        FIFO_NUMBER_OF_WORDS :positive range 1 to 128
    );
    Port (
        CLK :in std_logic;
        RST :in std_logic;
        
        INPUT_DATA :in std_logic_vector(INPUT_WORD_SIZE-1 downto 0) := (others => '0');
        INPUT_READY :in std_logic := '0';
        
        OUTPUT_DATA :out std_logic_vector(OUTPUT_WORD_SIZE-1 downto 0) := (others => '0');
        OUTPUT_READY :out std_logic := '0';
        OUTPUT_BUSY :in std_logic
    );
end Buffer_Size_Universal_Converter;

architecture RTL of Buffer_Size_Universal_Converter is
    constant FIFO_SINGLE_FRAME_SIZE :positive  := ((INPUT_WORD_SIZE + OUTPUT_WORD_SIZE - 1)/OUTPUT_WORD_SIZE) * OUTPUT_WORD_SIZE;
    constant FIFO_BUFFER_SIZE :positive := FIFO_SINGLE_FRAME_SIZE * FIFO_NUMBER_OF_WORDS;
    constant OUTPUT_FRAMES_PER_INPUT_FRAME :positive := FIFO_SINGLE_FRAME_SIZE/OUTPUT_WORD_SIZE;
    
    signal fifo_buffer : std_logic_vector (FIFO_BUFFER_SIZE-1 downto 0);
    signal buffer_pointer :natural range 0 to (FIFO_BUFFER_SIZE/FIFO_SINGLE_FRAME_SIZE) := 0;
    
    constant buffer_zero_padding_size :natural := FIFO_SINGLE_FRAME_SIZE - INPUT_WORD_SIZE;
    
    signal current_output_frame_pointer :natural := 0;
begin

    process(CLK, RST)
    begin
        if RST = '1' then
            fifo_buffer <= (others => '0');
            buffer_pointer <= 0;
            current_output_frame_pointer <= 0;
        elsif rising_edge(CLK) then
            if INPUT_READY = '1' then
                if buffer_pointer = FIFO_SINGLE_FRAME_SIZE then
                    null;
                else
                    buffer_pointer <= buffer_pointer + 1;
                    
                    fifo_buffer((buffer_pointer-1+1)*FIFO_SINGLE_FRAME_SIZE + INPUT_WORD_SIZE + buffer_zero_padding_size - 1 
                        downto (buffer_pointer - 1+1)*FIFO_SINGLE_FRAME_SIZE + INPUT_WORD_SIZE) <= (others => '0');
                    fifo_buffer((buffer_pointer-1+1)*FIFO_SINGLE_FRAME_SIZE + INPUT_WORD_SIZE - 1 
                        downto (buffer_pointer-1+1)*FIFO_SINGLE_FRAME_SIZE ) <= INPUT_DATA;
                    null;
                end if;
            end if;
            
            if OUTPUT_BUSY = '0' then 
                if buffer_pointer = 0 then
                    null;
                else
                    if current_output_frame_pointer = OUTPUT_FRAMES_PER_INPUT_FRAME then
                        fifo_buffer <= fifo_buffer(FIFO_BUFFER_SIZE - FIFO_SINGLE_FRAME_SIZE - 1 downto 0)
                            & (FIFO_SINGLE_FRAME_SIZE - 1 downto 0 => '0');
                        buffer_pointer <= buffer_pointer - 1;
                        current_output_frame_pointer <= 0;
                        OUTPUT_READY <= '1';
                    else
                        OUTPUT_DATA <= fifo_buffer((current_output_frame_pointer+1)*OUTPUT_WORD_SIZE - 1
                            downto (current_output_frame_pointer)*OUTPUT_WORD_SIZE);
                        current_output_frame_pointer <= current_output_frame_pointer + 1;
                        OUTPUT_READY <= '1';
                    end if;
                end if;
            else
                OUTPUT_READY <= '0';
            end if;
        end if;
    end process;

end RTL;
