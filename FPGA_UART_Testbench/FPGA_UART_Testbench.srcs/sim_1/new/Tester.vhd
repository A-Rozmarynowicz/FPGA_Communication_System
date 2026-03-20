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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Tester is
    generic (
        PARALLEL_BUS_WIDTH :positive := 8
    );
    port (
        CLK      : in  std_logic;
        RST      : in  std_logic;

        -- Outputs to Master_Interface (inputs from Tester perspective)
        START    : out std_logic := '0';
        DATA_TO_SEND  : out std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0):= (others => '0');

        -- Inputs from Master_Interface (outputs from Tester perspective)
        DATA_RECEIVED : in  std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0);
        DONE         : in  std_logic
    );
end Tester;

architecture Behavioral of Tester is
    type state_type is (    IDLE_STATE,
                            WRITE_RAM_STATE_SENDING, WRITE_RAM_STATE_CONFIRMING, AWAITING_MASTER,
                            READ_RAM_STATE_SENDING, READ_RAM_STATE_CONFIRMING,
                            WAIT_FOR_MASTER_RAM_READY, READ_RAM_STATE_READING,
                            DONE_STATE
                        );
    signal state : state_type := IDLE_STATE;

    signal expected_data : std_logic_vector(PARALLEL_BUS_WIDTH-1 downto 0) := (others => '0');

begin
    process(CLK, RST)
    begin
        if RST = '1' then
            START    <= '0';
            DATA_TO_SEND  <= (others => '0');
            state    <= IDLE_STATE;
            expected_data <= (others => '0');
        elsif rising_edge(CLK) then
            case state is
                when IDLE_STATE =>
                    state <= WRITE_RAM_STATE_SENDING;
            
                when WRITE_RAM_STATE_SENDING =>
                    DATA_TO_SEND <= b"01011";
                    START <= '1';
                    expected_data <= b"01011";
                    state <= WRITE_RAM_STATE_CONFIRMING;
            
                when WRITE_RAM_STATE_CONFIRMING =>
                    START <= '0';
                    state <= AWAITING_MASTER;
            
                when AWAITING_MASTER =>
--                    state <= IDLE_STATE;
                    null;            
                when READ_RAM_STATE_SENDING =>
                    null;
            
                when READ_RAM_STATE_CONFIRMING =>
                    null;
            
                when WAIT_FOR_MASTER_RAM_READY =>
                    null;
            
                when READ_RAM_STATE_READING =>
                    null;
            
                when DONE_STATE =>
                    null;
            
            end case;
        end if;
    end process;
end Behavioral;
