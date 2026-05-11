## Clock
set_property PACKAGE_PIN T8 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 83.333 [get_ports clk]

## LED
set_property PACKAGE_PIN M14 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]