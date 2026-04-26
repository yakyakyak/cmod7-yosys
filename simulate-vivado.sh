#!/bin/bash
# Simulation script for LED Blinky using Vivado xsim

set -e

VIVADO_SETTINGS="${HOME}/vivado/2025.2.1/Vivado/settings64.sh"

# Source Vivado environment
if [ ! -f "${VIVADO_SETTINGS}" ]; then
    echo "Error: Vivado settings not found at ${VIVADO_SETTINGS}"
    exit 1
fi
source "${VIVADO_SETTINGS}"

# Default testbench
TESTBENCH="${1:-quick}"

# Directories
SIM_DIR="sim"
SRC_DIR="src"
PLATFORM_DIR="platforms/cmod_a7"
BUILD_DIR="build"

# Create build directory if it doesn't exist
mkdir -p ${BUILD_DIR}

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "==================================================="
echo "LED Blinky Simulation (Vivado xsim)"
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
    uart|u)
        TB_FILE="${SIM_DIR}/tb_uart_reg.v"
        TB_MODULE="tb_uart_reg"
        VCD_FILE="${BUILD_DIR}/tb_uart_reg.vcd"
        echo "Running UART register testbench"
        ;;
    pwm-quick|pq)
        TB_FILE="${SIM_DIR}/tb_top_pwm_quick.v"
        TB_MODULE="tb_top_pwm_quick"
        VCD_FILE="${BUILD_DIR}/tb_top_pwm_quick.vcd"
        echo "Running PWM quick testbench (~65K cycles, <1 second)"
        ;;
    pwm|p)
        TB_FILE="${SIM_DIR}/tb_top_pwm.v"
        TB_MODULE="tb_top_pwm"
        VCD_FILE="${BUILD_DIR}/tb_top_pwm.vcd"
        echo "Running PWM full testbench (~8M cycles, may take several minutes)"
        ;;
    *)
        echo -e "${RED}Error: Unknown testbench '${TESTBENCH}'${NC}"
        echo "Usage: $0 [quick|full|uart|pwm-quick|pwm]"
        echo "  quick (default) - Fast simulation (~65K cycles)"
        echo "  full            - Complete simulation (~8M cycles)"
        echo "  uart            - UART register interface test"
        echo "  pwm-quick       - PWM fast simulation (~65K cycles)"
        echo "  pwm             - PWM complete simulation (~8M cycles)"
        exit 1
        ;;
esac

echo "Testbench: ${TB_FILE}"
echo "==================================================="
echo ""

# Step 1: Compile
echo -e "${YELLOW}[1/3]${NC} Compiling Verilog sources (xvlog)..."
xvlog -sv \
      -i ${SRC_DIR} \
      -i ${PLATFORM_DIR} \
      -i library/uart \
      library/uart/uart_rx.v \
      library/uart/uart_tx.v \
      ${SRC_DIR}/pwm_generator.v \
      ${SRC_DIR}/reg_ctrl.v \
      ${PLATFORM_DIR}/top.v \
      ${TB_FILE} 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Compilation successful"
else
    echo -e "${RED}✗${NC} Compilation failed"
    exit 1
fi
echo ""

# Step 2: Elaborate
echo -e "${YELLOW}[2/3]${NC} Elaborating design (xelab)..."
xelab -debug typical -timescale 1ns/1ps ${TB_MODULE} -s ${TB_MODULE} 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Elaboration successful"
else
    echo -e "${RED}✗${NC} Elaboration failed"
    exit 1
fi
echo ""

# Step 3: Simulate
echo -e "${YELLOW}[3/3]${NC} Running simulation (xsim)..."
xsim ${TB_MODULE} --runall 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Simulation completed"
else
    echo -e "${RED}✗${NC} Simulation failed"
    exit 1
fi
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
    echo ""
    echo "Then run: surfer ${VCD_FILE}"
fi

echo ""
echo "==================================================="
echo -e "${GREEN}Simulation complete!${NC}"
echo "==================================================="
