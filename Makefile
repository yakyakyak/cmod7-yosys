# Makefile for CMOD A7-35T LED Blinky
# OpenXC7 toolchain (yosys + nextpnr-xilinx)

# Project settings
PROJECT = blinky
TOP_MODULE = top
PART = xc7a35tcpg236-1

# Source files
VERILOG_SRC = src/top.v
XDC_FILE = constraints/cmod_a7.xdc

# Build directory
BUILD_DIR = build

# Docker settings
# Set USE_DOCKER=1 to use Docker for builds
USE_DOCKER ?= 0
DOCKER_IMAGE = openxc7-toolchain:latest
DOCKER_RUN = docker run --rm -v $(PWD):/workspace -w /workspace $(DOCKER_IMAGE)

# Toolchain commands (wrapped in Docker if enabled)
ifeq ($(USE_DOCKER),1)
	YOSYS = $(DOCKER_RUN) yosys
	NEXTPNR = $(DOCKER_RUN) nextpnr-xilinx
	PYPY3 = $(DOCKER_RUN) pypy3
	FASM2FRAMES = fasm2frames.py
	XC7FRAMES2BIT = $(DOCKER_RUN) xc7frames2bit
	OPENFPGALOADER = $(DOCKER_RUN) openFPGALoader
else
	YOSYS = yosys
	NEXTPNR = nextpnr-xilinx
	PYPY3 = pypy3
	FASM2FRAMES = fasm2frames.py
	XC7FRAMES2BIT = xc7frames2bit
	OPENFPGALOADER = openFPGALoader
endif

# Board for programming
BOARD = cmoda7_35t

# Build outputs
JSON = $(BUILD_DIR)/$(PROJECT).json
FASM = $(BUILD_DIR)/$(PROJECT).fasm
FRAMES = $(BUILD_DIR)/$(PROJECT).frames
BITSTREAM = $(BUILD_DIR)/$(PROJECT).bit

# Simulation outputs
SIM_DIR = sim
TB_QUICK = $(SIM_DIR)/tb_top_quick.v
TB_FULL = $(SIM_DIR)/tb_top.v
VCD_QUICK = $(BUILD_DIR)/tb_top_quick.vcd
VCD_FULL = $(BUILD_DIR)/tb_top.vcd
VVP_QUICK = $(BUILD_DIR)/tb_top_quick.vvp
VVP_FULL = $(BUILD_DIR)/tb_top.vvp

# Default target
all: $(BITSTREAM)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Synthesis with Yosys
$(JSON): $(VERILOG_SRC) | $(BUILD_DIR)
	$(YOSYS) -p "read_verilog $(VERILOG_SRC); synth_xilinx -flatten -abc9 -arch xc7 -top $(TOP_MODULE); write_json $@"

# Place and Route with nextpnr-xilinx
$(FASM): $(JSON) $(XDC_FILE)
	$(NEXTPNR) --chipdb $(CHIPDB)/$(PART).bin --xdc $(XDC_FILE) --json $(JSON) --write $(BUILD_DIR)/$(PROJECT)_routed.json --fasm $@

# Convert FASM to frames
$(FRAMES): $(FASM)
	$(PYPY3) $(FASM2FRAMES) --part $(PART) --db-root $(PRJXRAY_DB_DIR)/artix7 $< > $@

# Generate bitstream
$(BITSTREAM): $(FRAMES)
	$(XC7FRAMES2BIT) --part_file $(PRJXRAY_DB_DIR)/artix7/$(PART)/part.yaml --part_name $(PART) --frm_file $< --output_file $@

# Individual targets
synth: $(JSON)

pnr: $(FASM)

bitstream: $(BITSTREAM)

# Program FPGA (SRAM - temporary)
program: $(BITSTREAM)
	$(OPENFPGALOADER) -b $(BOARD) $(BITSTREAM)

# Program FPGA (Flash - persistent)
program-flash: $(BITSTREAM)
	$(OPENFPGALOADER) -b $(BOARD) -f $(BITSTREAM)

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)

# Simulation targets
sim: sim-quick

sim-quick: $(VCD_QUICK)

sim-full: $(VCD_FULL)

$(VVP_QUICK): $(VERILOG_SRC) $(TB_QUICK) | $(BUILD_DIR)
	iverilog -o $@ -g2012 -I$(dir $(VERILOG_SRC)) $(VERILOG_SRC) $(TB_QUICK)

$(VCD_QUICK): $(VVP_QUICK)
	vvp $<
	@echo "Simulation complete. Waveform saved to $(VCD_QUICK)"

$(VVP_FULL): $(VERILOG_SRC) $(TB_FULL) | $(BUILD_DIR)
	iverilog -o $@ -g2012 -I$(dir $(VERILOG_SRC)) $(VERILOG_SRC) $(TB_FULL)

$(VCD_FULL): $(VVP_FULL)
	vvp $<
	@echo "Simulation complete. Waveform saved to $(VCD_FULL)"

wave-quick: $(VCD_QUICK)
	@if command -v surfer >/dev/null 2>&1; then \
		surfer $(VCD_QUICK) & \
	else \
		echo "Error: surfer not found. Install with: cargo install surfer"; \
		echo "Or download from: https://github.com/surfer-project/surfer"; \
		exit 1; \
	fi

wave-full: $(VCD_FULL)
	@if command -v surfer >/dev/null 2>&1; then \
		surfer $(VCD_FULL) & \
	else \
		echo "Error: surfer not found. Install with: cargo install surfer"; \
		echo "Or download from: https://github.com/surfer-project/surfer"; \
		exit 1; \
	fi

clean-sim:
	rm -f $(VCD_QUICK) $(VCD_FULL) $(VVP_QUICK) $(VVP_FULL)

# Docker-specific targets
docker-build:
	docker build -t $(DOCKER_IMAGE) .

docker-shell:
	docker run --rm -it -v $(PWD):/workspace -w /workspace $(DOCKER_IMAGE) bash

docker-clean:
	docker rmi $(DOCKER_IMAGE) 2>/dev/null || true

# Display help
help:
	@echo "CMOD A7-35T LED Blinky Build System"
	@echo "===================================="
	@echo "Build Targets:"
	@echo "  all            - Build complete bitstream (default)"
	@echo "  synth          - Run synthesis only"
	@echo "  pnr            - Run place and route"
	@echo "  bitstream      - Generate bitstream"
	@echo "  program        - Program FPGA (SRAM - temporary)"
	@echo "  program-flash  - Program FPGA (Flash - persistent)"
	@echo "  clean          - Remove build artifacts"
	@echo ""
	@echo "Simulation Targets:"
	@echo "  sim            - Run quick simulation (default, ~65K cycles)"
	@echo "  sim-quick      - Run quick simulation (~65K cycles, <1s)"
	@echo "  sim-full       - Run full simulation (~8M cycles, minutes)"
	@echo "  wave-quick     - View quick simulation waveforms in Surfer"
	@echo "  wave-full      - View full simulation waveforms in Surfer"
	@echo "  clean-sim      - Remove simulation outputs"
	@echo ""
	@echo "Docker Targets:"
	@echo "  docker-build   - Build Docker image with OpenXC7 toolchain"
	@echo "  docker-shell   - Start interactive Docker shell"
	@echo "  docker-clean   - Remove Docker containers and images"
	@echo ""
	@echo "Other Targets:"
	@echo "  help           - Display this help"
	@echo ""
	@echo "Docker Usage:"
	@echo "  make docker-build              - Build the Docker image (first time)"
	@echo "  make all USE_DOCKER=1          - Build bitstream using Docker"
	@echo "  make program USE_DOCKER=1      - Program FPGA using Docker"
	@echo ""
	@echo "Typical Workflow:"
	@echo "  1. make sim-quick              - Verify design with simulation"
	@echo "  2. make all                    - Build bitstream (native or Docker)"
	@echo "  3. make program                - Program FPGA"
	@echo ""
	@echo "Simulation Requirements:"
	@echo "  - Icarus Verilog (iverilog) - Install: brew install icarus-verilog"
	@echo "  - Surfer (optional) - Install: cargo install surfer"
	@echo ""
	@echo "Native Build Requirements:"
	@echo "  - OpenXC7 toolchain (yosys, nextpnr-xilinx, prjxray tools)"
	@echo "  - openFPGALoader for programming"
	@echo "  - CHIPDB and PRJXRAY_DB_DIR environment variables must be set"

.PHONY: all synth pnr bitstream program program-flash clean help \
        sim sim-quick sim-full wave-quick wave-full clean-sim \
        docker-build docker-shell docker-clean
