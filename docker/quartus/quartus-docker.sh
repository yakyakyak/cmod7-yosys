#!/bin/bash
# Wrapper script for running Quartus Prime Lite in Docker with Colima
# Handles X11 forwarding and USB passthrough automatically

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Colima is running
check_colima() {
    if ! command -v colima &> /dev/null; then
        echo -e "${RED}Error: Colima is not installed${NC}"
        echo "Install with: brew install colima"
        exit 1
    fi

    if ! colima status &> /dev/null; then
        echo -e "${YELLOW}Warning: Colima is not running${NC}"
        echo ""
        echo "Starting Colima with required settings..."
        echo ""

        # Start Colima with x86_64 architecture and USB support
        colima start \
            --arch x86_64 \
            --vm-type=vz \
            --vz-rosetta \
            --cpu 4 \
            --memory 8 \
            --disk 60 \
            --mount-type=virtiofs

        echo -e "${GREEN}Colima started successfully${NC}"
        sleep 5
    fi
}

# Setup X11 forwarding (macOS)
setup_x11() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Check if XQuartz is installed
        if ! command -v xhost &> /dev/null; then
            echo -e "${YELLOW}Warning: XQuartz not found${NC}"
            echo "For GUI support, install XQuartz:"
            echo "  brew install --cask xquartz"
            echo ""
            echo "After installation, log out and back in, then run:"
            echo "  open -a XQuartz"
            echo ""
            return 1
        fi

        # Allow X11 connections from localhost
        xhost +localhost > /dev/null 2>&1 || true

        # Get the display
        export DISPLAY=:0

        echo -e "${GREEN}X11 forwarding configured${NC}"
    fi
}

# Print usage
usage() {
    echo "Quartus Prime Lite Docker Wrapper"
    echo "=================================="
    echo ""
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  shell              - Start interactive bash shell in container"
    echo "  build <project>    - Build Quartus project"
    echo "  program <sof>      - Program FPGA with .sof file"
    echo "  gui                - Launch Quartus GUI"
    echo "  quartus <args>     - Run quartus_sh with arguments"
    echo "  install            - Install Quartus inside container"
    echo "  stop               - Stop and remove container"
    echo "  logs               - Show container logs"
    echo ""
    echo "Examples:"
    echo "  $0 shell"
    echo "  $0 build de10_blinky"
    echo "  $0 program output_files/de10_blinky.sof"
    echo "  $0 gui"
    echo "  $0 quartus --version"
    echo ""
}

# Main script
main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi

    COMMAND=$1
    shift

    # Check Colima status
    check_colima

    cd "${SCRIPT_DIR}"

    case "${COMMAND}" in
        shell)
            echo -e "${GREEN}Starting Quartus Docker shell...${NC}"
            docker-compose run --rm quartus /bin/bash
            ;;

        build)
            if [ $# -eq 0 ]; then
                echo -e "${RED}Error: Project name required${NC}"
                echo "Usage: $0 build <project_name>"
                exit 1
            fi
            PROJECT=$1
            echo -e "${GREEN}Building Quartus project: ${PROJECT}${NC}"
            docker-compose run --rm quartus quartus_sh --flow compile "${PROJECT}"
            ;;

        program)
            if [ $# -eq 0 ]; then
                echo -e "${RED}Error: .sof file required${NC}"
                echo "Usage: $0 program <file.sof>"
                exit 1
            fi
            SOF_FILE=$1
            echo -e "${GREEN}Programming FPGA with: ${SOF_FILE}${NC}"
            docker-compose run --rm quartus quartus_pgm -m jtag -o "p;${SOF_FILE}"
            ;;

        gui)
            setup_x11
            echo -e "${GREEN}Launching Quartus GUI...${NC}"
            echo "Note: This requires XQuartz on macOS"
            docker-compose run --rm \
                -e DISPLAY="${DISPLAY}" \
                quartus quartus &
            ;;

        quartus)
            echo -e "${GREEN}Running quartus_sh $@${NC}"
            docker-compose run --rm quartus quartus_sh "$@"
            ;;

        install)
            echo -e "${GREEN}Installing Quartus Prime Lite...${NC}"
            echo ""
            echo "IMPORTANT: You must download the Quartus installer manually"
            echo ""
            echo "Steps:"
            echo "1. Download from: https://www.intel.com/content/www/us/en/software-kit/825278/"
            echo "2. Save to: ${PROJECT_ROOT}/docker/quartus/installers/"
            echo "3. Run this command again"
            echo ""

            # Check if installer exists
            INSTALLER_DIR="${SCRIPT_DIR}/installers"
            mkdir -p "${INSTALLER_DIR}"

            if ls "${INSTALLER_DIR}"/QuartusLiteSetup-*.run 1> /dev/null 2>&1; then
                echo "Found installer. Starting installation..."
                docker-compose run --rm quartus /home/quartus/installers/install-quartus.sh
            else
                echo "No installer found in ${INSTALLER_DIR}"
                exit 1
            fi
            ;;

        stop)
            echo -e "${YELLOW}Stopping Quartus container...${NC}"
            docker-compose down
            ;;

        logs)
            docker-compose logs -f
            ;;

        *)
            echo -e "${RED}Unknown command: ${COMMAND}${NC}"
            echo ""
            usage
            exit 1
            ;;
    esac
}

main "$@"
