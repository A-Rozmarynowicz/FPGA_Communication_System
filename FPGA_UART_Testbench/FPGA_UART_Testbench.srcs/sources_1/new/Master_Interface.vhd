----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2026 11:59:25
-- Design Name: 
-- Module Name: Master_Interface - Behavioral
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
use     ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Master_Interface is
    generic (
        CLOCK_FREQ		: positive := 100_000_000;		
        BAUD_RATE       : positive := 20_000_000;
        MIN_BAUD_RATE		:positive := 110;			
        NUMBER_OF_WORD_BITS		:positive range 5 to 8 := 8;			
        NUMBER_OF_PARITY_BITS       :natural range 0 to 1 := 1;         
        NUMBER_OF_STOP_BITS            :natural range 0 to 2 := 1;      
        PARITY_TYPE         :std_logic := '0'; -- 0 is even, 1 is odd
        
        PARALLEL_BUS_WIDTH :positive range 4 to 10 := 5;
        
        FIFO_NUMBER_OF_WORDS :positive range 1 to 10 := 5
      );
    Port (
        CLK   : in std_logic;
        RST   : in std_logic;

        PARALLEL_START : in std_logic;
        PARALLEL_DATA_IN  : in std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0);
        PARALLEL_DATA_OUT : out std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0) := (others => '0');
        PARALLEL_DONE  : out std_logic := '0';

        -- UART
        UART_TX : out std_logic;
        UART_RX : in  std_logic
    );
end Master_Interface;

architecture rtl of Master_Interface is
    constant FIFO_SINGLE_FRAME_SIZE :positive  := ((PARALLEL_BUS_WIDTH + NUMBER_OF_WORD_BITS - 1)/NUMBER_OF_WORD_BITS) * NUMBER_OF_WORD_BITS;
    constant FIFO_BUFFER_SIZE :positive := FIFO_SINGLE_FRAME_SIZE * FIFO_NUMBER_OF_WORDS;
    constant UART_FRAMES_PER_SINGLE_FRAME :positive := FIFO_SINGLE_FRAME_SIZE/NUMBER_OF_WORD_BITS;
    
    signal rx_data   : std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    signal rx_receive_complete  : std_logic;
    signal rx_error : std_logic;

    signal tx_data   : std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    signal tx_word_ready : std_logic;
    signal tx_busy : std_logic;
    signal tx_error : std_logic;
    
    signal parallel_reading_complete : std_logic;
    signal parallel_received_data : std_logic_vector (PARALLEL_BUS_WIDTH-1 downto 0);
    
    signal parallel_output_data : std_logic_vector (PARALLEL_BUS_WIDTH-1 downto 0);
    signal parallel_output_ready : std_logic;
    signal parallel_busy :std_logic;

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
          TX_ERROR          => tx_error
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
       
       
    -- Instantiate Parallel Interface
    parallel_interface_inst : entity work.Parallel_Interface
        generic map (
            PARALLEL_BUS_WIDTH => PARALLEL_BUS_WIDTH
        )
        port map (
            CLK      => CLK,
            RST      => RST,
            
            START   => PARALLEL_START,
            DATA_IN => PARALLEL_DATA_IN,
            
            DATA_OUT => PARALLEL_DATA_OUT,
            DONE    => PARALLEL_DONE,
            
            READING_COMPLETE => parallel_reading_complete,
            DATA_RECEIVED => parallel_received_data,
            
            INPUT_DATA_WORD => parallel_output_data,
            INPUT_DATA_READY => parallel_output_ready,
            BUSY => parallel_busy
        );
    
    buffer_size_parallel_to_uart_converter : entity work.Buffer_Size_Universal_Converter
        generic map (
            OUTPUT_WORD_SIZE => NUMBER_OF_WORD_BITS,
            INPUT_WORD_SIZE => PARALLEL_BUS_WIDTH,
            FIFO_NUMBER_OF_WORDS => FIFO_NUMBER_OF_WORDS
        )
        port map (
            CLK      => CLK,
            RST      => RST,
            
            INPUT_DATA => parallel_received_data,
            INPUT_READY => parallel_reading_complete,
            OUTPUT_DATA => tx_data,
            OUTPUT_READY => tx_word_ready,
            OUTPUT_BUSY => tx_busy
        );
        
        buffer_size_uart_to_parallel_converter : entity work.Buffer_Size_Universal_Converter
        generic map (
            OUTPUT_WORD_SIZE => PARALLEL_BUS_WIDTH,
            INPUT_WORD_SIZE => NUMBER_OF_WORD_BITS,
            FIFO_NUMBER_OF_WORDS => FIFO_NUMBER_OF_WORDS
        )
        port map (
            CLK      => CLK,
            RST      => RST,
            
            INPUT_DATA => rx_data,
            INPUT_READY => rx_receive_complete,
            OUTPUT_DATA => parallel_output_data,
            OUTPUT_READY => parallel_output_ready,
            OUTPUT_BUSY => parallel_busy
        );
    
    process (RST, CLK) is
    begin
        if (RST='1') then	
            null;
        elsif (rising_edge(CLK)) then
            if rx_error = '1' then
                report "RX Master: ERROR"
                severity error;
            end if;
            if tx_error = '1' then
                report "TX Master: ERROR"
                severity error;
            end if;
        end if;
    end process;
end rtl;
