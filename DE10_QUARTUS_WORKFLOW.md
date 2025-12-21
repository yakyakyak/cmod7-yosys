# Intel Quartus Prime Workflow for Terasic DE10 Boards

This guide explains how to develop FPGA designs for Terasic DE10 boards using Intel Quartus Prime Lite, in contrast to the open-source OpenXC7 workflow used for the CMOD A7.

## Why Different Toolchains?

| Aspect | CMOD A7 (Xilinx) | DE10 (Intel/Altera) |
|--------|------------------|---------------------|
| **FPGA** | Artix-7 (Xilinx 7-series) | MAX 10 / Cyclone V |
| **Manufacturer** | AMD/Xilinx | Intel (formerly Altera) |
| **Open-Source Tools** | ✅ Full (Yosys + NextPNR + prjxray) | ⚠️ Partial (synthesis only) |
| **Proprietary Tools** | Vivado (optional) | Quartus Prime (required for P&R) |
| **Toolchain Used** | OpenXC7 (fully open) | Quartus Prime Lite (free, proprietary) |

**Bottom Line**: While Xilinx 7-series has mature open-source support via OpenXC7, Intel FPGAs still require Quartus Prime for place-and-route and bitstream generation.

## DE10 Board Comparison

### DE10-Lite ($140)
- **FPGA**: Intel MAX 10 (10M50DAF484C7G)
- **Logic Elements**: 50K LEs
- **Memory**: 64MB SDRAM
- **Features**: VGA, accelerometer, Arduino headers, GPIO
- **Best For**: Students, hobbyists, learning FPGA basics
- **User Manual**: [DE10-Lite Manual](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/Boards/DE10-Lite/DE10_Lite_User_Manual.pdf)

### DE10-Nano ($225)
- **FPGA**: Cyclone V SoC (5CSEBA6U23I7)
- **Logic Elements**: 110K LEs
- **Processor**: Dual-core ARM Cortex-A9
- **Memory**: 1GB DDR3 (HPS), no FPGA-side SDRAM
- **Features**: HDMI, Ethernet, USB OTG, Arduino headers
- **Best For**: SoC projects, embedded Linux + FPGA
- **User Manual**: [DE10-Nano Manual](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/Boards/DE10-Nano/DE10_Nano_User_Manual.pdf)

### DE10-Standard ($499)
- **FPGA**: Cyclone V SoC (5CSXFC6D6F31C6N)
- **Logic Elements**: 110K LEs
- **Processor**: Dual-core ARM Cortex-A9 (925 MHz)
- **Memory**: 64MB SDRAM (FPGA), 1GB DDR3 (HPS)
- **Features**: Video-in, VGA, HDMI, HSMC, extensive I/O
- **Best For**: Advanced projects, video processing, education
- **User Manual**: [DE10-Standard Manual](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/Boards/DE10-Standard/DE10_Standard_User_Manual.pdf)

**Recommendation**: Start with **DE10-Lite** for learning, or **DE10-Nano** if you need Linux/ARM integration.

## Quartus Prime Lite Installation

### System Requirements

**Minimum**:
- OS: Ubuntu 22.04 LTS, Windows 10/11, or macOS 12+ (limited support)
- RAM: 8GB (16GB recommended)
- Disk: 15GB for Quartus Lite + device files
- CPU: 64-bit processor

**Supported Devices in Quartus Prime Lite** (Free):
- ✅ MAX 10, MAX V
- ✅ Cyclone V, Cyclone IV, Cyclone 10 LP
- ✅ All DE10 boards fully supported
- ❌ Stratix, Arria (require paid licenses)

### Download and Install

#### Option 1: Linux (Recommended for Automation)

```bash
# Download Quartus Prime Lite 23.1std (latest as of 2024)
# Visit: https://www.intel.com/content/www/us/en/software-kit/794624/intel-quartus-prime-lite-edition-design-software-version-23-1std-for-linux.html

# Or use direct download (example for 23.1)
wget https://downloads.intel.com/akdlm/software/acdsinst/23.1std/991/ib_installers/QuartusLiteSetup-23.1std.0.991-linux.run

# Make installer executable
chmod +x QuartusLiteSetup-23.1std.0.991-linux.run

# Run installer (GUI)
./QuartusLiteSetup-23.1std.0.991-linux.run

# Or headless install
./QuartusLiteSetup-23.1std.0.991-linux.run --mode unattended --installdir ~/intelFPGA_lite/23.1std

# Add to PATH
echo 'export PATH="$HOME/intelFPGA_lite/23.1std/quartus/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
quartus_sh --version
```

**Device Support**: During installation, select:
- ✅ Quartus Prime Lite Edition
- ✅ MAX 10 FPGA device support (for DE10-Lite)
- ✅ Cyclone V device support (for DE10-Nano/Standard)
- ✅ ModelSim-Intel FPGA Starter Edition (for simulation)

#### Option 2: Windows

1. Download from [Intel FPGA Software Download](https://www.intel.com/content/www/us/en/software-kit/794624/intel-quartus-prime-lite-edition-design-software-version-23-1std-for-windows.html)
2. Run `QuartusLiteSetup-23.1std.0.991-windows.exe`
3. Follow GUI installer, select device families as above
4. Add to PATH: `C:\intelFPGA_lite\23.1std\quartus\bin64`

#### Option 3: macOS (Limited Support)

**Warning**: Intel dropped native macOS support after Quartus 19.1. Options:
- Use Quartus 19.1 (old but works natively)
- Run Linux VM with Quartus
- **Use Docker + Colima** (recommended - see below)

### Option 4: Docker + Colima (Recommended for macOS)

**Perfect if you're already using Colima for the OpenXC7 workflow!**

We've created a complete Docker setup that works seamlessly with Colima:

```bash
# Quick Start
cd docker/quartus

# 1. Download Quartus installer (manual step, ~5-6GB)
# See: docker/quartus/installers/README.md

# 2. Build and install
docker-compose build
./quartus-docker.sh install

# 3. Verify
./quartus-docker.sh quartus --version

# 4. Build your project
./quartus-docker.sh build de10_blinky

# 5. Program FPGA
./quartus-docker.sh program output_files/de10_blinky.sof
```

**Full Documentation**: See [`docker/quartus/README.md`](docker/quartus/README.md) for:
- Complete installation guide
- Colima configuration for optimal performance
- USB passthrough for FPGA programming
- X11 forwarding for GUI support
- Troubleshooting and performance tips

**Advantages**:
- ✅ Works on Apple Silicon (via Rosetta 2)
- ✅ Reuses existing Colima setup
- ✅ Consistent environment across machines
- ✅ No native macOS install mess
- ✅ ~1.2x slower than native (acceptable)

**Requirements**:
- Colima with x86_64 architecture
- 60GB disk space (Quartus ~15GB + projects)
- 8-16GB RAM allocated to VM
- XQuartz (for GUI support)

### Docker Alternative: Unofficial Images

```bash
# Use community pre-built image (not recommended for production)
docker pull raetro/quartus-lite:23.1

# Run Quartus in container
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  raetro/quartus-lite:23.1 \
  quartus_sh --version
```

**Note**: Our official setup in `docker/quartus/` is preferred as it's maintained and tested.

## Project Structure

A typical Quartus project for DE10:

```
de10-lite-blinky/
├── rtl/
│   └── blinky.v                 # Verilog source
├── constraints/
│   └── DE10_Lite.qsf            # Quartus Settings File (pin assignments)
├── simulation/
│   └── tb_blinky.v              # Testbench (optional)
├── de10_blinky.qpf              # Quartus Project File
├── de10_blinky.qsf              # Quartus Settings File (generated)
└── output_files/
    ├── de10_blinky.sof          # SRAM Object File (temporary programming)
    └── de10_blinky.pof          # Programmer Object File (flash programming)
```

## Build Workflow Comparison

### OpenXC7 (CMOD A7) vs Quartus (DE10)

| Step | CMOD A7 (OpenXC7) | DE10 (Quartus) |
|------|-------------------|----------------|
| **1. Synthesis** | Yosys (open-source) | Quartus Map (proprietary) |
| **2. Place & Route** | NextPNR-Xilinx (open) | Quartus Fit (proprietary) |
| **3. Bitstream** | xc7frames2bit (open) | Quartus Assembler (proprietary) |
| **4. Programming** | openFPGALoader | Quartus Programmer / USB-Blaster |
| **Container** | Docker (Linux) | Native install or Docker |
| **File Size** | ~40MB (tools cached) | ~5-10GB (full install) |

## Basic LED Blinky Example

### Step 1: Create Verilog Source

**File**: `rtl/blinky.v`

```verilog
// Simple LED blinky for DE10-Lite
// Blinks LED[0] at ~1 Hz using 50 MHz clock

module blinky (
    input  wire       clk,        // 50 MHz clock (MAX10_CLK1_50)
    output reg  [9:0] led         // 10 LEDs
);

    // Counter for clock division
    // 50 MHz / 2^26 = ~0.75 Hz
    reg [25:0] counter = 26'h0;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    // Assign counter bits to LEDs
    always @(posedge clk) begin
        led[0] <= counter[24];  // ~3 Hz
        led[1] <= counter[25];  // ~1.5 Hz
        led[2] <= counter[23];  // ~6 Hz
        led[3] <= 1'b0;         // Off
        led[4] <= 1'b0;
        led[5] <= 1'b0;
        led[6] <= 1'b0;
        led[7] <= 1'b0;
        led[8] <= 1'b0;
        led[9] <= 1'b0;
    end

endmodule
```

### Step 2: Create Pin Assignment File

**File**: `constraints/DE10_Lite.qsf`

```tcl
# DE10-Lite Pin Assignments for LED Blinky

# Device settings
set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M50DAF484C7G
set_global_assignment -name TOP_LEVEL_ENTITY blinky

# Clock input (50 MHz)
set_location_assignment PIN_P11 -to clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk

# LEDs (active high)
set_location_assignment PIN_A8  -to led[0]
set_location_assignment PIN_A9  -to led[1]
set_location_assignment PIN_A10 -to led[2]
set_location_assignment PIN_B10 -to led[3]
set_location_assignment PIN_D13 -to led[4]
set_location_assignment PIN_C13 -to led[5]
set_location_assignment PIN_E14 -to led[6]
set_location_assignment PIN_D14 -to led[7]
set_location_assignment PIN_A11 -to led[8]
set_location_assignment PIN_B11 -to led[9]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[9]

# Timing constraints
create_clock -name clk -period 20.000 [get_ports {clk}]
```

### Step 3: Create Project with Command Line

```bash
# Create project directory
mkdir -p de10-lite-blinky/{rtl,constraints,output_files}
cd de10-lite-blinky

# Create Quartus project
quartus_sh --tcl_eval project_new de10_blinky -overwrite

# Set device
quartus_sh --tcl_eval "project_open de10_blinky; \
  set_global_assignment -name FAMILY \"MAX 10\"; \
  set_global_assignment -name DEVICE 10M50DAF484C7G; \
  set_global_assignment -name TOP_LEVEL_ENTITY blinky; \
  set_global_assignment -name VERILOG_FILE rtl/blinky.v; \
  set_global_assignment -name SOURCE_TCL_SCRIPT_FILE constraints/DE10_Lite.qsf; \
  project_close"

# Build design
quartus_sh --flow compile de10_blinky
```

### Step 4: Build Process Explained

```bash
# Full compilation flow
quartus_sh --flow compile de10_blinky

# Or run steps individually:

# 1. Analysis & Elaboration (check syntax)
quartus_sh --analysis_and_elaboration de10_blinky

# 2. Synthesis (map to FPGA primitives)
quartus_map de10_blinky

# 3. Place & Route (fit design to device)
quartus_fit de10_blinky

# 4. Static Timing Analysis
quartus_sta de10_blinky

# 5. Assembler (generate .sof bitstream)
quartus_asm de10_blinky
```

**Build Output**:
```
output_files/
├── de10_blinky.sof         # SRAM Object File (volatile, fast programming)
├── de10_blinky.pof         # Programmer Object File (non-volatile flash)
├── de10_blinky.flow.rpt    # Compilation report
├── de10_blinky.fit.rpt     # Fitter report (resource usage)
└── de10_blinky.sta.rpt     # Timing analysis
```

## Programming the DE10 Board

### Method 1: Using Quartus Programmer (GUI)

```bash
# Launch programmer GUI
quartus_pgmw
```

Steps:
1. Hardware Setup → Select USB-Blaster
2. Add File → Browse to `output_files/de10_blinky.sof`
3. Check "Program/Configure"
4. Click "Start"

### Method 2: Command Line Programming

```bash
# Program to SRAM (temporary, lost on power cycle)
quartus_pgm -m jtag -o "p;output_files/de10_blinky.sof"

# Program to Flash (permanent)
quartus_pgm -m jtag -o "p;output_files/de10_blinky.pof"

# Auto-detect cable
quartus_pgm -l
```

### Method 3: Using openFPGALoader (Open-Source Alternative)

```bash
# Install openFPGALoader
# Ubuntu/Debian
sudo apt install openfpgaloader

# macOS
brew install openfpgaloader

# Program DE10-Lite
openFPGALoader -b de10lite output_files/de10_blinky.sof

# Program DE10-Nano
openFPGALoader -b de10nano output_files/de10_blinky.sof
```

## Makefile for Automation

**File**: `Makefile`

```makefile
# Makefile for DE10-Lite Quartus Project

PROJECT = de10_blinky
TOP_LEVEL = blinky
DEVICE_FAMILY = "MAX 10"
DEVICE = 10M50DAF484C7G

# Source files
VERILOG_SRC = rtl/blinky.v
QSF_CONSTRAINTS = constraints/DE10_Lite.qsf

# Quartus tools
QUARTUS_SH = quartus_sh
QUARTUS_MAP = quartus_map
QUARTUS_FIT = quartus_fit
QUARTUS_ASM = quartus_asm
QUARTUS_STA = quartus_sta
QUARTUS_PGM = quartus_pgm

# Output
SOF = output_files/$(PROJECT).sof
POF = output_files/$(PROJECT).pof

# Default target
all: $(SOF)

# Create project if it doesn't exist
$(PROJECT).qpf:
	$(QUARTUS_SH) --tcl_eval "project_new $(PROJECT) -overwrite; \
	  set_global_assignment -name FAMILY $(DEVICE_FAMILY); \
	  set_global_assignment -name DEVICE $(DEVICE); \
	  set_global_assignment -name TOP_LEVEL_ENTITY $(TOP_LEVEL); \
	  set_global_assignment -name VERILOG_FILE $(VERILOG_SRC); \
	  set_global_assignment -name SOURCE_TCL_SCRIPT_FILE $(QSF_CONSTRAINTS); \
	  project_close"

# Compile design
$(SOF): $(PROJECT).qpf $(VERILOG_SRC) $(QSF_CONSTRAINTS)
	$(QUARTUS_SH) --flow compile $(PROJECT)

# Individual steps
analysis:
	$(QUARTUS_SH) --analysis_and_elaboration $(PROJECT)

synth:
	$(QUARTUS_MAP) $(PROJECT)

fit:
	$(QUARTUS_FIT) $(PROJECT)

timing:
	$(QUARTUS_STA) $(PROJECT)

asm:
	$(QUARTUS_ASM) $(PROJECT)

# Programming
program: $(SOF)
	$(QUARTUS_PGM) -m jtag -o "p;$(SOF)"

program-flash: $(POF)
	$(QUARTUS_PGM) -m jtag -o "p;$(POF)"

# Using openFPGALoader
program-open: $(SOF)
	openFPGALoader -b de10lite $(SOF)

# Clean
clean:
	rm -rf output_files/ db/ incremental_db/ .qsys_edit/ *.rpt *.summary *.qws *.qtl

# Help
help:
	@echo "DE10-Lite Quartus Build System"
	@echo "=============================="
	@echo "Targets:"
	@echo "  all            - Compile complete design (default)"
	@echo "  analysis       - Analysis & elaboration only"
	@echo "  synth          - Run synthesis"
	@echo "  fit            - Run place & route"
	@echo "  timing         - Run timing analysis"
	@echo "  asm            - Generate bitstream"
	@echo "  program        - Program to SRAM (USB-Blaster)"
	@echo "  program-flash  - Program to Flash (USB-Blaster)"
	@echo "  program-open   - Program using openFPGALoader"
	@echo "  clean          - Remove build files"
	@echo ""
	@echo "Usage:"
	@echo "  make                    # Build bitstream"
	@echo "  make program            # Program board"

.PHONY: all analysis synth fit timing asm program program-flash program-open clean help
```

**Usage**:
```bash
# Build bitstream
make

# Program board
make program

# Or with openFPGALoader
make program-open

# Clean build
make clean
```

## Hybrid Open-Source Approach

You can use Yosys for synthesis, then Quartus for place-and-route:

```bash
# Step 1: Synthesis with Yosys (open-source)
yosys -p "read_verilog rtl/blinky.v; \
          synth_intel -family max10 -top blinky; \
          write_verilog -noattr output_yosys.v"

# Step 2: Create Quartus project using Yosys output
quartus_sh --tcl_eval "project_new de10_blinky -overwrite; \
  set_global_assignment -name VERILOG_FILE output_yosys.v; \
  # ... rest of settings ..."

# Step 3: Place & Route with Quartus (proprietary)
quartus_fit de10_blinky
quartus_asm de10_blinky
```

**Trade-offs**:
- ✅ Synthesis is open-source and reproducible
- ❌ Still depends on Quartus for P&R
- ⚠️ May lose some optimization vs. native Quartus flow

## Resources and References

### Official Documentation
- [Quartus Prime Lite Download](https://www.intel.com/content/www/us/en/software-kit/794624/intel-quartus-prime-lite-edition-design-software-version-23-1std-for-linux.html)
- [DE10-Lite User Manual](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/Boards/DE10-Lite/DE10_Lite_User_Manual.pdf)
- [DE10-Nano User Manual](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/Boards/DE10-Nano/DE10_Nano_User_Manual.pdf)
- [DE10-Standard User Manual](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/Boards/DE10-Standard/DE10_Standard_User_Manual.pdf)

### Terasic Resources
- [DE10-Lite Product Page](http://de10-lite.terasic.com/)
- [DE10-Nano Product Page](https://de10-nano.terasic.com/)
- [DE10-Standard Product Page](http://de10-standard.terasic.com/)

### Open-Source Tools
- [openFPGALoader](https://github.com/trabucayre/openFPGALoader) - Open-source programming tool
- [Yosys](https://github.com/YosysHQ/yosys) - Open-source synthesis (partial support)
- [Project Mistral](https://github.com/Ravenslofty/mistral) - Experimental Cyclone V reverse engineering

## Next Steps

1. **Install Quartus Prime Lite** for your OS
2. **Download DE10 examples** from Terasic website
3. **Try the LED blinky** example above
4. **Explore Intel FPGA University Program** tutorials
5. **Consider SoC designs** if using DE10-Nano/Standard

## Comparison Summary

For those coming from the CMOD A7 OpenXC7 workflow:

| Feature | CMOD A7 + OpenXC7 | DE10 + Quartus |
|---------|-------------------|----------------|
| **Fully Open-Source** | ✅ Yes | ❌ No (P&R proprietary) |
| **Free to Use** | ✅ Yes | ✅ Yes (Lite edition) |
| **Linux Support** | ✅ Excellent | ✅ Excellent |
| **Docker/Container** | ✅ Easy | ⚠️ Possible but large |
| **Install Size** | ~1GB | ~10-15GB |
| **Learning Curve** | Moderate | Easier (mature GUI) |
| **Build Speed** | Fast | Moderate |
| **SoC/ARM Support** | ❌ No | ✅ Yes (DE10-Nano/Std) |

Choose CMOD A7 for fully open-source workflows, or DE10 if you need more resources, ARM integration, or don't mind proprietary tools.
