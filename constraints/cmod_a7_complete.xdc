## Complete XDC for CmodA7 Rev. B (All Pins Available)
## Based on Digilent CmodA7 Master XDC
## All constraints are uncommented and ready for use in RTL
## Comment out unused pins or rename signals to match your top-level design

## =============================================================================
## Clock Signal (12 MHz)
## =============================================================================
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { sysclk }];
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {sysclk}];

## =============================================================================
## On-Board LEDs
## =============================================================================
set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];

## =============================================================================
## RGB LED (3 separate channels)
## =============================================================================
set_property -dict { PACKAGE_PIN B17   IOSTANDARD LVCMOS33 } [get_ports { led0_b }];
set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33 } [get_ports { led0_g }];
set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { led0_r }];

## =============================================================================
## Push Buttons
## =============================================================================
set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }];
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }];

## =============================================================================
## Pmod Header JA (8-pin connector)
## =============================================================================
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { ja[0] }];
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports { ja[1] }];
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { ja[2] }];
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { ja[3] }];
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { ja[4] }];
set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33 } [get_ports { ja[5] }];
set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33 } [get_ports { ja[6] }];
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { ja[7] }];

## =============================================================================
## Analog XADC Pins (Differential Pairs)
## WARNING: Using these pins as analog inputs prevents their use as digital I/O
## These correspond to DIP pins 15 and 16 (pio15/pio16)
## For single-ended: connect signal to xa_p and ground to xa_n
## =============================================================================
set_property -dict { PACKAGE_PIN G2    IOSTANDARD LVCMOS33 } [get_ports { xa_n[0] }];
set_property -dict { PACKAGE_PIN G3    IOSTANDARD LVCMOS33 } [get_ports { xa_p[0] }];
set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports { xa_n[1] }];
set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33 } [get_ports { xa_p[1] }];

## =============================================================================
## GPIO Pins (DIP Header)
## Note: Pins 15-16 are shared with analog inputs (comment out if using analog)
## Note: Pins 24-25 do not exist (gap in numbering)
## =============================================================================

## GPIO Bank 35 (pio[1] through pio[23])
set_property -dict { PACKAGE_PIN M3    IOSTANDARD LVCMOS33 } [get_ports { pio[1]  }];
set_property -dict { PACKAGE_PIN L3    IOSTANDARD LVCMOS33 } [get_ports { pio[2]  }];
set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports { pio[3]  }];
set_property -dict { PACKAGE_PIN K3    IOSTANDARD LVCMOS33 } [get_ports { pio[4]  }];
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports { pio[5]  }];
set_property -dict { PACKAGE_PIN H1    IOSTANDARD LVCMOS33 } [get_ports { pio[6]  }];
set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33 } [get_ports { pio[7]  }];
set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33 } [get_ports { pio[8]  }];
set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports { pio[9]  }];
set_property -dict { PACKAGE_PIN J3    IOSTANDARD LVCMOS33 } [get_ports { pio[10] }];
set_property -dict { PACKAGE_PIN J1    IOSTANDARD LVCMOS33 } [get_ports { pio[11] }];
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { pio[12] }];
set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports { pio[13] }];
set_property -dict { PACKAGE_PIN L2    IOSTANDARD LVCMOS33 } [get_ports { pio[14] }];
## pio[15] and pio[16] are shared with analog - see XADC section above
set_property -dict { PACKAGE_PIN M1    IOSTANDARD LVCMOS33 } [get_ports { pio[17] }];
set_property -dict { PACKAGE_PIN N3    IOSTANDARD LVCMOS33 } [get_ports { pio[18] }];
set_property -dict { PACKAGE_PIN P3    IOSTANDARD LVCMOS33 } [get_ports { pio[19] }];
set_property -dict { PACKAGE_PIN M2    IOSTANDARD LVCMOS33 } [get_ports { pio[20] }];
set_property -dict { PACKAGE_PIN N1    IOSTANDARD LVCMOS33 } [get_ports { pio[21] }];
set_property -dict { PACKAGE_PIN N2    IOSTANDARD LVCMOS33 } [get_ports { pio[22] }];
set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 } [get_ports { pio[23] }];

## GPIO Bank 34 (pio[26] through pio[48])
## Note: pio[24] and pio[25] do not exist
set_property -dict { PACKAGE_PIN R3    IOSTANDARD LVCMOS33 } [get_ports { pio[26] }];
set_property -dict { PACKAGE_PIN T3    IOSTANDARD LVCMOS33 } [get_ports { pio[27] }];
set_property -dict { PACKAGE_PIN R2    IOSTANDARD LVCMOS33 } [get_ports { pio[28] }];
set_property -dict { PACKAGE_PIN T1    IOSTANDARD LVCMOS33 } [get_ports { pio[29] }];
set_property -dict { PACKAGE_PIN T2    IOSTANDARD LVCMOS33 } [get_ports { pio[30] }];
set_property -dict { PACKAGE_PIN U1    IOSTANDARD LVCMOS33 } [get_ports { pio[31] }];
set_property -dict { PACKAGE_PIN W2    IOSTANDARD LVCMOS33 } [get_ports { pio[32] }];
set_property -dict { PACKAGE_PIN V2    IOSTANDARD LVCMOS33 } [get_ports { pio[33] }];
set_property -dict { PACKAGE_PIN W3    IOSTANDARD LVCMOS33 } [get_ports { pio[34] }];
set_property -dict { PACKAGE_PIN V3    IOSTANDARD LVCMOS33 } [get_ports { pio[35] }];
set_property -dict { PACKAGE_PIN W5    IOSTANDARD LVCMOS33 } [get_ports { pio[36] }];
set_property -dict { PACKAGE_PIN V4    IOSTANDARD LVCMOS33 } [get_ports { pio[37] }];
set_property -dict { PACKAGE_PIN U4    IOSTANDARD LVCMOS33 } [get_ports { pio[38] }];
set_property -dict { PACKAGE_PIN V5    IOSTANDARD LVCMOS33 } [get_ports { pio[39] }];
set_property -dict { PACKAGE_PIN W4    IOSTANDARD LVCMOS33 } [get_ports { pio[40] }];
set_property -dict { PACKAGE_PIN U5    IOSTANDARD LVCMOS33 } [get_ports { pio[41] }];
set_property -dict { PACKAGE_PIN U2    IOSTANDARD LVCMOS33 } [get_ports { pio[42] }];
set_property -dict { PACKAGE_PIN W6    IOSTANDARD LVCMOS33 } [get_ports { pio[43] }];
set_property -dict { PACKAGE_PIN U3    IOSTANDARD LVCMOS33 } [get_ports { pio[44] }];
set_property -dict { PACKAGE_PIN U7    IOSTANDARD LVCMOS33 } [get_ports { pio[45] }];
set_property -dict { PACKAGE_PIN W7    IOSTANDARD LVCMOS33 } [get_ports { pio[46] }];
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS33 } [get_ports { pio[47] }];
set_property -dict { PACKAGE_PIN V8    IOSTANDARD LVCMOS33 } [get_ports { pio[48] }];

## =============================================================================
## UART (USB-UART Bridge)
## =============================================================================
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }];
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { uart_txd_in  }];

## =============================================================================
## Crypto 1-Wire Interface (ATSHA204A)
## =============================================================================
set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports { crypto_sda }];

## =============================================================================
## QSPI Flash (Spansion S25FL032P, 4MB)
## =============================================================================
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { qspi_cs    }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[0] }];
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[1] }];
set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[2] }];
set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[3] }];

## =============================================================================
## Cellular RAM (ISSI IS66WVE4M16EBLL, 512Kx16, 8-bit mode)
## =============================================================================

## Address Bus (19-bit)
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[0]  }];
set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[1]  }];
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[2]  }];
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[3]  }];
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[4]  }];
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[5]  }];
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[6]  }];
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[7]  }];
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[8]  }];
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[9]  }];
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[10] }];
set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[11] }];
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[12] }];
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[13] }];
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[14] }];
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[15] }];
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[16] }];
set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[17] }];
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { MemAdr[18] }];

## Data Bus (8-bit, bidirectional)
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { MemDB[0]   }];
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { MemDB[1]   }];
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { MemDB[2]   }];
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports { MemDB[3]   }];
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { MemDB[4]   }];
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { MemDB[5]   }];
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { MemDB[6]   }];
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { MemDB[7]   }];

## Control Signals (active low)
set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS33 } [get_ports { RamOEn     }];
set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports { RamWEn     }];
set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS33 } [get_ports { RamCEn     }];
