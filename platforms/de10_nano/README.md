# DE10-Nano Platform

**Board**: Terasic DE10-Nano  
**FPGA**: Intel Cyclone V SoC (5CSEBA6U23I7) — 110K logic elements, dual ARM Cortex-A9 @ 925 MHz  
**Clock**: 50 MHz on-board oscillator (FPGA_CLK1_50, pin V11)  
**Toolchain**: Intel Quartus Prime Lite (required for place-and-route)

## Design

The top module (`platforms/de10_nano/top.v`) runs the same shared RTL as CMOD A7 with three clock-frequency adjustments (50 MHz vs 12 MHz) and adds a JTAG UART path alongside the GPIO UART:

| Signal | Pin | Notes |
|--------|-----|-------|
| `clk` | V11 | 50 MHz FPGA_CLK1_50 |
| `led[0]` | W15 | Active-low; blinks ~0.75 Hz (counter[25]) or UART-controlled |
| `led[1]` | AA24 | Active-low; blinks ~1.5 Hz (counter[24]) or UART-controlled |
| `led[2:7]` | V16…AA23 | Show counter[23:18] (binary counter display) |
| `uart_rxd_in` | V12 | GPIO_0[0] — external USB-UART adapter required |
| `uart_txd_out` | E8 | GPIO_0[1] |
| `pwm_out` | W12 | GPIO_0[2] |

**JTAG UART**: The design also instantiates `alt_jtag_atlantic` so you can use the on-board USB Blaster without an external serial adapter. JTAG has RX priority; in practice only one path is active at a time.

## Prerequisites

**Linux (recommended)**: Install Quartus Prime Lite 25.1std to `~/altera_lite/25.1std/`:

```bash
# Download from Intel FPGA downloads page:
# https://www.intel.com/content/www/us/en/software-kit/825278/
chmod +x QuartusLiteSetup-25.1std-linux.run
./QuartusLiteSetup-25.1std-linux.run --mode unattended \
    --installdir ~/altera_lite/25.1std \
    --accept_eula 1
```

Select device support: **Cyclone V** (required). ModelSim-Intel is optional.

**macOS (Apple Silicon)**: Native Quartus does not support macOS beyond 19.1. Use the Docker + Colima setup:

```bash
cd docker/quartus
# See docker/quartus/README.md for full setup instructions
./quartus-docker.sh install
./quartus-docker.sh build de10_nano
```

## Build

```bash
cd platforms/de10_nano
./build.sh
```

The script calls `quartus_sh --flow compile de10_nano` and expects Quartus at `~/altera_lite/25.1std/quartus/bin`. Edit the `QUARTUS_BIN` line in `build.sh` if your install path differs.

**Output**: `platforms/de10_nano/output_files/de10_nano.sof`

## Programming

```bash
# SRAM — temporary, lost on power-cycle (fastest)
openFPGALoader -b de10nano platforms/de10_nano/output_files/de10_nano.sof

# Or using Quartus Programmer
quartus_pgm -m jtag -o "p;platforms/de10_nano/output_files/de10_nano.sof"
```

For permanent flash programming, convert `.sof` → `.jic` in Quartus Convert Programming Files, then:

```bash
openFPGALoader -b de10nano --write-flash de10_nano.jic
```

## UART Register Interface

### Via GPIO_0 header (external USB-UART adapter)

Connect a 3.3V USB-UART adapter to the GPIO_0 header (J1):
- GPIO_0[0] (pin V12) → adapter RX
- GPIO_0[1] (pin E8)  → adapter TX
- GND → adapter GND

```bash
python tools/reg_access.py /dev/ttyUSB0 ping
```

### Via JTAG UART (no external hardware)

With Quartus tools installed:

```bash
nios2-terminal --instance=0
```

Or use the Python tool if `tools/reg_access_jtag.py` is present.

See [library/uart/docs/register-interface.md](../../library/uart/docs/register-interface.md) for the full register map and protocol.

## Key Differences from CMOD A7

| Aspect | CMOD A7 | DE10-Nano |
|--------|---------|-----------|
| Clock | 12 MHz | 50 MHz |
| Counter width | 24-bit | 26-bit (same visible blink rate) |
| LEDs | 2 (active high) | 8 (active low; only [0:1] UART-controlled) |
| UART path | FTDI USB (built-in) | GPIO_0 header + JTAG UART |
| Synthesis | Vivado or OpenXC7 | Quartus Prime Lite |
| HPS (ARM) | None | Dual Cortex-A9 (not used in this design) |

## HPS Bring-Up (Future)

The Cyclone V SoC's Hard Processor System (ARM Cortex-A9 + Linux) is not used in this blinky design. See [plans/de10_nano_hps_bringup.md](../../plans/de10_nano_hps_bringup.md) for the SD-card bring-up plan covering U-Boot, Linux kernel, and FPGA-HPS bridge setup.
