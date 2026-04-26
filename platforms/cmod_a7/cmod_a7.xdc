## CMOD A7-35T Constraints for LED Blinky with PWM (NextPNR-Xilinx format)
## Adapted from Digilent CMOD A7 Master XDC

## Clock signal (12 MHz)
set_property PACKAGE_PIN L17 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 83.333 -name sys_clk_pin -waveform {0.000 41.667} [get_ports clk]

## LEDs
set_property PACKAGE_PIN A17 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN C16 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

## GPIO - PWM Output
## DIP pin 2, Bank 35
set_property PACKAGE_PIN M3 [get_ports pio1]
set_property IOSTANDARD LVCMOS33 [get_ports pio1]

## UART - via FTDI FT2232HL Channel B
## J17 = FPGA RX input (Digilent calls this uart_txd_in)
## J18 = FPGA TX output (Digilent calls this uart_rxd_out)
set_property PACKAGE_PIN J17 [get_ports uart_rxd_in]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rxd_in]

set_property PACKAGE_PIN J18 [get_ports uart_txd_out]
set_property IOSTANDARD LVCMOS33 [get_ports uart_txd_out]
