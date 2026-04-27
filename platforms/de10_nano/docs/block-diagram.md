# DE10-Nano Platform — Block Diagram

## Overview

The DE10-Nano is a Terasic development board built around the Intel Cyclone V SoC
FPGA (5CSEBA6U23I7). It combines 110K logic elements with a Hard Processor System
(HPS) containing a dual-core ARM Cortex-A9 at up to 925 MHz. The HPS and FPGA
fabric communicate through a high-bandwidth interconnect, enabling tightly coupled
embedded Linux + programmable logic designs. The board provides 1 GB DDR3 (HPS),
HDMI output, Gigabit Ethernet, and USB OTG.

---

## Board-Level Block Diagram

```
  ┌────────────────────────────────────────────────────────────────────────────┐
  │  DE10-Nano Board                                                           │
  │                                                                            │
  │  ┌────────────┐  FPGA_CLK1_50      ┌──────────────────────────────────┐   │
  │  │ 50 MHz OSC ├───────────────────►│                                  │   │
  │  └────────────┘                    │    Cyclone V SoC  5CSEBA6U23I7   │   │
  │                                    │                                  │   │
  │  ┌────────────┐  SW[3:0]           │  ┌────────────────────────────┐  │   │
  │  │  Switches  ├───────────────────►│  │  FPGA Fabric               │  ├───┼──► LED[7:0]
  │  └────────────┘                    │  │  110K Logic Elements        │  │   │    (8 user LEDs)
  │                                    │  │  5,570 ALMs                 │  │   │
  │  ┌────────────┐  KEY[1:0]          │  │  4 PLLs                    │  ├───┼──► HDMI TX
  │  │  Buttons   ├───────────────────►│  │  2 Transceiver blocks       │  │   │
  │  │ (active-lo)│                    │  │                            │  ├───┼──► Arduino / GPIO
  │  └────────────┘                    │  └──────────┬─────────────────┘  │   │
  │                                    │             │ HPS-FPGA Bridge     │   │
  │                                    │  ┌──────────┴─────────────────┐  │   │
  │                                    │  │  HPS (Hard Processor System)│  │   │
  │  ┌────────────┐  DDR3 (32-bit)     │  │  Dual-core ARM Cortex-A9   │  │   │
  │  │  1 GB DDR3 ├◄──────────────────►│  │  Up to 925 MHz             │  │   │
  │  │  SDRAM     │                    │  │  32 KB L1 / 512 KB L2      │  │   │
  │  └────────────┘                    │  │                            │  ├───┼──► Ethernet (RJ45)
  │                                    │  │                            │  ├───┼──► USB OTG
  │  ┌────────────┐  QSPI              │  │                            │  ├───┼──► USB UART
  │  │  QSPI Flash├◄──────────────────►│  │                            │  │   │
  │  │  (HPS boot)│                    │  │                            │  ├───┼──► microSD
  │  └────────────┘                    │  └────────────────────────────┘  │   │
  │                                    └──────────────────────────────────┘   │
  │                                                    ▲                      │
  │                                                    │ JTAG                 │
  │  ┌──────────────────────────────┐                  │                      │
  │  │  USB-Blaster II (on-board)   ├──────────────────┘                      │
  │  └──────────────┬───────────────┘                                         │
  │                 │ USB Micro-B                                              │
  └─────────────────┼────────────────────────────────────────────────────────-┘
                    │
             USB to Host PC
```

---

## Blinky Top-Level Module (FPGA-only)

For a pure FPGA blinky design (no HPS), a 26-bit counter driven by the 50 MHz
clock maps bits to LED outputs at different toggle rates.

```
                          blinky.v (top)
                  ┌─────────────────────────────┐
  FPGA_CLK1_50 ──►│                             │
   50 MHz         │  counter[25:0]              ├──► LED[0]  ~3 Hz   (bit 24)
                  │  +1 every clock             ├──► LED[1]  ~1.5 Hz (bit 25)
                  │                             ├──► LED[2]  ~6 Hz   (bit 23)
                  │  @ 50 MHz:                  ├──► LED[3]  off
                  │    bit 23 → ~6 Hz           ├──► LED[4]  off
                  │    bit 24 → ~3 Hz           ├──► LED[5]  off
                  │    bit 25 → ~1.5 Hz         ├──► LED[6]  off
                  └─────────────────────────────┴──► LED[7]  off
```

---

## HPS + FPGA SoC Architecture

The Cyclone V SoC exposes three bridge interfaces between the HPS and FPGA fabric.
A typical embedded Linux design uses the Lightweight HPS-to-FPGA bridge for
register-mapped peripherals.

```
  ┌───────────────────────────────────────────────────────────────────────┐
  │  Cyclone V SoC                                                        │
  │                                                                       │
  │  ┌──────────────────────────┐    ┌──────────────────────────────────┐ │
  │  │  HPS                     │    │  FPGA Fabric                     │ │
  │  │                          │    │                                  │ │
  │  │  ARM Cortex-A9 × 2  ─────┼────┼─► HPS-to-FPGA bridge            │ │
  │  │  (Linux / bare-metal)    │    │    (AXI, up to 3 GB/s)          │ │
  │  │                          │◄───┼─── FPGA-to-HPS bridge            │ │
  │  │  L2 Cache (512 KB)       │    │    (AXI, up to 3 GB/s)          │ │
  │  │                          │    │                                  │ │
  │  │  DMA controller          │◄───┼─── Lightweight HPS-to-FPGA       │ │
  │  │  Ethernet MAC            │    │    (APB, register maps)          │ │
  │  │  USB OTG                 │    │                                  │ │
  │  │  UART / SPI / I2C        │    │  Custom RTL (user logic)         │ │
  │  │  SD/MMC controller       │    │  LEDs, GPIO, DSP, video, etc.   │ │
  │  │                          │    │                                  │ │
  │  └──────────────────────────┘    └──────────────────────────────────┘ │
  │             │                                    │                    │
  │             ▼                                    ▼                    │
  │       1 GB DDR3                          FPGA_CLK1_50                 │
  │       (HPS memory)                       GPIO / HDMI / Arduino        │
  └───────────────────────────────────────────────────────────────────────┘
```

---

## Build Toolchain Flow

```
  Host macOS (Apple Silicon)
  ┌────────────────────────────────────────────────────────────────────────┐
  │                                                                        │
  │  quartus-docker.sh build de10_blinky                                   │
  │         │                                                              │
  │         ▼                                                              │
  │  ┌────────────────────────────────────────────────────────────────┐    │
  │  │  Colima VM  (x86_64, Rosetta 2)                                │    │
  │  │                                                                │    │
  │  │  ┌──────────────────────────────────────────────────────────┐  │    │
  │  │  │  Docker: Quartus Prime Lite container                    │  │    │
  │  │  │                                                          │  │    │
  │  │  │  1. quartus_map  ──► synthesis   (Cyclone V target)      │  │    │
  │  │  │  2. quartus_fit  ──► place & route                       │  │    │
  │  │  │  3. quartus_sta  ──► timing analysis                     │  │    │
  │  │  │  4. quartus_asm  ──► bitstream   (.sof / .rbf)           │  │    │
  │  │  │                                                          │  │    │
  │  │  └──────────────────────────────────────────────────────────┘  │    │
  │  └────────────────────────────────────────────────────────────────┘    │
  │         │                                                              │
  │         │  output_files/de10_blinky.sof                               │
  │         ▼                                                              │
  │  openFPGALoader -b de10nano de10_blinky.sof                           │
  │         │                                                              │
  └─────────┼──────────────────────────────────────────────────────────────┘
            │ USB (JTAG via USB-Blaster II)
            ▼
      DE10-Nano Board → LEDs blink
```

---

## Key Specifications

| Item | DE10-Nano Value |
|------|----------------|
| FPGA/SoC | Intel Cyclone V SoC — 5CSEBA6U23I7 |
| FPGA Logic Elements | 110,000 (5,570 ALMs) |
| FPGA M10K RAM | 5,140 Kbits |
| FPGA DSP blocks | 112 (×18 multipliers) |
| HPS processor | Dual-core ARM Cortex-A9, up to 925 MHz |
| HPS memory | 1 GB DDR3 (32-bit) |
| FPGA clock | 50 MHz (FPGA_CLK1_50) |
| User LEDs | 8 (active high, 3.3 V LVTTL) |
| User switches | 4 |
| Push buttons | 2 (active low) |
| Video output | HDMI TX |
| Networking | Gigabit Ethernet (HPS) |
| USB | USB OTG + USB UART (HPS) |
| Boot storage | microSD + QSPI Flash (HPS) |
| Toolchain | Quartus Prime Lite 23.1 + Cyclone V support |
| Programming | USB-Blaster II (on-board) |
| Host setup | Docker + Colima (x86_64 + Rosetta) |
