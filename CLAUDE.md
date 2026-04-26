# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FPGA design for the Digilent CMOD A7-35T board (Xilinx Artix-7 xc7a35tcpg236-1) using the open-source OpenXC7 toolchain. The design implements LED blinking, a PWM output, and a UART register interface — all controlled by a free-running 24-bit counter or overridden via UART commands.

## Build Commands

### Docker-based Build (Recommended)
```bash
./docker-build.sh                    # Complete build (synthesis → bitstream)
```

The build uses the `ghcr.io/meriac/openxc7-litex:latest` container and produces `build/blinky.bit`.

**Important Docker Setup**: On macOS with Apple Silicon, Colima must be running with x86_64 emulation:
```bash
colima start --arch x86_64 --vm-type=vz --vz-rosetta
```

### Build Steps
The `docker-build.sh` script runs 5 sequential steps:
1. **Synthesis** (Yosys): sources → `build/blinky.json`
2. **Chipdb Generation** (bbaexport/bbasm): Creates `build/xc7a35tcpg236-1.bin` (88 MB, cached after first run)
3. **Place & Route** (NextPNR): `build/blinky.json` + `constraints/cmod_a7.xdc` → `build/blinky.fasm`
4. **FASM to Frames** (fasm2frames): `build/blinky.fasm` → `build/blinky.frames`
5. **Bitstream Generation** (xc7frames2bit): `build/blinky.frames` → `build/blinky.bit`

### Simulation — Icarus Verilog
```bash
./simulate.sh               # Quick simulation (~65K cycles, <1s)
./simulate.sh quick         # LED/counter testbench, fast
./simulate.sh full          # LED/counter testbench, ~8M cycles
./simulate.sh uart          # UART register interface integration test
```

Requires: `iverilog`; optional: `surfer` for waveform viewing.

### Simulation — Vivado (xsim)
```bash
./simulate-vivado.sh               # Quick simulation (default)
./simulate-vivado.sh quick         # LED/counter testbench, fast
./simulate-vivado.sh full          # LED/counter testbench, ~8M cycles
./simulate-vivado.sh uart          # UART register interface integration test
```

Requires: Vivado installed at `~/vivado`; `settings64.sh` is sourced automatically by the script.

### Makefile Targets
```bash
make sim-quick              # Icarus: quick simulation
make sim-full               # Icarus: full simulation
make sim-uart               # Icarus: UART register test
make wave-quick             # View quick waveform in Surfer
make wave-full              # View full waveform in Surfer
make wave-uart              # View UART waveform in Surfer
make clean                  # Remove build artifacts
make clean-sim              # Remove simulation outputs
```

Note: The Makefile's build targets expect `CHIPDB` and `PRJXRAY_DB_DIR` environment variables set inside the Docker container. Use `docker-build.sh` for hardware builds.

## Code Architecture

### Hardware Design
The top module (`src/top.v`) wires together four submodules around a free-running 24-bit counter:

- **`library/uart/uart_rx.v`** / **`uart_tx.v`**: 8N1 UART at 115200 baud (CLK_FREQ/BAUD_RATE parameterized)
- **`src/reg_ctrl.v`**: UART command parser; 4-state FSM (IDLE→ADDR→WDATA→RESP) that implements Ping/Read/Write over the byte protocol below. Drives `led_ctrl`, `led_mode`, `pwm_duty_reg`, `pwm_mode`.
- **`src/pwm_generator.v`**: Free-running counter vs. duty comparator; PWM frequency = CLK / 2^COUNTER_WIDTH (~46.9 kHz at 8 bits)
- **`src/top.v`**: Muxes between auto (counter-driven) and manual (register-driven) modes for both LEDs and PWM

### UART Register Protocol
Single-byte commands, 8N1, 115200 baud on FTDI FT2232HL Channel B (RX=J17, TX=J18):

| Command | TX bytes    | RX bytes          |
|---------|-------------|-------------------|
| Ping    | `'P'`       | `'P'`             |
| Read    | `'R' ADDR`  | `'A' ADDR DATA` or `'N' ADDR` |
| Write   | `'W' ADDR DATA` | `'A' ADDR DATA` or `'N' ADDR` |

Register map (from `tools/reg_access.py`):

| Addr | Name     | R/W | Description                        |
|------|----------|-----|------------------------------------|
| 0x00 | LED_CTRL | R/W | bit[1:0] = led[1:0] (manual mode)  |
| 0x01 | LED_MODE | R/W | 0=auto blink, 1=manual             |
| 0x02 | PWM_DUTY | R/W | manual PWM duty 0–255              |
| 0x03 | PWM_MODE | R/W | 0=auto breathing, 1=manual         |
| 0x04 | CNT_HI   | RO  | counter[23:16]                     |
| 0x05 | CNT_MID  | RO  | counter[15:8]                      |
| 0x06 | CNT_LO   | RO  | counter[7:0]                       |
| 0x07 | VERSION  | RO  | 0xA7                               |

### Constraints
- **`constraints/cmod_a7.xdc`**: Clock L17 (12 MHz), LED[0]=A17, LED[1]=C16, PWM=M3, UART RX=J17, TX=J18; all LVCMOS33

### Simulation Testbenches
- **`sim/tb_top_quick.v`**: ~65K cycles, checks counter increment and LED assignments
- **`sim/tb_top.v`**: ~8M cycles, observes full LED toggle period
- **`sim/tb_top_pwm_quick.v`**: ~65K cycles, verifies PWM duty cycle measurement
- **`sim/tb_top_pwm.v`**: Full PWM simulation
- **`sim/tb_uart_reg.v`**: Integration test — drives UART RX bit-by-bit and checks TX responses for ping, version read, LED/PWM write+readback, and NAK on bad address

### Build System
- **`docker-build.sh`**: Main build script; hardcoded `PROJECT="blinky"`, `PART="xc7a35tcpg236-1"`. Caches chipdb (88 MB, ~2–3 min to generate). Uses `docker cp` workaround for fasm2frames permission issues.
- **`simulate.sh`**: Icarus Verilog wrapper with colored output and optional Surfer launch
- **`simulate-vivado.sh`**: Vivado xsim wrapper (sources `~/vivado/2025.2.1/Vivado/settings64.sh`)

### Tools
- **`tools/reg_access.py`**: Host-side Python CLI for UART register access. Requires `pyserial`.
  ```bash
  python tools/reg_access.py /dev/tty.usbserial-XXXXB ping
  python tools/reg_access.py /dev/tty.usbserial-XXXXB write 0x01 1
  ```

### Key Implementation Details

**Docker Container Paths** (in `docker-build.sh`):
- Tools: `/home/builder/.local/bin`
- NextPNR Python: `/home/builder/.local/share/nextpnr/python`
- Project X-Ray DB: `/home/builder/.local/share/nextpnr/external/prjxray-db`

**No reset**: The CMOD A7 has no reset button. `reg_ctrl` uses Verilog `initial` blocks for power-on state (Xilinx supports this); `rst` is tied to `1'b0`.

**Chipdb Caching**: Step 2 is skipped if `build/xc7a35tcpg236-1.bin` exists.

## Modifying the Design

To change the FPGA part or project name, edit `docker-build.sh`:
```bash
PROJECT="blinky"              # Line 6
PART="xc7a35tcpg236-1"       # Line 7
```
Also update corresponding values in the Makefile.

## Programming the FPGA

```bash
openFPGALoader -b cmoda7_35t build/blinky.bit        # SRAM (temporary)
openFPGALoader -b cmoda7_35t -f build/blinky.bit     # Flash (persistent)
```

See README.md for detailed programming instructions.
