#!/bin/bash
# Simulation script for LED Blinky using Icarus Verilog

set -e

# Default testbench
TESTBENCH="${1:-quick}"

# Directories
SIM_DIR="sim"
SRC_DIR="src"
BUILD_DIR="build"

# Create build directory if it doesn't exist
mkdir -p ${BUILD_DIR}

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "==================================================="
echo "LED Blinky Simulation"
echo "==================================================="

# Select testbench
case ${TESTBENCH} in
    quick|q)
        TB_FILE="${SIM_DIR}/tb_top_quick.v"
        TB_MODULE="tb_top_quick"
        VCD_FILE="${BUILD_DIR}/tb_top_quick.vcd"
        echo "Running quick testbench (~65K cycles, <1 second)"
        ;;
    full|f)
        TB_FILE="${SIM_DIR}/tb_top.v"
        TB_MODULE="tb_top"
        VCD_FILE="${BUILD_DIR}/tb_top.vcd"
        echo "Running full testbench (~8M cycles, may take several minutes)"
        ;;
    *)
        echo -e "${RED}Error: Unknown testbench '${TESTBENCH}'${NC}"
        echo "Usage: $0 [quick|full]"
        echo "  quick (default) - Fast simulation (~65K cycles)"
        echo "  full            - Complete simulation (~8M cycles)"
        exit 1
        ;;
esac

echo "Testbench: ${TB_FILE}"
echo "==================================================="
echo ""

# Check if iverilog is installed
if ! command -v iverilog &> /dev/null; then
    echo -e "${RED}Error: iverilog not found${NC}"
    echo "Please install Icarus Verilog:"
    echo "  macOS: brew install icarus-verilog"
    echo "  Ubuntu/Debian: sudo apt-get install iverilog"
    exit 1
fi

# Step 1: Compile
echo -e "${YELLOW}[1/3]${NC} Compiling Verilog sources..."
iverilog -o ${BUILD_DIR}/${TB_MODULE}.vvp \
         -g2012 \
         -I${SRC_DIR} \
         ${SRC_DIR}/top.v \
         ${TB_FILE}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Compilation successful"
else
    echo -e "${RED}✗${NC} Compilation failed"
    exit 1
fi
echo ""

# Step 2: Run simulation
echo -e "${YELLOW}[2/3]${NC} Running simulation..."
vvp ${BUILD_DIR}/${TB_MODULE}.vvp

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Simulation completed"
else
    echo -e "${RED}✗${NC} Simulation failed"
    exit 1
fi
echo ""

# Step 3: View waveform (optional)
echo -e "${YELLOW}[3/3]${NC} Waveform generation complete"
echo ""
echo "VCD file created: ${VCD_FILE}"
echo ""

# Check if surfer is installed
if command -v surfer &> /dev/null; then
    echo "To view waveform, run:"
    echo "  surfer ${VCD_FILE}"
    echo ""
    read -p "Open waveform viewer now? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        surfer ${VCD_FILE} &
    fi
else
    echo "To view waveforms, install Surfer:"
    echo "  macOS/Linux: cargo install surfer"
    echo "  Or download from: https://github.com/surfer-project/surfer"
    echo ""
    echo "Then run: surfer ${VCD_FILE}"
fi

echo ""
echo "==================================================="
echo -e "${GREEN}Simulation complete!${NC}"
echo "==================================================="
