# Quartus Prime Lite in Docker with Colima

This directory contains a complete Docker setup for running Intel Quartus Prime Lite with Colima on macOS (especially Apple Silicon).

## Why Docker + Colima?

- ✅ **Consistent environment** - Same toolchain across different machines
- ✅ **No native install mess** - Keep your system clean
- ✅ **Works with Apple Silicon** - Via Rosetta 2 emulation
- ✅ **Already using Colima** - Reuse your OpenXC7 setup
- ✅ **USB passthrough** - Can program FPGAs directly
- ⚠️ **Large container** - ~10-15GB for full Quartus install

## Quick Start

### Prerequisites

```bash
# 1. Install Colima (if not already installed)
brew install colima docker docker-compose

# 2. Install XQuartz for GUI support (optional)
brew install --cask xquartz
# Log out and back in after installing XQuartz
# Then start it: open -a XQuartz

# 3. Make wrapper script executable
chmod +x quartus-docker.sh
```

### Installation Steps

#### Step 1: Download Quartus Installer

You must download the Quartus Prime Lite installer manually (it's too large to automate):

1. Visit: https://www.intel.com/content/www/us/en/software-kit/825278/
2. Download: **QuartusLiteSetup-23.1std.1.993-linux.run** (~5-6GB)
3. Save to: `docker/quartus/installers/`

```bash
# Create installers directory
mkdir -p installers

# After downloading, verify the file
ls -lh installers/QuartusLiteSetup-*.run
```

#### Step 2: Build Docker Image

```bash
# Build the base image
docker-compose build
```

#### Step 3: Install Quartus Inside Container

```bash
# This mounts the installer and runs installation
./quartus-docker.sh install

# Or manually:
docker-compose run --rm quartus bash
# Inside container:
chmod +x /home/quartus/installers/install-quartus.sh
/home/quartus/installers/install-quartus.sh
```

Installation takes 10-15 minutes and installs:
- Quartus Prime Lite Edition
- MAX 10 device support (DE10-Lite)
- Cyclone V device support (DE10-Nano/Standard)

#### Step 4: Verify Installation

```bash
# Check Quartus version
./quartus-docker.sh quartus --version

# Expected output:
# Version 23.1std.1 Build 993 ...
```

## Usage

### Command-Line Workflows

#### Build a Project

```bash
# Build complete project
./quartus-docker.sh build de10_blinky

# Or run quartus_sh directly
./quartus-docker.sh quartus --flow compile de10_blinky
```

#### Individual Build Steps

```bash
# Analysis & elaboration
./quartus-docker.sh quartus --analysis_and_elaboration de10_blinky

# Synthesis
docker-compose run --rm quartus quartus_map de10_blinky

# Place & route
docker-compose run --rm quartus quartus_fit de10_blinky

# Timing analysis
docker-compose run --rm quartus quartus_sta de10_blinky

# Generate bitstream
docker-compose run --rm quartus quartus_asm de10_blinky
```

#### Programming the FPGA

```bash
# Program using Quartus Programmer
./quartus-docker.sh program output_files/de10_blinky.sof

# Or use openFPGALoader (install on host first)
brew install openfpgaloader
openFPGALoader -b de10lite output_files/de10_blinky.sof
```

### GUI Workflows

#### Launch Quartus GUI

```bash
# Start XQuartz first (if not already running)
open -a XQuartz

# Enable X11 forwarding
xhost +localhost

# Launch Quartus GUI
./quartus-docker.sh gui

# Or launch specific tools:
docker-compose run --rm quartus quartus &           # Main GUI
docker-compose run --rm quartus qsys-edit &         # Platform Designer
docker-compose run --rm quartus quartus_pgmw &      # Programmer GUI
```

**Note**: GUI performance may be slower through X11 forwarding. For best performance, use command-line workflow.

### Interactive Shell

```bash
# Start bash shell inside container
./quartus-docker.sh shell

# Inside container, you can run any Quartus commands:
quartus_sh --version
quartus_map --help
cd /workspace
ls
```

## Colima Configuration

### Optimal Settings for Quartus

```bash
# Stop Colima if running
colima stop

# Start with recommended settings
colima start \
    --arch x86_64 \
    --vm-type=vz \
    --vz-rosetta \
    --cpu 4 \
    --memory 8 \
    --disk 60 \
    --mount-type=virtiofs
```

**Settings Explained**:
- `--arch x86_64` - Required (Quartus is x86_64 only)
- `--vz-rosetta` - Use Rosetta 2 for better performance on Apple Silicon
- `--cpu 4` - Allocate 4 CPU cores (increase if available)
- `--memory 8` - 8GB RAM minimum (16GB recommended for large designs)
- `--disk 60` - 60GB disk space (Quartus install ~15GB + projects)
- `--mount-type=virtiofs` - Faster file I/O

### USB Passthrough for Programming

Colima supports USB passthrough, but it requires some setup:

```bash
# Option 1: Use privileged mode (in docker-compose.yml - already configured)
privileged: true
devices:
  - /dev/bus/usb:/dev/bus/usb

# Option 2: Use openFPGALoader on host (easier)
brew install openfpgaloader
openFPGALoader -b de10lite build/output_files/design.sof
```

**Note**: USB passthrough in Colima is experimental. If it doesn't work, use openFPGALoader on the host macOS system (works reliably).

## Directory Structure

```
docker/quartus/
├── Dockerfile                  # Quartus container definition
├── docker-compose.yml          # Docker Compose configuration
├── quartus-docker.sh           # Convenient wrapper script
├── install-quartus.sh          # Quartus installation script
├── installers/                 # Place Quartus installer here
│   └── QuartusLiteSetup-*.run  # Downloaded manually
└── README.md                   # This file

Volumes (persistent):
├── quartus-install/            # Quartus installation (~15GB)
└── quartus-installers/         # Installer files
```

## Troubleshooting

### Issue: "Colima is not running"

```bash
# Start Colima with proper settings
colima start --arch x86_64 --vm-type=vz --vz-rosetta --cpu 4 --memory 8
```

### Issue: GUI doesn't start

```bash
# 1. Ensure XQuartz is installed
brew install --cask xquartz

# 2. Log out and log back in (required after first XQuartz install)

# 3. Start XQuartz
open -a XQuartz

# 4. Allow connections
xhost +localhost

# 5. Set DISPLAY environment variable
export DISPLAY=:0

# 6. Try launching Quartus GUI again
./quartus-docker.sh gui
```

### Issue: "Permission denied" when programming

```bash
# Option 1: Use privileged mode (already enabled in docker-compose.yml)

# Option 2: Add user to dialout group (Linux-style, may not work on macOS)
docker-compose run --rm quartus bash
sudo usermod -a -G dialout quartus

# Option 3: Use openFPGALoader on host instead
brew install openfpgaloader
openFPGALoader -b de10lite output_files/design.sof
```

### Issue: Container is slow

```bash
# 1. Ensure Rosetta 2 is enabled
colima status | grep rosetta

# 2. Allocate more resources
colima stop
colima start --arch x86_64 --vz-rosetta --cpu 6 --memory 16

# 3. Use command-line instead of GUI
# GUI through X11 is inherently slower
```

### Issue: "No space left on device"

```bash
# Increase Colima disk size
colima stop
colima start --disk 100

# Or clean up old images
docker system prune -a
```

### Issue: USB-Blaster not detected

```bash
# Check USB devices in container
docker-compose run --rm quartus lsusb

# If USB-Blaster (Altera USB-Blaster) not shown:
# Use openFPGALoader on macOS host instead
brew install openfpgaloader
openFPGALoader -c usb-blaster -b de10lite design.sof
```

## Performance Comparison

| Metric | Native Linux | Docker (x86_64 VM) | Docker + Rosetta |
|--------|--------------|-------------------|------------------|
| **Synthesis** | Baseline | ~1.5x slower | ~1.2x slower |
| **Place & Route** | Baseline | ~1.5x slower | ~1.2x slower |
| **GUI Responsiveness** | Excellent | Slow | Slow |
| **Overall** | Fastest | Acceptable | Good |

**Recommendation**: Use Docker for convenience, but if you're doing heavy FPGA work, consider a native Linux installation or dual-boot.

## Alternative: Pre-built Docker Images

If you don't want to build your own, there are community Docker images available:

```bash
# Example: Use unofficial pre-built image
docker pull raetro/quartus-lite:23.1

# Run with your project
docker run --rm -it \
    -v $(pwd):/workspace \
    -w /workspace \
    raetro/quartus-lite:23.1 \
    quartus_sh --version
```

**Warning**: Unofficial images may be outdated or contain modifications. Use at your own risk.

## Tips and Best Practices

1. **Use volumes for persistence** - Don't install Quartus every time
2. **Command-line over GUI** - Much faster, better for automation
3. **Use Makefiles** - Automate build process (see main DE10 workflow docs)
4. **openFPGALoader on host** - Easier than USB passthrough
5. **Monitor resources** - `docker stats` to check CPU/memory usage
6. **Keep Colima updated** - `brew upgrade colima`

## Resources

- [Intel Quartus Download](https://www.intel.com/content/www/us/en/software-kit/825278/)
- [Colima Documentation](https://github.com/abiosoft/colima)
- [openFPGALoader](https://github.com/trabucayre/openFPGALoader)
- [DE10-Lite User Manual](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/Boards/DE10-Lite/DE10_Lite_User_Manual.pdf)

## License

This Docker setup is provided as-is for educational purposes. Intel Quartus Prime Lite is proprietary software - review Intel's license terms before use.
