# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FPGA LED blinky example for the Digilent CMOD A7-35T board (Xilinx Artix-7 xc7a35tcpg236-1) using the open-source OpenXC7 toolchain. The design is a simple counter-based LED blinker implemented in Verilog.

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
1. **Synthesis** (Yosys): `src/top.v` → `build/blinky.json`
2. **Chipdb Generation** (bbaexport/bbasm): Creates `build/xc7a35tcpg236-1.bin` (88 MB, cached after first run)
3. **Place & Route** (NextPNR): `build/blinky.json` + `constraints/cmod_a7.xdc` → `build/blinky.fasm`
4. **FASM to Frames** (fasm2frames): `build/blinky.fasm` → `build/blinky.frames`
5. **Bitstream Generation** (xc7frames2bit): `build/blinky.frames` → `build/blinky.bit`

### Simulation
```bash
./simulate.sh               # Quick simulation (~65K cycles, <1s)
./simulate.sh quick         # Same as above
./simulate.sh full          # Full simulation (~8M cycles, several minutes)
```

Requires: `iverilog` (Icarus Verilog)
Optional: `surfer` for waveform viewing

### Makefile Targets
```bash
make sim-quick              # Run quick simulation
make sim-full               # Run full simulation
make wave-quick             # View quick simulation waveforms in Surfer
make wave-full              # View full simulation waveforms in Surfer
make clean                  # Remove build artifacts
make clean-sim              # Remove simulation outputs
```

Note: The Makefile's build targets expect environment variables (CHIPDB, PRJXRAY_DB_DIR) that are set in the Docker container. Use `docker-build.sh` for builds.

## Code Architecture

### Hardware Design
- **src/top.v**: Top-level Verilog module
  - Single 24-bit counter incremented on each clock cycle
  - LEDs mapped to counter bits (led[0]=counter[23], led[1]=counter[22])
  - Minimal design: 35 FPGA cells, achieves 285 MHz (23.8x margin over 12 MHz clock)

### Constraints
- **constraints/cmod_a7.xdc**: Pin assignments and I/O standards for CMOD A7-35T
  - Clock: L17 (12 MHz oscillator)
  - LED[0]: A17, LED[1]: C16
  - All pins use LVCMOS33 I/O standard

### Simulation
- **sim/tb_top_quick.v**: Fast testbench (~65K cycles)
- **sim/tb_top.v**: Full testbench (~8M cycles to observe LED toggles)
- Both testbenches verify counter increment and LED assignments

### Build System
- **docker-build.sh**: Main build script using OpenXC7 Docker container
  - Hardcoded project name: "blinky"
  - Hardcoded part: "xc7a35tcpg236-1"
  - Uses docker cp workaround for fasm2frames permission issues
  - Automatic chipdb caching to speed up subsequent builds

- **simulate.sh**: Wrapper for Icarus Verilog simulation
  - Colored output for compilation/simulation status
  - Optional interactive launch of Surfer waveform viewer

### Key Implementation Details

**Docker Container Paths** (in docker-build.sh):
- Tools: `/home/builder/.local/bin`
- NextPNR Python: `/home/builder/.local/share/nextpnr/python`
- Project X-Ray DB: `/home/builder/.local/share/nextpnr/external/prjxray-db`

**Chipdb Caching**: The chipdb generation step (Step 2) checks if `build/xc7a35tcpg236-1.bin` exists and skips regeneration if found. This file takes 2-3 minutes to generate but is reused across builds.

**Permission Workaround**: Step 4 (fasm2frames) uses a detached container with docker cp to avoid permission issues when writing to the build directory.

## Modifying the Design

To change the FPGA part or project name, edit the following in `docker-build.sh`:
```bash
PROJECT="blinky"              # Line 6
PART="xc7a35tcpg236-1"       # Line 7
```

Also update corresponding values in the Makefile if using make targets.

## Programming the FPGA

Not handled by the build scripts. Use external tools:
- openFPGALoader: `openFPGALoader -b cmoda7_35t build/blinky.bit`
- OpenOCD, Digilent Adept, or Vivado Hardware Manager

See README.md for detailed programming instructions.
