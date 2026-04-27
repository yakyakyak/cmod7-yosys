#!/bin/bash
# Build bitstream for LED Blinky using Vivado (synthesis + implementation)

set -e

VIVADO_SETTINGS="${HOME}/vivado/2025.2.1/Vivado/settings64.sh"

# Source Vivado environment
if [ ! -f "${VIVADO_SETTINGS}" ]; then
    echo "Error: Vivado settings not found at ${VIVADO_SETTINGS}"
    exit 1
fi
source "${VIVADO_SETTINGS}"

# Configuration
PROJECT="blinky"
PART="xc7a35tcpg236-1"
TOP_MODULE="top"
BUILD_DIR="build/vivado"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "==================================================="
echo "LED Blinky Bitstream Build (Vivado)"
echo "Part: ${PART}"
echo "==================================================="
echo ""

# Create build directory
mkdir -p ${BUILD_DIR}

# Write the Vivado TCL build script
TCL_SCRIPT="${BUILD_DIR}/run.tcl"
cat > "${TCL_SCRIPT}" << 'EOF'
# Vivado non-project batch build script

# Read RTL sources
read_verilog library/uart/uart_rx.v
read_verilog library/uart/uart_tx.v
read_verilog src/pwm_generator.v
read_verilog src/gen/cmod7_reg_store.sv
read_verilog src/reg_ctrl.v
read_verilog platforms/cmod_a7/top.v

# Read constraints
read_xdc platforms/cmod_a7/cmod_a7.xdc

# Synthesis
synth_design -top top -part xc7a35tcpg236-1 -include_dirs {src platforms/cmod_a7 library/uart}

# Implementation
opt_design
place_design
route_design

# Reports
report_timing_summary -file build/vivado/timing_summary.rpt
report_utilization    -file build/vivado/utilization.rpt

# Checkpoint and bitstream
write_checkpoint -force build/vivado/post_route.dcp
write_bitstream  -force build/vivado/blinky.bit
EOF

# Step 1: Synthesis + Implementation + Bitstream
echo -e "${YELLOW}[1/1]${NC} Running Vivado synthesis, implementation, and bitstream generation..."
echo "      Log: ${BUILD_DIR}/vivado.log"
echo ""

vivado -mode batch \
       -source "${TCL_SCRIPT}" \
       -log "${BUILD_DIR}/vivado.log" \
       -journal "${BUILD_DIR}/vivado.jou"

EXIT_CODE=$?

echo ""

if [ ${EXIT_CODE} -eq 0 ] && [ -f "${BUILD_DIR}/${PROJECT}.bit" ]; then
    echo -e "${GREEN}✓${NC} Build successful"
    echo ""
    echo "Outputs:"
    echo "  Bitstream:         ${BUILD_DIR}/${PROJECT}.bit"
    echo "  Timing report:     ${BUILD_DIR}/timing_summary.rpt"
    echo "  Utilization:       ${BUILD_DIR}/utilization.rpt"
    echo "  Design checkpoint: ${BUILD_DIR}/post_route.dcp"
    echo ""
    echo "To program the FPGA (SRAM):"
    echo "  openFPGALoader -b cmoda7_35t ${BUILD_DIR}/${PROJECT}.bit"
    echo ""
    echo "To program the FPGA (Flash):"
    echo "  openFPGALoader -b cmoda7_35t -f ${BUILD_DIR}/${PROJECT}.bit"
else
    echo -e "${RED}✗${NC} Build failed (exit code: ${EXIT_CODE})"
    echo ""
    echo "Check the log for details:"
    echo "  ${BUILD_DIR}/vivado.log"
    exit 1
fi

echo "==================================================="
echo -e "${GREEN}Build complete!${NC}"
echo "==================================================="
