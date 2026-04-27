# CMOD A7-35T Platform

**Board**: Digilent CMOD A7-35T — breadboardable Artix-7 module  
**FPGA**: Xilinx Artix-7 xc7a35tcpg236-1 (CPG236 BGA, 8150 logic cells, 90 DSPs)  
**Clock**: 12 MHz on-board oscillator (pin L17)  
**UART**: FTDI FT2232HL Channel B — virtual serial port over USB Micro, no additional hardware needed

## Design

The top module (`platforms/cmod_a7/top.v`) wires together shared RTL from `src/` and `library/`:

| Signal | Pin | Notes |
|--------|-----|-------|
| `clk` | L17 | 12 MHz oscillator |
| `led[0]` | A17 | Blinks at ~0.71 Hz (counter[23]) or UART-controlled |
| `led[1]` | C16 | Blinks at ~1.43 Hz (counter[22]) or UART-controlled |
| `pio1` (PWM) | M3 | DIP pin 2; ~46.9 kHz PWM, duty auto-breathes or UART-controlled |
| `uart_rxd_in` | J17 | FPGA RX ← FTDI TX |
| `uart_txd_out` | J18 | FPGA TX → FTDI RX |

See [PINOUT.md](PINOUT.md) for the full 48-pin DIP header reference.

## Build — Vivado (preferred)

Requires Vivado 2025.2.1 at `~/vivado/`. Adjust the path in `build-vivado.sh` if needed.

```bash
./build-vivado.sh
```

Outputs to `build/vivado/`:

| File | Description |
|------|-------------|
| `blinky.bit` | Programmable bitstream |
| `timing_summary.rpt` | Timing report |
| `utilization.rpt` | Resource utilization |
| `post_route.dcp` | Post-route checkpoint (open in Vivado GUI for debug) |

## Build — OpenXC7 (open-source, Docker)

Requires Docker and Colima (x86_64) on macOS Apple Silicon:

```bash
colima start --arch x86_64 --vm-type=vz --vz-rosetta
./docker-build.sh
```

Output: `build/blinky.bit`. The five-step pipeline (Yosys synthesis → chipdb → NextPNR → fasm2frames → xc7frames2bit) is described in the root README.

> Chipdb generation (`build/xc7a35tcpg236-1.bin`, 88 MB) runs once and is cached.

## Programming

```bash
# SRAM — temporary, cleared on power-cycle
openFPGALoader -b cmoda7_35t build/vivado/blinky.bit

# Flash — persistent across power cycles
openFPGALoader -b cmoda7_35t -f build/vivado/blinky.bit
```

Use `build/blinky.bit` instead if programming from the OpenXC7 flow.

You can also use **Vivado Hardware Manager** (open `build/vivado/post_route.dcp`, connect to target, program device).

## Resource Utilization (Vivado flow)

```
Slice LUTs:    ~50 / 20800    < 1%
Slice FFs:     ~25 / 41600    < 1%
DSPs:            0 /    90      0%
BRAMs:           0 /    50      0%
```

## Constraints

See `platforms/cmod_a7/cmod_a7.xdc`. All I/O are LVCMOS33.

## UART Register Interface

The FTDI USB bridge exposes a virtual COM port (no driver install needed on Linux/macOS):

```bash
# macOS
python tools/reg_access.py /dev/tty.usbserial-XXXXB ping

# Linux
python tools/reg_access.py /dev/ttyUSB1 ping
```

See [library/uart/docs/register-interface.md](../../library/uart/docs/register-interface.md) for the full register map and protocol.
