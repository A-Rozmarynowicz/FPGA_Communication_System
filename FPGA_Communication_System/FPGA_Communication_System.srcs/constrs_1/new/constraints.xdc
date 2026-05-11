## Clock
set_property PACKAGE_PIN T8 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 83.333 [get_ports clk]

## LED
set_property PACKAGE_PIN M14 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]

## RESET BUTTON
set_property PACKAGE_PIN K17 [get_ports rst_btn]
set_property IOSTANDARD LVCMOS33 [get_ports rst_btn]

## UART TX
set_property PACKAGE_PIN D10 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

set_property PACKAGE_PIN A9 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]