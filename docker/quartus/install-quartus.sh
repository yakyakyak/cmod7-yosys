#!/bin/bash
# Script to install Quartus Prime Lite inside Docker container
# Run this script INSIDE the container after downloading the installer

set -e

QUARTUS_VERSION="23.1std.1.993"
INSTALLER_DIR="/home/quartus/installers"
INSTALL_DIR="/home/quartus/intelFPGA_lite/23.1std"

echo "=============================================="
echo "Quartus Prime Lite Installation Script"
echo "=============================================="
echo ""
echo "This script will install Quartus Prime Lite"
echo "Version: ${QUARTUS_VERSION}"
echo "Install directory: ${INSTALL_DIR}"
echo ""

# Check if installer exists
if [ ! -f "${INSTALLER_DIR}/QuartusLiteSetup-${QUARTUS_VERSION}-linux.run" ]; then
    echo "ERROR: Quartus installer not found!"
    echo ""
    echo "Please download the installer manually:"
    echo "1. Visit: https://www.intel.com/content/www/us/en/software-kit/825278/"
    echo "2. Download: QuartusLiteSetup-${QUARTUS_VERSION}-linux.run"
    echo "3. Place it in: ${INSTALLER_DIR}/"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "Found installer: QuartusLiteSetup-${QUARTUS_VERSION}-linux.run"
echo ""

# Make installer executable
chmod +x "${INSTALLER_DIR}/QuartusLiteSetup-${QUARTUS_VERSION}-linux.run"

# Run installer in unattended mode
echo "Starting installation (this may take 10-15 minutes)..."
echo ""

"${INSTALLER_DIR}/QuartusLiteSetup-${QUARTUS_VERSION}-linux.run" \
    --mode unattended \
    --installdir "${INSTALL_DIR}" \
    --accept_eula 1 \
    --disable-components quartus_help,modelsim_ase

echo ""
echo "=============================================="
echo "Installation complete!"
echo "=============================================="
echo ""
echo "Quartus is installed at: ${INSTALL_DIR}"
echo ""
echo "To verify installation:"
echo "  source /home/quartus/.bashrc"
echo "  quartus_sh --version"
echo ""
echo "Device support installed:"
echo "  - Quartus Prime Lite Edition"
echo "  - MAX 10 device family"
echo "  - Cyclone V device family"
echo ""
