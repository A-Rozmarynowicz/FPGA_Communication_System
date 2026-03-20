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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Master_Interface is
    generic (
        CLOCK_FREQ		: positive := 100_000_000;			-- czestotliwosc zegata w [Hz]
        BAUD_RATE       : positive := 1_000_000;
        MIN_BAUD_RATE		:positive := 110;				-- minimalna predkosc nadawania w [bodach]
        NUMBER_OF_WORD_BITS		:natural range 5 to 8 := 8;			-- liczba bitow slowa danych (5-8)
        NUMBER_OF_PARITY_BITS       :natural range 0 to 1 := 1;                     -- liczba bitow parzystosci (0-1)
        NUMBER_OF_STOP_BITS            :natural range 0 to 2 := 2;                     -- liczba bitow stopu (1-2)
        PARITY_TYPE         :std_logic := '0'; -- 0 to even, 1 to odd
        
        PARALLEL_BUS_WIDTH :positive range 4 to 10 := 5;
        
        FIFO_BUFFER_SIZE :positive := 5;
        FIFO_SINGLE_FRAME_SIZE :positive := 5;
        UART_FRAMES_PER_SINGLE_FRAME :positive := 5
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
    -- Signals between internal logic and UART modules
    signal rx_data   : std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    signal rx_receive_complete  : std_logic;
    signal rx_error : std_logic;

    signal tx_data   : std_logic_vector(NUMBER_OF_WORD_BITS-1 downto 0);
    signal tx_word_ready : std_logic;
    signal tx_busy : std_logic;
    signal tx_error : std_logic;
    
    signal parallel_reading_complete : std_logic;
    signal parallel_received_data : std_logic_vector (PARALLEL_BUS_WIDTH-1 downto 0);
    
    signal fifo_buffer : std_logic_vector (FIFO_BUFFER_SIZE-1 downto 0);
    signal buffer_pointer :natural range 0 to (FIFO_BUFFER_SIZE/FIFO_SINGLE_FRAME_SIZE) := 0;
    
    signal buffer_zero_padding_size :natural := FIFO_SINGLE_FRAME_SIZE - PARALLEL_BUS_WIDTH;
    
    signal current_uart_frame_pointer :natural := UART_FRAMES_PER_SINGLE_FRAME;
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
            clk      => CLK,
            rst      => RST,
            
            start   => PARALLEL_START,
            data_in  => PARALLEL_DATA_IN,
            
            data_out => PARALLEL_DATA_OUT,
            done    => PARALLEL_DONE,
            
            reading_complete => parallel_reading_complete,
            data_received => parallel_received_data
        );
        
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
                    fifo_buffer((buffer_pointer-1+1)*FIFO_SINGLE_FRAME_SIZE + buffer_zero_padding_size - 1 
                        downto (buffer_pointer - 1+1)*FIFO_SINGLE_FRAME_SIZE) <= (others => '0');
                    fifo_buffer((buffer_pointer-1+1)*FIFO_SINGLE_FRAME_SIZE + PARALLEL_BUS_WIDTH + buffer_zero_padding_size - 1 
                        downto (buffer_pointer-1+1)*FIFO_SINGLE_FRAME_SIZE + buffer_zero_padding_size) <= parallel_received_data;
                end if;
            end if;
            
            if tx_busy = '0' then 
                if buffer_pointer = 0 then
                    null;
                else
                    if current_uart_frame_pointer = 0 then
                        fifo_buffer <= fifo_buffer(FIFO_BUFFER_SIZE - FIFO_SINGLE_FRAME_SIZE - 1 downto 0)
                            & (FIFO_SINGLE_FRAME_SIZE - 1 downto 0 => '0');
                        buffer_pointer <= buffer_pointer - 1;
                        current_uart_frame_pointer <= UART_FRAMES_PER_SINGLE_FRAME;
                    else
                        tx_data <= fifo_buffer((current_uart_frame_pointer)*NUMBER_OF_WORD_BITS - 1
                            downto (current_uart_frame_pointer-1)*NUMBER_OF_WORD_BITS);
                        current_uart_frame_pointer <= current_uart_frame_pointer - 1;
                        tx_word_ready <= '1';
                    end if;
                end if;
            else
                tx_word_ready <= '0';
            end if;
        end if;
    end process;
    
end rtl;
