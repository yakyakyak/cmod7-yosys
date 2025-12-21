## CMOD A7-35T Constraints for LED Blinky (NextPNR-Xilinx format)
## Adapted from Digilent CMOD A7 Master XDC

## Clock signal (12 MHz)
set_property PACKAGE_PIN L17 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

## LEDs
set_property PACKAGE_PIN A17 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN C16 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
