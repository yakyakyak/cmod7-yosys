# Dockerfile for Intel Quartus Prime Lite
# This creates a container with Quartus Prime Lite pre-installed
# Supports both headless (command-line) and GUI workflows

FROM ubuntu:22.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Set Quartus version
ARG QUARTUS_VERSION=23.1std.1.993
ARG QUARTUS_UPDATE=0.993

# Install dependencies
RUN apt-get update && apt-get install -y \
    # Quartus dependencies
    libc6:i386 \
    libncurses5:i386 \
    libstdc++6:i386 \
    lib32z1 \
    libqt5xml5 \
    libqt5network5 \
    libqt5widgets5 \
    libqt5gui5 \
    libqt5core5a \
    libglib2.0-0 \
    libfreetype6 \
    libsm6 \
    libxrender1 \
    libfontconfig1 \
    libxext6 \
    libxtst6 \
    libxi6 \
    libxft2 \
    # Build tools
    wget \
    curl \
    unzip \
    make \
    gcc \
    g++ \
    # USB programming support
    usbutils \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    # X11 for GUI
    xauth \
    x11-apps \
    # Utilities
    vim \
    git \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Create quartus user (non-root)
RUN useradd -m -s /bin/bash quartus && \
    echo "quartus ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER quartus
WORKDIR /home/quartus

# NOTE: Quartus installer is too large to include in Dockerfile
# Users must download manually and mount during build
# Download from: https://www.intel.com/content/www/us/en/software-kit/825278/intel-quartus-prime-lite-edition-design-software-version-23-1-1-for-linux.html

# Set environment variables for Quartus
ENV QUARTUS_ROOTDIR=/home/quartus/intelFPGA_lite/23.1std/quartus
ENV PATH="${QUARTUS_ROOTDIR}/bin:${PATH}"
ENV QSYS_ROOTDIR="${QUARTUS_ROOTDIR}/sopc_builder/bin"

# Create workspace directory
RUN mkdir -p /home/quartus/workspace

WORKDIR /home/quartus/workspace

# Default command
CMD ["/bin/bash"]
