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
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           addr : in STD_LOGIC_VECTOR (7 downto 0);
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           write_en : in STD_LOGIC;
           read_en : in STD_LOGIC;
           ready : out STD_LOGIC;
           spi_miso : in STD_LOGIC;
           spi_mosi : out STD_LOGIC;
           spi_sclk : out STD_LOGIC;
           spi_csn : out STD_LOGIC);
end Master_Interface;

architecture Behavioral of Master_Interface is

begin


end Behavioral;
