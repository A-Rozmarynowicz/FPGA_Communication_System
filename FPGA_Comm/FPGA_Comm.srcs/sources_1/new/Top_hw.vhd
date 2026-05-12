----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.05.2026 19:53:59
-- Design Name: 
-- Module Name: Top_hw - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Top_hw is
    Port (
        clk      : in  std_logic;

        uart_rx  : in  std_logic;
        uart_tx  : out std_logic;

        led      : out std_logic
    );
end Top_hw;

architecture Behavioral of Top_hw is

    constant CLOCK_FREQ :positive := 12_000_000;
    constant BAUD_RATE :positive := 1_000_000;
    
    -- UART parameters
    constant MIN_BAUD_RATE :positive := 110;				
    constant NUMBER_OF_WORD_BITS :positive := 8;			
    constant NUMBER_OF_PARITY_BITS  :natural := 1;
    constant NUMBER_OF_STOP_BITS    :positive := 2; 
    constant PARITY_TYPE    :std_logic := '0'; -- 1 is odd 0 is even
    
    -- Parallel parameters
    constant PARALLEL_BUS_WIDTH     :positive := 8;
    constant TESTER_ZERO_PADDING_SIZE :natural := 0;
--                (PARALLEL_BUS_WIDTH - NUMBER_OF_WORD_BITS) when (PARALLEL_BUS_WIDTH > NUMBER_OF_WORD_BITS) else 0;

    signal rst : std_logic;
    signal parallel_start : std_logic;
    signal parallel_data_in : std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0);
    signal parallel_data_out : std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0) := (others => '0');
    signal parallel_done : std_logic := '0';
    signal parallel_receiver_full : std_logic := '0';
    signal parallel_data_stored : std_logic := '0';
    signal parallel_tester_data_stored : std_logic;
    
    signal send_prev : std_logic := '0';
    
    signal cnt : unsigned(25 downto 0) := (others => '0');
    signal heartbeat : std_logic := '0';

    signal heartbeat_dbg      : std_logic;
    signal uart_tx_dbg        : std_logic;
    
    attribute MARK_DEBUG : string;
    attribute DONT_TOUCH : string;
        
    attribute MARK_DEBUG of heartbeat_dbg : signal is "TRUE";
    attribute DONT_TOUCH of heartbeat_dbg : signal is "TRUE";
    
    attribute MARK_DEBUG of uart_tx_dbg : signal is "TRUE";
    attribute DONT_TOUCH of uart_tx_dbg : signal is "TRUE";

    signal vio_rst       : std_logic;
    signal vio_parallel_start      : std_logic;
    signal vio_parallel_data_in   : std_logic_vector(7 downto 0);
    signal vio_parallel_data_out   : std_logic_vector(7 downto 0);
    signal vio_parallel_done : std_logic;
    signal vio_parallel_receiver_full : std_logic;
    signal vio_parallel_data_stored : std_logic;
    signal vio_parallel_tester_data_stored : std_logic;

--    signal vio_uart_tx : std_logic;
--    signal vio_uart_rx : std_logic;

    signal vio_heartbeat : std_logic;
begin

    Master_Interface : entity work.Master_Interface
    generic map(
            CLOCK_FREQ	=> CLOCK_FREQ,
            BAUD_RATE   => BAUD_RATE,
            MIN_BAUD_RATE => MIN_BAUD_RATE,				
            NUMBER_OF_WORD_BITS => NUMBER_OF_WORD_BITS,			
            NUMBER_OF_PARITY_BITS   => NUMBER_OF_PARITY_BITS,                    
            NUMBER_OF_STOP_BITS     => NUMBER_OF_STOP_BITS,                     
            PARITY_TYPE     => PARITY_TYPE,
          
            PARALLEL_BUS_WIDTH => PARALLEL_BUS_WIDTH,
            
            FIFO_NUMBER_OF_WORDS => 5
          )
    port map (
        CLK      => clk,
        RST      => rst,

        PARALLEL_START => parallel_start,
        PARALLEL_DATA_IN  => parallel_data_in,
        PARALLEL_DATA_OUT => parallel_data_out,
        PARALLEL_DONE  => parallel_done,
        PARALLEL_RECEIVER_FULL => parallel_receiver_full,
        PARALLEL_DATA_STORED => parallel_data_stored,
        PARALLEL_TESTER_DATA_STORED => parallel_tester_data_stored,
        
        UART_RX  => uart_rx,
        UART_TX  => uart_tx
    );

    vio_0_inst : entity work.vio_0
        port map (
            clk => clk,
            
            probe_out0(0) => vio_rst,
            probe_out1(0) => vio_parallel_start,
            probe_out2 => vio_parallel_data_in,
            probe_out3(0) => vio_parallel_tester_data_stored,
--            probe_out4(0) => vio_uart_tx,
        
            probe_in0 => vio_parallel_data_out,
            probe_in1(0) => vio_parallel_done,
            probe_in2(0) => vio_parallel_receiver_full,
            probe_in3(0) => vio_parallel_data_stored,
            probe_in4(0) => vio_heartbeat
--            probe_in4(0) => vio_uart_rx,
            
        );

    process(clk)
    begin
        if rising_edge(clk) then
    
            if cnt = 50_000_000 then
                cnt <= (others => '0');
                heartbeat <= not heartbeat;
            else
                cnt <= cnt + 1;
            end if;
    
            parallel_start <= '0';

            if (vio_parallel_start = '1' and send_prev = '0') then
                parallel_start <= '1';
            end if;
    
            send_prev <= vio_parallel_start;
    
        end if;
    end process;
    
    led <= heartbeat;
    
    heartbeat_dbg <= heartbeat;
    uart_tx_dbg <= uart_tx;
    
    rst <= vio_rst;
--    parallel_start <= vio_parallel_start;
    parallel_data_in <= vio_parallel_data_in;
    parallel_tester_data_stored <= vio_parallel_tester_data_stored;
--    uart_rx <= vio_uart_tx;

    vio_parallel_data_out <= parallel_data_out;
    vio_parallel_done <= parallel_done;
    vio_parallel_receiver_full <= parallel_receiver_full;
    vio_parallel_data_stored <= parallel_data_stored;
--    vio_uart_rx <= uart_tx;
    vio_heartbeat <= heartbeat;

end Behavioral;
