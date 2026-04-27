# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Multi-platform FPGA design targeting the Digilent CMOD A7-35T (Xilinx Artix-7) and Terasic DE10-Nano (Intel Cyclone V). The design implements LED blinking, a PWM output, and a UART register interface — all controlled by a free-running counter or overridden via UART commands.

**Toolchains**:
- CMOD A7: **Vivado** (preferred, `build-vivado.sh`) or OpenXC7/Yosys (open-source, `docker-build.sh`)
- DE10-Nano: **Quartus Prime Lite** (`platforms/de10_nano/build.sh`)

## Build Commands

### CMOD A7 — Vivado (preferred)
```bash
./build-vivado.sh                    # Synthesis + implementation + bitstream
```
Output: `build/vivado/blinky.bit`. Requires Vivado at `~/vivado/2025.2.1/Vivado/`.

### CMOD A7 — OpenXC7 (open-source Docker)
```bash
./docker-build.sh                    # Complete build (synthesis → bitstream)
```
Output: `build/blinky.bit`. Uses `ghcr.io/meriac/openxc7-litex:latest`.

**Docker setup on macOS/Apple Silicon**:
```bash
colima start --arch x86_64 --vm-type=vz --vz-rosetta
```

#### OpenXC7 Build Steps
1. **Synthesis** (Yosys): sources → `build/blinky.json`
2. **Chipdb** (bbaexport/bbasm): `build/xc7a35tcpg236-1.bin` (88 MB, cached after first run)
3. **Place & Route** (NextPNR): → `build/blinky.fasm`
4. **FASM to Frames**: → `build/blinky.frames`
5. **Bitstream** (xc7frames2bit): → `build/blinky.bit`

### DE10-Nano — Quartus
```bash
cd platforms/de10_nano && ./build.sh
```
Output: `platforms/de10_nano/output_files/de10_nano.sof`. Requires Quartus at `~/altera_lite/25.1std/`.

### Simulation — Icarus Verilog
```bash
./simulate.sh               # Quick simulation (~65K cycles, <1s)
./simulate.sh quick         # LED/counter testbench, fast
./simulate.sh full          # LED/counter testbench, ~8M cycles
./simulate.sh uart          # UART register interface integration test
```

### Simulation — Vivado (xsim)
```bash
./simulate-vivado.sh               # Quick simulation (default)
./simulate-vivado.sh quick
./simulate-vivado.sh full
./simulate-vivado.sh uart
```
Requires Vivado at `~/vivado`; `settings64.sh` is sourced automatically.

### Simulation — Verilator
```bash
./simulate-verilator.sh [quick|full|uart]
```

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

## Code Architecture

### Repository Layout
```
platforms/cmod_a7/   top.v, cmod_a7.xdc, build.sh  (Artix-7 top + constraints)
platforms/de10_nano/ top.v, de10_nano.qsf, build.sh (Cyclone V top + constraints)
src/                 reg_ctrl.v, pwm_generator.v     (shared RTL)
library/uart/        uart_rx.v, uart_tx.v            (shared UART library)
sim/                 tb_top*.v, tb_uart_reg.v         (shared testbenches)
```

### Hardware Design
Each platform's `top.v` wires shared modules around a free-running counter:

- **`library/uart/uart_rx.v`** / **`uart_tx.v`**: 8N1 UART (CLK_FREQ/BAUD_RATE parameterized)
- **`src/reg_ctrl.v`**: 4-state FSM (IDLE→ADDR→WDATA→RESP); Ping/Read/Write protocol; drives `led_ctrl`, `led_mode`, `pwm_duty_reg`, `pwm_mode`
- **`src/pwm_generator.v`**: duty comparator; PWM freq = CLK / 2^COUNTER_WIDTH

### UART Register Protocol
| Command | TX bytes | RX bytes |
|---------|----------|----------|
| Ping | `'P'` | `'P'` |
| Read | `'R' ADDR` | `'A' ADDR DATA` or `'N' ADDR` |
| Write | `'W' ADDR DATA` | `'A' ADDR DATA` or `'N' ADDR` |

Register map: LED_CTRL (0x00), LED_MODE (0x01), PWM_DUTY (0x02), PWM_MODE (0x03), CNT_HI/MID/LO (0x04–0x06), VERSION (0x07).

### Key Implementation Details

**CMOD A7 UART**: FTDI FT2232HL Channel B, pins J17 (RX) / J18 (TX). No external hardware needed.

**DE10-Nano UART**: Two paths — GPIO_0 header (PIN_V12/E8, external adapter required) and JTAG UART (`alt_jtag_atlantic`, USB Blaster). JTAG has RX priority.

**No reset**: `reg_ctrl` uses Verilog `initial` blocks; `rst` is tied to `1'b0`. Xilinx and Intel both support synthesis of `initial`.

**Chipdb Caching** (OpenXC7): Step 2 skipped if `build/xc7a35tcpg236-1.bin` exists.

**Docker Container Paths** (in `docker-build.sh`):
- Tools: `/home/builder/.local/bin`
- NextPNR Python: `/home/builder/.local/share/nextpnr/python`
- Project X-Ray DB: `/home/builder/.local/share/nextpnr/external/prjxray-db`

### Simulation Testbenches
- **`sim/tb_top_quick.v`**: ~65K cycles, checks counter and LED assignments
- **`sim/tb_top.v`**: ~8M cycles, full LED toggle period
- **`sim/tb_top_pwm_quick.v`**: ~65K cycles, PWM duty cycle measurement
- **`sim/tb_top_pwm.v`**: Full PWM simulation
- **`sim/tb_uart_reg.v`**: Integration test — drives UART bit-by-bit, checks ping/read/write/NAK

### Tools
- **`tools/reg_access.py`**: Host-side Python CLI. Requires `pyserial`.
  ```bash
  python tools/reg_access.py /dev/tty.usbserial-XXXXB ping
  python tools/reg_access.py /dev/tty.usbserial-XXXXB write 0x01 1
  ```

## Platform-Specific Notes

### CMOD A7-35T
- See `platforms/cmod_a7/README.md` and `platforms/cmod_a7/PINOUT.md`
- Constraints: `platforms/cmod_a7/cmod_a7.xdc`
- Vivado output: `build/vivado/blinky.bit`; OpenXC7 output: `build/blinky.bit`

### DE10-Nano
- See `platforms/de10_nano/README.md`
- Constraints: `platforms/de10_nano/de10_nano.qsf` + `de10_nano.sdc`
- Quartus output: `platforms/de10_nano/output_files/de10_nano.sof`
- macOS: use Docker via `docker/quartus/` — see `docker/quartus/README.md`

## Programming the FPGA

```bash
# CMOD A7
openFPGALoader -b cmoda7_35t build/vivado/blinky.bit        # SRAM
openFPGALoader -b cmoda7_35t -f build/vivado/blinky.bit     # Flash

# DE10-Nano
openFPGALoader -b de10nano platforms/de10_nano/output_files/de10_nano.sof
```
