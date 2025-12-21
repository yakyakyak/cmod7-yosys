# CMOD A7-35T Pin Diagram and Signal Reference

This document provides a complete pin reference for the Digilent CMOD A7-35T FPGA board.

## Board Overview

- **FPGA**: Xilinx Artix-7 XC7A35T-1CPG236C
- **Package**: CPG236 (15mm x 15mm BGA)
- **Form Factor**: 48-pin DIP (0.6" spacing, breadboard compatible)
- **I/O Voltage**: 3.3V (LVCMOS33)
- **Total FPGA I/O**: 44 digital + 2 analog inputs

## Board Block Diagram

```
                        CMOD A7-35T Block Diagram
                        (XDC Signal Names Shown)

     USB Micro                                           48-Pin DIP Header
         │                                                      │
         ├──[FTDI]──────────┐                          ┌───────┴────────┐
         │    FT2232HL      │                          │                │
         │                  │                          │   pio[1:48]    │
         │  uart_txd_in ────┤                          │   (44 GPIO)    │
         │  uart_rxd_out────┤                          │                │
         │                  │                          │   xa_p[0:1]    │
    ┌────┴─────┐            │                          │   xa_n[0:1]    │
    │ Power    │            │                          │   (2 analog)   │
    │ 5V→3.3V  │            │                          │                │
    └────┬─────┘            │       ┌─────────────────────────┐         │
         │                  │       │                         │         │
         │                  └───────┤ Artix-7 XC7A35T-1CPG236 ├─────────┘
         │                          │                         │
         │     sysclk (L17) ◄───────┤ FPGA (Bank 14,16,34,35) │
         │     12 MHz Clock         │                         │
         │                          │ 8,150 logic cells       │
    ┌────┴──────────────────────────┤ 1,800 Kbits Block RAM   │
    │   3.3V Power Rails             │ 90 DSP Slices           │
    │   (Board + DIP Pin 48)         └─────┬───────────────────┘
    └────────────────────────────────────┬─┘
                                         │
         ┌───────────────────────────────┼───────────────────────────────┐
         │                               │                               │
         │                               │                               │
    ┌────┴────┐  ┌────────┐  ┌──────────┴──────────┐  ┌──────────┐  ┌──┴──────┐
    │ LEDs    │  │Buttons │  │   QSPI Flash 4MB    │  │  SRAM    │  │ Crypto  │
    ├─────────┤  ├────────┤  ├─────────────────────┤  │ 512Kx16  │  │ 1-Wire  │
    │ led[0]  │  │ btn[0] │  │ qspi_cs    (K19)    │  │ 8-bit    │  │         │
    │  (A17)  │  │  (A18) │  │ qspi_dq[0] (D18)    │  │ mode     │  │crypto_  │
    │         │  │        │  │ qspi_dq[1] (D19)    │  │          │  │  sda    │
    │ led[1]  │  │ btn[1] │  │ qspi_dq[2] (G18)    │  │MemAdr    │  │  (D17)  │
    │  (C16)  │  │  (B18) │  │ qspi_dq[3] (F18)    │  │ [0:18]   │  │         │
    │         │  │        │  │                     │  │          │  │ATSHA204A│
    │RGB LED  │  └────────┘  │ S25FL032P           │  │MemDB     │  └─────────┘
    │         │              │                     │  │ [0:7]    │
    │led0_r   │              └─────────────────────┘  │          │
    │ (C17)   │                                       │RamOEn    │
    │         │              ┌─────────────────────┐  │RamWEn    │
    │led0_g   │              │  Pmod Header JA     │  │RamCEn    │
    │ (B16)   │              ├─────────────────────┤  │          │
    │         │              │ ja[0]  (G17)        │  │IS66WVE4M │
    │led0_b   │              │ ja[1]  (G19)        │  │ 16EBLL   │
    │ (B17)   │              │ ja[2]  (N18)        │  └──────────┘
    └─────────┘              │ ja[3]  (L18)        │
                             │ ja[4]  (H17)        │
      12 MHz Oscillator      │ ja[5]  (H19)        │
           (L17)             │ ja[6]  (J19)        │
                             │ ja[7]  (K18)        │
                             │                     │
                             │ 8-pin 100mil header │
                             └─────────────────────┘

Legend:
  Signal_Name (FPGA_Pin) - XDC port name and package pin location
  All I/O are 3.3V LVCMOS33
```

## 48-Pin DIP Header Pinout (With XDC Signal Names)

```
                    CMOD A7-35T DIP Header (Top View)
                    XDC Signal Names and FPGA Pins

   Left Side                                          Right Side
   ---------                                          ----------

   GND       [1]  ●                            ●  [48] 3V3
   pio[1]    [2]  ● M3                     V8 ●  [47] pio[48]
   pio[2]    [3]  ● L3                     U8 ●  [46] pio[47]
   pio[3]    [4]  ● A16                    W7 ●  [45] pio[46]
   pio[4]    [5]  ● K3                     U7 ●  [44] pio[45]
   pio[5]    [6]  ● C15                    U3 ●  [43] pio[44]
   pio[6]    [7]  ● H1                     W6 ●  [42] pio[43]
   pio[7]    [8]  ● A15                    U2 ●  [41] pio[42]
   pio[8]    [9]  ● B15                    U5 ●  [40] pio[41]
   pio[9]    [10] ● A14                    W4 ●  [39] pio[40]
   pio[10]   [11] ● J3                     V5 ●  [38] pio[39]
   pio[11]   [12] ● J1                     U4 ●  [37] pio[38]
   pio[12]   [13] ● K2                     V4 ●  [36] pio[37]
   pio[13]   [14] ● L1                     W5 ●  [35] pio[36]
   pio[14]   [15] ● L2                     V3 ●  [34] pio[35]
   xa_p[0]   [16] ● G3  (analog)           W3 ●  [33] pio[34]
   xa_n[0]        ● G2  (analog pair)      V2 ●  [32] pio[33]
   xa_p[1]   [17] ● H2  (analog)           W2 ●  [31] pio[32]
   xa_n[1]        ● J2  (analog pair)      U1 ●  [30] pio[31]
   pio[17]   [18] ● M1                     T2 ●  [29] pio[30]
   pio[18]   [19] ● N3                     T1 ●  [28] pio[29]
   pio[19]   [20] ● P3                     R2 ●  [27] pio[28]
   pio[20]   [21] ● M2                     T3 ●  [26] pio[27]
   pio[21]   [22] ● N1                     R3 ●  [25] pio[26]
   pio[22]   [23] ● N2
   pio[23]   [24] ● P1              [24-25 pins do not exist]

Notes:
  • XDC signal names shown on left
  • FPGA package pins shown after ● symbol
  • All I/O are 3.3V LVCMOS33
  • Pins 16-17 are dual-purpose: digital GPIO OR analog XADC (not both)
    - Digital mode: use pio[15], pio[16] (commented out if using analog)
    - Analog mode:  use xa_p[0:1], xa_n[0:1] (differential pairs)
  • DIP pins 24-25 do not exist (gap in physical pinout)
  • Pin 1 (GND) has square pad, pin 48 (3V3) is round
```

## Detailed DIP Pin Table with All Signal Information

| DIP | XDC Signal | FPGA Pin | Bank | Direction | Alternative |
|-----|------------|----------|------|-----------|-------------|
| 1   | GND        | -        | -    | Power     | Ground      |
| 2   | pio[1]     | M3       | 35   | I/O       | -           |
| 3   | pio[2]     | L3       | 35   | I/O       | -           |
| 4   | pio[3]     | A16      | 16   | I/O       | -           |
| 5   | pio[4]     | K3       | 35   | I/O       | -           |
| 6   | pio[5]     | C15      | 16   | I/O       | -           |
| 7   | pio[6]     | H1       | 35   | I/O       | -           |
| 8   | pio[7]     | A15      | 16   | I/O       | -           |
| 9   | pio[8]     | B15      | 16   | I/O       | -           |
| 10  | pio[9]     | A14      | 16   | I/O       | -           |
| 11  | pio[10]    | J3       | 35   | I/O       | -           |
| 12  | pio[11]    | J1       | 35   | I/O       | -           |
| 13  | pio[12]    | K2       | 35   | I/O       | -           |
| 14  | pio[13]    | L1       | 35   | I/O       | -           |
| 15  | pio[14]    | L2       | 35   | I/O       | -           |
| 16  | xa_p[0]    | G3       | 35   | Analog In | pio[15] if digital |
|     | xa_n[0]    | G2       | 35   | Analog In | (pair)      |
| 17  | xa_p[1]    | H2       | 35   | Analog In | pio[16] if digital |
|     | xa_n[1]    | J2       | 35   | Analog In | (pair)      |
| 18  | pio[17]    | M1       | 35   | I/O       | -           |
| 19  | pio[18]    | N3       | 35   | I/O       | -           |
| 20  | pio[19]    | P3       | 35   | I/O       | -           |
| 21  | pio[20]    | M2       | 35   | I/O       | -           |
| 22  | pio[21]    | N1       | 35   | I/O       | -           |
| 23  | pio[22]    | N2       | 35   | I/O       | -           |
| 24  | pio[23]    | P1       | 35   | I/O       | -           |
| 25  | pio[26]    | R3       | 34   | I/O       | -           |
| 26  | pio[27]    | T3       | 34   | I/O       | -           |
| 27  | pio[28]    | R2       | 34   | I/O       | -           |
| 28  | pio[29]    | T1       | 34   | I/O       | -           |
| 29  | pio[30]    | T2       | 34   | I/O       | -           |
| 30  | pio[31]    | U1       | 34   | I/O       | -           |
| 31  | pio[32]    | W2       | 34   | I/O       | -           |
| 32  | pio[33]    | V2       | 34   | I/O       | -           |
| 33  | pio[34]    | W3       | 34   | I/O       | -           |
| 34  | pio[35]    | V3       | 34   | I/O       | -           |
| 35  | pio[36]    | W5       | 34   | I/O       | -           |
| 36  | pio[37]    | V4       | 34   | I/O       | -           |
| 37  | pio[38]    | U4       | 34   | I/O       | -           |
| 38  | pio[39]    | V5       | 34   | I/O       | -           |
| 39  | pio[40]    | W4       | 34   | I/O       | -           |
| 40  | pio[41]    | U5       | 34   | I/O       | -           |
| 41  | pio[42]    | U2       | 34   | I/O       | -           |
| 42  | pio[43]    | W6       | 34   | I/O       | -           |
| 43  | pio[44]    | U3       | 34   | I/O       | -           |
| 44  | pio[45]    | U7       | 34   | I/O       | -           |
| 45  | pio[46]    | W7       | 34   | I/O       | -           |
| 46  | pio[47]    | U8       | 34   | I/O       | -           |
| 47  | pio[48]    | V8       | 34   | I/O       | -           |
| 48  | 3V3        | -        | -    | Power     | 3.3V Supply |
```

## Complete Pin Assignments

### Clock Signal

| Pin # | Signal | FPGA Pin | I/O Std | Description |
|-------|--------|----------|---------|-------------|
| - | sysclk | L17 | LVCMOS33 | 12 MHz on-board oscillator |

**Timing Constraint**: 83.33 ns period (12 MHz)

### LEDs (On-Board)

| Signal | FPGA Pin | I/O Std | Description | Schematic |
|--------|----------|---------|-------------|-----------|
| led[0] | A17 | LVCMOS33 | Green LED 1 | led[1] |
| led[1] | C16 | LVCMOS33 | Green LED 2 | led[2] |

### RGB LED (On-Board)

| Signal | FPGA Pin | I/O Std | Color | Schematic |
|--------|----------|---------|-------|-----------|
| led0_b | B17 | LVCMOS33 | Blue | led0_b |
| led0_g | B16 | LVCMOS33 | Green | led0_g |
| led0_r | C17 | LVCMOS33 | Red | led0_r |

### Buttons (On-Board)

| Signal | FPGA Pin | I/O Std | Description | Schematic |
|--------|----------|---------|-------------|-----------|
| btn[0] | A18 | LVCMOS33 | Push button 0 | btn[0] |
| btn[1] | B18 | LVCMOS33 | Push button 1 | btn[1] |

### Pmod Header JA (8-pin)

```
    Pmod JA Connector (Top View, looking at board)

    ┌─────────────────────────────────┐
    │  1   2   3   4   5   6   7   8  │  Pin Numbers
    │  ●   ●   ●   ●   ●   ●   ●   ●  │
    │ GND GND VCC VCC  |  GND GND VCC VCC
    │                                 │
    └─────────────────────────────────┘
       ▲   ▲   ▲   ▲      ▲   ▲   ▲   ▲
       │   │   │   │      │   │   │   │
       1   2   3   4      7   8   9  10  (Schematic numbering)
       │   │   │   │      │   │   │   │
    ja[0] [1] ja[2] [3] ja[4] [5] ja[6] [7]  (XDC array index)
    ja[1] [2] ja[3] [4] ja[5] [6] ja[7] [8]

    Signal to Pin Mapping:
    Pin 1,2,7,8  = GND (0V)
    Pin 5,6,11,12= VCC (3.3V)
    Pin 3,4,9,10 = User I/O signals (see table below)
```

| XDC Signal | FPGA Pin | I/O Std | Connector Pin | Schematic Ref |
|------------|----------|---------|---------------|---------------|
| ja[0]      | G17      | LVCMOS33| Pin 1 (JA1)   | ja[1]         |
| ja[1]      | G19      | LVCMOS33| Pin 2 (JA2)   | ja[2]         |
| ja[2]      | N18      | LVCMOS33| Pin 3 (JA3)   | ja[3]         |
| ja[3]      | L18      | LVCMOS33| Pin 4 (JA4)   | ja[4]         |
| ja[4]      | H17      | LVCMOS33| Pin 7 (JA7)   | ja[7]         |
| ja[5]      | H19      | LVCMOS33| Pin 8 (JA8)   | ja[8]         |
| ja[6]      | J19      | LVCMOS33| Pin 9 (JA9)   | ja[9]         |
| ja[7]      | K18      | LVCMOS33| Pin 10 (JA10) | ja[10]        |

**Note**: Standard Pmod specification - 4 signals per row with GND/VCC

### Analog Inputs (XADC)

**Note**: Pins 15 and 16 on the DIP header are shared between digital I/O and analog input functionality. You must choose one or the other.

| Signal | FPGA Pin | I/O Std | DIP Pin | XADC Channel | Description |
|--------|----------|---------|---------|--------------|-------------|
| xa_p[0] | G3 | LVCMOS33 | 16 | AD4P | Analog input 15 (positive) |
| xa_n[0] | G2 | LVCMOS33 | 16 | AD4N | Analog input 15 (negative) |
| xa_p[1] | H2 | LVCMOS33 | 17 | AD12P | Analog input 16 (positive) |
| xa_n[1] | J2 | LVCMOS33 | 17 | AD12N | Analog input 16 (negative) |

**For single-ended conversion**: Connect signal to xa_p and ground to xa_n

### GPIO Pins (DIP Header)

**Important Notes**:
- Pins 15 and 16 are shared with analog inputs (see above)
- Pins 24 and 25 do not exist (gap in numbering)
- All GPIO use LVCMOS33 I/O standard

#### Bank 35 GPIO

| DIP Pin | Signal | FPGA Pin | I/O Std | FPGA I/O Type |
|---------|--------|----------|---------|---------------|
| 2 | pio[1] | M3 | LVCMOS33 | IO_L8N_T1_AD14N_35 |
| 3 | pio[2] | L3 | LVCMOS33 | IO_L8P_T1_AD14P_35 |
| 4 | pio[3] | A16 | LVCMOS33 | IO_L12P_T1_MRCC_16 |
| 5 | pio[4] | K3 | LVCMOS33 | IO_L7N_T1_AD6N_35 |
| 6 | pio[5] | C15 | LVCMOS33 | IO_L11P_T1_SRCC_16 |
| 7 | pio[6] | H1 | LVCMOS33 | IO_L3P_T0_DQS_AD5P_35 |
| 8 | pio[7] | A15 | LVCMOS33 | IO_L6N_T0_VREF_16 |
| 9 | pio[8] | B15 | LVCMOS33 | IO_L11N_T1_SRCC_16 |
| 10 | pio[9] | A14 | LVCMOS33 | IO_L6P_T0_16 |
| 11 | pio[10] | J3 | LVCMOS33 | IO_L7P_T1_AD6P_35 |
| 12 | pio[11] | J1 | LVCMOS33 | IO_L3N_T0_DQS_AD5N_35 |
| 13 | pio[12] | K2 | LVCMOS33 | IO_L5P_T0_AD13P_35 |
| 14 | pio[13] | L1 | LVCMOS33 | IO_L6N_T0_VREF_35 |
| 15 | pio[14] | L2 | LVCMOS33 | IO_L5N_T0_AD13N_35 |
| 16 | pio[15] | G2/G3 | LVCMOS33 | See Analog Inputs |
| 17 | pio[16] | J2/H2 | LVCMOS33 | See Analog Inputs |
| 18 | pio[17] | M1 | LVCMOS33 | IO_L9N_T1_DQS_AD7N_35 |
| 19 | pio[18] | N3 | LVCMOS33 | IO_L12P_T1_MRCC_35 |
| 20 | pio[19] | P3 | LVCMOS33 | IO_L12N_T1_MRCC_35 |
| 21 | pio[20] | M2 | LVCMOS33 | IO_L9P_T1_DQS_AD7P_35 |
| 22 | pio[21] | N1 | LVCMOS33 | IO_L10N_T1_AD15N_35 |
| 23 | pio[22] | N2 | LVCMOS33 | IO_L10P_T1_AD15P_35 |
| 24 | pio[23] | P1 | LVCMOS33 | IO_L19N_T3_VREF_35 |

#### Bank 34 GPIO

| DIP Pin | Signal | FPGA Pin | I/O Std | FPGA I/O Type |
|---------|--------|----------|---------|---------------|
| 25 | pio[26] | R3 | LVCMOS33 | IO_L2P_T0_34 |
| 26 | pio[27] | T3 | LVCMOS33 | IO_L2N_T0_34 |
| 27 | pio[28] | R2 | LVCMOS33 | IO_L1P_T0_34 |
| 28 | pio[29] | T1 | LVCMOS33 | IO_L3P_T0_DQS_34 |
| 29 | pio[30] | T2 | LVCMOS33 | IO_L1N_T0_34 |
| 30 | pio[31] | U1 | LVCMOS33 | IO_L3N_T0_DQS_34 |
| 31 | pio[32] | W2 | LVCMOS33 | IO_L5N_T0_34 |
| 32 | pio[33] | V2 | LVCMOS33 | IO_L5P_T0_34 |
| 33 | pio[34] | W3 | LVCMOS33 | IO_L6N_T0_VREF_34 |
| 34 | pio[35] | V3 | LVCMOS33 | IO_L6P_T0_34 |
| 35 | pio[36] | W5 | LVCMOS33 | IO_L12P_T1_MRCC_34 |
| 36 | pio[37] | V4 | LVCMOS33 | IO_L11N_T1_SRCC_34 |
| 37 | pio[38] | U4 | LVCMOS33 | IO_L11P_T1_SRCC_34 |
| 38 | pio[39] | V5 | LVCMOS33 | IO_L16N_T2_34 |
| 39 | pio[40] | W4 | LVCMOS33 | IO_L12N_T1_MRCC_34 |
| 40 | pio[41] | U5 | LVCMOS33 | IO_L16P_T2_34 |
| 41 | pio[42] | U2 | LVCMOS33 | IO_L9N_T1_DQS_34 |
| 42 | pio[43] | W6 | LVCMOS33 | IO_L13N_T2_MRCC_34 |
| 43 | pio[44] | U3 | LVCMOS33 | IO_L9P_T1_DQS_34 |
| 44 | pio[45] | U7 | LVCMOS33 | IO_L19P_T3_34 |
| 45 | pio[46] | W7 | LVCMOS33 | IO_L13P_T2_MRCC_34 |
| 46 | pio[47] | U8 | LVCMOS33 | IO_L14P_T2_SRCC_34 |
| 47 | pio[48] | V8 | LVCMOS33 | IO_L14N_T2_SRCC_34 |

### UART (USB Interface)

| Signal | FPGA Pin | I/O Std | Description | Schematic |
|--------|----------|---------|-------------|-----------|
| uart_rxd_out | J18 | LVCMOS33 | UART receive | uart_rxd_out |
| uart_txd_in | J17 | LVCMOS33 | UART transmit | uart_txd_in |

**Note**: Connected to on-board FTDI USB-UART bridge

### Crypto 1-Wire Interface

| Signal | FPGA Pin | I/O Std | Description |
|--------|----------|---------|-------------|
| crypto_sda | D17 | LVCMOS33 | Atmel ATSHA204A crypto chip |

### QSPI Flash (On-Board)

| Signal | FPGA Pin | I/O Std | Description | Schematic |
|--------|----------|---------|-------------|-----------|
| qspi_cs | K19 | LVCMOS33 | Chip select | qspi_cs |
| qspi_dq[0] | D18 | LVCMOS33 | Data 0 (MOSI) | qspi_dq[0] |
| qspi_dq[1] | D19 | LVCMOS33 | Data 1 (MISO) | qspi_dq[1] |
| qspi_dq[2] | G18 | LVCMOS33 | Data 2 (WP#) | qspi_dq[2] |
| qspi_dq[3] | F18 | LVCMOS33 | Data 3 (HOLD#) | qspi_dq[3] |

**Device**: Spansion S25FL032P (4 MB)

### Cellular RAM (On-Board SRAM)

**Device**: ISSI IS66WVE4M16EBLL-55BLI (512K x 16-bit)

#### Address Bus (19-bit)

| Signal | FPGA Pin | I/O Std | Description |
|--------|----------|---------|-------------|
| MemAdr[0] | M18 | LVCMOS33 | Address bit 0 |
| MemAdr[1] | M19 | LVCMOS33 | Address bit 1 |
| MemAdr[2] | K17 | LVCMOS33 | Address bit 2 |
| MemAdr[3] | N17 | LVCMOS33 | Address bit 3 |
| MemAdr[4] | P17 | LVCMOS33 | Address bit 4 |
| MemAdr[5] | P18 | LVCMOS33 | Address bit 5 |
| MemAdr[6] | R18 | LVCMOS33 | Address bit 6 |
| MemAdr[7] | W19 | LVCMOS33 | Address bit 7 |
| MemAdr[8] | U19 | LVCMOS33 | Address bit 8 |
| MemAdr[9] | V19 | LVCMOS33 | Address bit 9 |
| MemAdr[10] | W18 | LVCMOS33 | Address bit 10 |
| MemAdr[11] | T17 | LVCMOS33 | Address bit 11 |
| MemAdr[12] | T18 | LVCMOS33 | Address bit 12 |
| MemAdr[13] | U17 | LVCMOS33 | Address bit 13 |
| MemAdr[14] | U18 | LVCMOS33 | Address bit 14 |
| MemAdr[15] | V16 | LVCMOS33 | Address bit 15 |
| MemAdr[16] | W16 | LVCMOS33 | Address bit 16 |
| MemAdr[17] | W17 | LVCMOS33 | Address bit 17 |
| MemAdr[18] | V15 | LVCMOS33 | Address bit 18 |

#### Data Bus (8-bit, Bidirectional)

| Signal | FPGA Pin | I/O Std | Description |
|--------|----------|---------|-------------|
| MemDB[0] | W15 | LVCMOS33 | Data bit 0 |
| MemDB[1] | W13 | LVCMOS33 | Data bit 1 |
| MemDB[2] | W14 | LVCMOS33 | Data bit 2 |
| MemDB[3] | U15 | LVCMOS33 | Data bit 3 |
| MemDB[4] | U16 | LVCMOS33 | Data bit 4 |
| MemDB[5] | V13 | LVCMOS33 | Data bit 5 |
| MemDB[6] | V14 | LVCMOS33 | Data bit 6 |
| MemDB[7] | U14 | LVCMOS33 | Data bit 7 |

#### Control Signals

| Signal | FPGA Pin | I/O Std | Description |
|--------|----------|---------|-------------|
| RamOEn | P19 | LVCMOS33 | Output enable (active low) |
| RamWEn | R19 | LVCMOS33 | Write enable (active low) |
| RamCEn | N19 | LVCMOS33 | Chip enable (active low) |

**Note**: Only 8 data bits are connected (MemDB[0:7]). Upper byte (MemDB[8:15]) not available.

## I/O Bank Summary

| Bank | Voltage | Pin Count | Usage |
|------|---------|-----------|-------|
| 14 | 3.3V | - | Clock, Pmod JA, UART, QSPI, SRAM |
| 16 | 3.3V | - | LEDs, Buttons, some GPIO |
| 34 | 3.3V | 24 | GPIO (pio[26] through pio[48]) |
| 35 | 3.3V | 23 | GPIO (pio[1] through pio[23]), Analog |

## Power Pins

| DIP Pin | Signal | Description |
|---------|--------|-------------|
| 1 | GND | Ground |
| 48 | 3V3 | 3.3V power supply |

**Additional Power**: Available via USB connector (5V and 3.3V)

## Quick Reference: On-Board Peripherals

All peripherals with XDC signal names and FPGA pins for easy reference:

```
PERIPHERAL          XDC SIGNAL         FPGA PIN    NOTES
══════════════════════════════════════════════════════════════════════
Clock (12 MHz)      sysclk             L17         Create timing constraint

LEDs (Green)        led[0]             A17         Active high
                    led[1]             C16         Active high

RGB LED             led0_r             C17         Red channel
                    led0_g             B16         Green channel
                    led0_b             B17         Blue channel

Push Buttons        btn[0]             A18         Active high when pressed
                    btn[1]             B18         Active high when pressed

Pmod Connector      ja[0:7]            See table   8 GPIO signals
                                       above       100-mil header

USB-UART            uart_txd_in        J17         TX to FPGA (input)
                    uart_rxd_out       J18         RX from FPGA (output)

QSPI Flash (4MB)    qspi_cs            K19         Active low chip select
                    qspi_dq[0:3]       D18,D19,    Quad SPI data
                                       G18,F18

SRAM (512Kx16)      MemAdr[0:18]       19 pins     Address bus
8-bit mode          MemDB[0:7]         8 pins      Data bus (bidirectional)
                    RamOEn             P19         Output enable (active low)
                    RamWEn             R19         Write enable (active low)
                    RamCEn             N19         Chip enable (active low)

Crypto Chip         crypto_sda         D17         1-wire interface
(ATSHA204A)                                        Open-drain

DIP Header GPIO     pio[1:48]          44 pins     See DIP pinout table
                    (gaps at 15-16,                16,17 shared with analog
                     24-25)

Analog Inputs       xa_p[0:1]          G3,H2       Positive inputs
(XADC)              xa_n[0:1]          G2,J2       Negative inputs
                                                   DIP pins 16-17 (shared)
══════════════════════════════════════════════════════════════════════
```

## Usage Notes

1. **All I/O are 3.3V (LVCMOS33)** - Do not connect 5V signals directly
2. **Analog/Digital Pin Conflict**: Pins 15-16 cannot be used as both analog and digital simultaneously
3. **Missing Pin Numbers**: pio[24] and pio[25] do not exist
4. **SRAM Data Width**: Only 8 data bits available (not full 16-bit width)
5. **USB-UART**: Automatically available when USB is connected, no driver needed on most OSes
6. **On-board Components**: LEDs, buttons, QSPI flash, SRAM, and crypto chip share FPGA pins with DIP header
7. **Breadboard Compatible**: 0.6" DIP spacing fits standard breadboards

## References

- [Cmod A7 Reference Manual](https://digilent.com/reference/programmable-logic/cmod-a7/reference-manual)
- [Cmod A7 Schematic](https://digilent.com/reference/_media/reference/programmable-logic/cmod-a7/cmod_a7_sch.pdf)
- [Master XDC File](https://github.com/Digilent/digilent-xdc/blob/master/Cmod-A7-Master.xdc)
- [Artix-7 FPGAs Data Sheet](https://www.xilinx.com/support/documentation/data_sheets/ds181_Artix_7_Data_Sheet.pdf)

## Revision History

- **Rev B**: Current board revision documented here
- All pin assignments verified against Digilent master XDC file
