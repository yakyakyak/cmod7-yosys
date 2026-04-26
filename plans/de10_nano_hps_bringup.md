# DE10-Nano ARM HPS Bring-Up Plan

**Board**: Terasic DE10-Nano  
**SoC**: Intel/Altera Cyclone V SE (5CSEBA6U23I7)  
**ARM**: Dual-core Cortex-A9 MPCore @ up to 800 MHz  
**RAM**: 1 GB DDR3 (on HPS side)

---

## 1. Architecture Overview

### Boot Chain

```
BootROM (silicon)
  └─ reads BSEL pins → locates partition type 0xA2 on SD card
       └─ loads SPL into 64 KB on-chip SRAM (OCRAM)
            └─ SPL: initializes PLLs, pinmux, DDR3 SDRAM
                 └─ loads U-Boot into DDR3
                      └─ U-Boot: (optionally) programs FPGA, loads kernel + DTB
                           └─ Linux kernel
```

### FPGA ↔ HPS Bridges

| Bridge | Direction | Width | HPS Base Address | Purpose |
|--------|-----------|-------|------------------|---------|
| Lightweight H2F | HPS → FPGA | 32-bit AXI | 0xFF200000 | Control registers, low latency |
| HPS-to-FPGA (H2F) | HPS → FPGA | 32/64/128-bit AXI | 0xC0000000 | High-bandwidth data |
| FPGA-to-HPS (F2H) | FPGA → HPS | 32/64/128-bit AXI | (FPGA master) | FPGA accesses HPS memory/peripherals |
| FPGA-to-SDRAM | FPGA → DDR3 | up to 256-bit | (FPGA master) | Direct DRAM access, bypasses ARM caches |

---

## 2. SD Card Partition Layout

The Cyclone V BootROM scans the MBR for a partition with type `0xA2`. Partitions must be created in this order with `fdisk`:

| Create Order | Partition | Type | Hex | Size | Filesystem | Contents |
|---|---|---|---|---|---|---|
| 1st | p3 | Altera custom | `0xA2` | 1 MB | raw (none) | `u-boot-with-spl.sfp` |
| 2nd | p1 | W95 FAT32 | `0x0B` | 254 MB | FAT32 | zImage, DTB, extlinux.conf, optional .rbf |
| 3rd | p2 | Linux | `0x83` | Remainder | ext4 | Root filesystem |

The `.sfp` file packs **four redundant 64 KB SPL copies** (total 256 KB) followed by full U-Boot at offset 0x40000. The BootROM validates each copy via CRC, falling back to the next if one is corrupt.

---

## 3. Board Switch Configuration

**Before powering on:**

### SW10 — MSEL (FPGA configuration mode)
Set all 6 switches **ON**. This selects FPP x16 mode, allowing the HPS to program the FPGA fabric via the FPGA Manager. Required for U-Boot FPGA load to work.

### BSEL — Boot source
The DE10-Nano has BSEL hardwired for SD/MMC 3.3V boot (BSEL value = 5). No user action needed — this is not user-configurable on the DE10-Nano.

### UART Console
Connect a Micro-USB cable to the UART port (the Mini-B connector labeled "UART"). This bridges to the HPS UART0 (`/dev/ttyUSB0` on Linux, `COM*` on Windows).
- **Baud rate**: 115200, 8N1, no flow control

---

## 4. Toolchain Setup

### Cross-Compiler (Bootlin, recommended)

```bash
# Download the armv7-eabihf glibc toolchain
wget https://toolchains.bootlin.com/downloads/releases/toolchains/armv7-eabihf/tarballs/armv7-eabihf--glibc--stable-2024.05-1.tar.bz2
tar -xf armv7-eabihf--glibc--stable-2024.05-1.tar.bz2

# Export for use in all build steps
export CROSS_COMPILE=$PWD/armv7-eabihf--glibc--stable-2024.05-1/bin/arm-linux-
export ARCH=arm
```

Alternatively, use your distro's `arm-linux-gnueabihf-` toolchain:
```bash
sudo apt install gcc-arm-linux-gnueabihf
export CROSS_COMPILE=arm-linux-gnueabihf-
```

### Other Required Tools

```bash
sudo apt install \
  git make bison flex bc libssl-dev \
  fdisk dosfstools e2fsprogs \
  u-boot-tools dtc \
  debootstrap systemd-container \
  picocom                            # for serial console
```

---

## 5. Building U-Boot (SPL + Bootloader)

The SPL (Secondary Program Loader) and U-Boot are built together from the same source tree. The output `u-boot-with-spl.sfp` is written directly to the raw 0xA2 partition.

```bash
git clone https://github.com/u-boot/u-boot.git
cd u-boot
git checkout v2024.10          # or latest stable tag

make socfpga_de10_nano_defconfig
make -j$(nproc)
```

**Output**: `u-boot-with-spl.sfp`

### Notes
- The DE10-Nano defconfig ships with correct QTS header files for the board's DDR3 and PLL config — no Quartus handoff step needed unless you modify the HPS in Platform Designer.
- If you customize the HPS (change bridge widths, add peripherals), regenerate the QTS headers using `cv_bsp_generator.py` from the Intel SoC EDS handoff directory and copy them to `board/terasic/de10-nano/qts/` before building.

---

## 6. Building the Linux Kernel

```bash
git clone https://github.com/altera-opensource/linux-socfpga.git
cd linux-socfpga
git checkout socfpga-6.1.x         # LTS branch; or check for latest

make socfpga_defconfig
make menuconfig
# Recommended changes:
#   → File systems → Overlay Filesystem Support: enable
#   → File systems → Pseudo filesystems → Userspace-driven configuration filesystem: enable
#   → General → Local version: clear (cleaner module paths)

make -j$(nproc) zImage
make -j$(nproc) dtbs
```

**Output files**:
- `arch/arm/boot/zImage`
- `arch/arm/boot/dts/socfpga_cyclone5_de0_nano_soc.dtb` (compatible with DE10-Nano for basic bring-up)

### Device Tree Note
A DE10-Nano-specific DTS (`socfpga_cyclone5_de10_nano.dts`) exists in the U-Boot source tree but may not be present in all kernel versions. The DE0-Nano-SoC device tree is hardware-compatible for initial bring-up. Use the U-Boot-sourced DTB if you need a DE10-Nano-specific one:

```bash
# From within the u-boot tree (after building)
ls arch/arm/dts/socfpga_cyclone5_de10_nano.dtb
```

---

## 7. Building the Root Filesystem (Debian Bookworm)

```bash
mkdir rootfs

# Stage 1: Download skeleton (run as root or with sudo)
sudo debootstrap --arch=armhf --foreign bookworm rootfs

# Stage 2: Complete inside the chroot
sudo systemd-nspawn -D rootfs /debootstrap/debootstrap --second-stage

# Stage 3: Configure the system
sudo systemd-nspawn -D rootfs bash <<'EOF'
  # Enable serial console login
  systemctl enable serial-getty@ttyS0.service

  # Set root password
  echo "root:root" | chpasswd

  # Hostname
  echo "de10-nano" > /etc/hostname

  # Networking (DHCP on eth0)
  cat > /etc/network/interfaces.d/eth0 <<'NETEOF'
auto eth0
iface eth0 inet dhcp
NETEOF

  # fstab
  cat > /etc/fstab <<'FSEOF'
/dev/mmcblk0p2  /     ext4  errors=remount-ro  0  1
/dev/mmcblk0p1  /boot vfat  defaults           0  2
tmpfs           /tmp  tmpfs defaults            0  0
FSEOF

  # Optional: SSH and dev tools
  apt-get update
  apt-get install -y openssh-server build-essential

  exit
EOF

# Package into a tarball
sudo tar -cjpf rootfs.tar.bz2 -C rootfs .
```

---

## 8. Preparing the SD Card

### Step 1: Create and Partition a Disk Image

```bash
# Create a 4 GB image (adjust to fit your rootfs)
fallocate -l 4G sdcard.img

# Attach as loopback device
LOOP=$(sudo losetup --show -f sdcard.img)
echo "Loop device: $LOOP"

# Partition (create in order: p3 → p1 → p2)
sudo fdisk "$LOOP" <<'EOF'
n
p
3


+1M
t
a2
n
p
1


+254M
t
1
b
n
p
2


w
EOF

# Re-read partition table
sudo partprobe "$LOOP"
```

### Step 2: Format and Populate

```bash
# Partition 1: FAT32
sudo mkfs.vfat "${LOOP}p1"

# Partition 2: ext4
sudo mkfs.ext4 "${LOOP}p2"

# Partition 3: write raw bootloader (NO filesystem)
sudo dd if=u-boot/u-boot-with-spl.sfp of="${LOOP}p3" bs=64k seek=0 oflag=sync

# Populate FAT partition
sudo mkdir -p /mnt/fat
sudo mount "${LOOP}p1" /mnt/fat

sudo cp linux-socfpga/arch/arm/boot/zImage                           /mnt/fat/
sudo cp linux-socfpga/arch/arm/boot/dts/socfpga_cyclone5_de0_nano_soc.dtb /mnt/fat/

sudo mkdir -p /mnt/fat/extlinux
sudo tee /mnt/fat/extlinux/extlinux.conf <<'EOF'
LABEL Linux Default
    KERNEL ../zImage
    FDT ../socfpga_cyclone5_de0_nano_soc.dtb
    APPEND root=/dev/mmcblk0p2 rw rootwait earlyprintk console=ttyS0,115200n8
EOF

# Optional: copy FPGA bitstream for U-Boot to load
# sudo cp soc_system.rbf /mnt/fat/

sudo umount /mnt/fat

# Populate ext4 partition
sudo mkdir -p /mnt/ext4
sudo mount "${LOOP}p2" /mnt/ext4
sudo tar -xjpf rootfs.tar.bz2 -C /mnt/ext4
sudo umount /mnt/ext4

# Detach loopback
sudo losetup -d "$LOOP"
```

### Step 3: Write to Physical SD Card

```bash
# Find your SD card device (check dmesg or lsblk after inserting)
lsblk

# Write (replace sdX with your device — DOUBLE CHECK before running)
sudo dd if=sdcard.img of=/dev/sdX bs=64K status=progress conv=fsync
```

---

## 9. First Boot

1. Insert the SD card into the DE10-Nano micro-SD slot.
2. Set SW10 (MSEL) all ON.
3. Connect the UART Micro-USB cable.
4. Open serial console: `picocom -b 115200 /dev/ttyUSB0`
5. Connect power (5V DC barrel jack or Micro-USB power).

**Expected boot sequence output:**

```
U-Boot SPL 2024.10 (...)
Trying to boot from MMC1
...
U-Boot 2024.10 (...)
DRAM:  1 GiB
...
Hit any key to stop autoboot: 3
```

If autoboot proceeds, you should see the kernel decompressing and eventually a login prompt on `ttyS0`.

**Login**: `root` / `root` (as configured in the rootfs step)

### Troubleshooting

| Symptom | Likely Cause |
|---------|-------------|
| No output at all | Wrong UART cable / baud rate, or partition 3 not type 0xA2 |
| SPL boots but DDR init fails | DDR3 not initialized — check QTS header files in U-Boot |
| U-Boot hangs at "Trying to boot from MMC1" | FAT partition not found / extlinux.conf missing |
| Kernel panics on rootfs mount | Partition 2 not ext4 or wrong `root=` in APPEND line |

---

## 10. FPGA-HPS Bridge Setup (Optional, for FPGA integration)

### Option A: Load FPGA from U-Boot

Convert your Quartus `.sof` to a raw binary `.rbf` (Passive Parallel x16):

```
Quartus → File → Convert Programming Files → Passive Serial (.rbf)
```

Place `soc_system.rbf` on the FAT partition and create a U-Boot script:

```bash
# u-boot.txt
fatload mmc 0:1 $fpgadata soc_system.rbf
fpga load 0 $fpgadata $filesize
run bridge_enable_handoff
```

```bash
mkimage -A arm -O linux -T script -C none -a 0 -e 0 \
  -n "FPGA config" -d u-boot.txt u-boot.scr
# Copy u-boot.scr to FAT partition alongside the .rbf
```

### Option B: Load FPGA from Linux (Device Tree Overlay)

```bash
# On the DE10-Nano, after booting:
mount -t configfs configfs /config

# Copy bitstream and overlay to /lib/firmware
cp soc_system.rbf /lib/firmware/
cp soc_system.dtbo /lib/firmware/

# Apply overlay (triggers FPGA Manager to program the fabric)
mkdir /config/device-tree/overlays/fpga0
echo -n "soc_system.dtbo" > /config/device-tree/overlays/fpga0/path
cat /config/device-tree/overlays/fpga0/status     # should print "applied"

# Verify bridges are enabled
cat /sys/class/fpga_bridge/*/state
```

### User-Space Register Access (via /dev/mem)

```c
#include <sys/mman.h>
#include <fcntl.h>

#define LW_BRIDGE_BASE  0xFF200000
#define LW_BRIDGE_SPAN  0x00200000

int fd = open("/dev/mem", O_RDWR | O_SYNC);
void *bridge = mmap(NULL, LW_BRIDGE_SPAN,
    PROT_READ | PROT_WRITE, MAP_SHARED, fd, LW_BRIDGE_BASE);

// Access FPGA peripheral at LW H2F offset
volatile uint32_t *my_reg = (uint32_t *)((char *)bridge + MY_PERIPH_OFFSET);
*my_reg = 0xDEADBEEF;
```

---

## References

- **James Gibbard's 2025 guide** (most current, Debian Bookworm + U-Boot v2024.10 + Linux 6.1.x):  
  https://www.gibbard.me/linux_debian_de10_2025/

- **zangman/de10-nano** (modular step-by-step, Arch or Debian rootfs):  
  https://github.com/zangman/de10-nano

- **RocketBoards.org** (Intel's official Cyclone V bootloader and GSRD docs):  
  https://www.rocketboards.org/foswiki/Documentation/BuildingBootloaderCycloneVAndArria10

- **bitlog.it** (good explanations of boot flow + FPGA IP integration):  
  https://bitlog.it/20170820_building_embedded_linux_for_the_terasic_de10-nano.html

- **Terasic DE10-Nano Resources** (user manual, pre-built SD card image):  
  https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1046&PartNo=4

- **Intel DE10-Nano Get Started Guide**:  
  https://www.intel.com/content/www/us/en/developer/articles/guide/terasic-de10-nano-get-started-guide.html

- **meta-de10-nano** (Intel's official Yocto layer, if you prefer Yocto over Debian):  
  https://github.com/intel/meta-de10-nano
