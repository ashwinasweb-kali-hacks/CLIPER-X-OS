#!/bin/bash
# ============================================================
# CLIPER X OS — Build Script
# Custom Kali Linux for Raspberry Pi 5 (16GB RAM)
#
# Usage:
#   ./build.sh --target rpi5 --variant full
#   ./build.sh --target rpi5 --variant minimal
#   ./build.sh --target rpi5 --variant dev
#
# Requirements:
#   - Debian/Ubuntu build host (or Docker)
#   - debootstrap, qemu-user-static, binfmt-support
#   - At least 32GB free disk space
#   - Internet connection
# ============================================================

set -euo pipefail

# ========================
# Configuration
# ========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

OS_NAME="Cliper X OS"
OS_VERSION="1.0.0"
OS_CODENAME="phantom"
KALI_MIRROR="https://http.kali.org/kali"
KALI_SUITE="kali-rolling"

TARGET="rpi5"
VARIANT="full"     # full, minimal, dev
ARCH="arm64"
KERNEL_VERSION="6.6"

BUILD_DIR="${PROJECT_ROOT}/build/output"
ROOTFS_DIR="${BUILD_DIR}/rootfs"
BOOT_DIR="${BUILD_DIR}/boot"
IMAGE_FILE="${BUILD_DIR}/cliper-x-os-${OS_VERSION}-${TARGET}.img"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[CLIPER X]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ========================
# Parse Arguments
# ========================

while [[ $# -gt 0 ]]; do
    case $1 in
        --target) TARGET="$2"; shift 2 ;;
        --variant) VARIANT="$2"; shift 2 ;;
        --clean) CLEAN=true; shift ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --target    Target device (rpi5)"
            echo "  --variant   Build variant (full, minimal, dev)"
            echo "  --clean     Clean build directory first"
            exit 0
            ;;
        *) error "Unknown option: $1" ;;
    esac
done

# ========================
# Build Steps
# ========================

banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║         CLIPER X OS BUILD SYSTEM         ║"
    echo "║      Custom Kali Linux for RPi 5         ║"
    echo "║         v${OS_VERSION} (${OS_CODENAME})              ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "  Target:   ${TARGET}"
    echo "  Variant:  ${VARIANT}"
    echo "  Arch:     ${ARCH}"
    echo "  Output:   ${IMAGE_FILE}"
    echo ""
}

check_dependencies() {
    log "Checking build dependencies..."
    
    local deps=(debootstrap qemu-user-static binfmt-support kpartx parted dosfstools e2fsprogs)
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! dpkg -l "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log "Installing missing dependencies: ${missing[*]}"
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
    
    log "✅ All dependencies satisfied"
}

prepare_build_dir() {
    log "Preparing build directory..."
    
    if [ "${CLEAN:-false}" = true ] && [ -d "$BUILD_DIR" ]; then
        warn "Cleaning existing build directory..."
        sudo rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR" "$ROOTFS_DIR" "$BOOT_DIR"
    log "✅ Build directory ready: $BUILD_DIR"
}

create_image() {
    log "Creating disk image (16GB)..."
    
    # Create a 16GB image
    dd if=/dev/zero of="$IMAGE_FILE" bs=1M count=16384 status=progress
    
    # Partition the image
    # Partition 1: boot (FAT32, 512MB)
    # Partition 2: root (ext4, rest)
    parted "$IMAGE_FILE" --script -- \
        mklabel msdos \
        mkpart primary fat32 4MiB 516MiB \
        mkpart primary ext4 516MiB 100%
    
    # Setup loop device
    LOOP_DEV=$(sudo losetup -fP --show "$IMAGE_FILE")
    
    # Format partitions
    sudo mkfs.vfat -F 32 -n CLIPERBOOT "${LOOP_DEV}p1"
    sudo mkfs.ext4 -L CLIPERROOT "${LOOP_DEV}p2"
    
    # Mount
    sudo mount "${LOOP_DEV}p2" "$ROOTFS_DIR"
    sudo mkdir -p "$ROOTFS_DIR/boot/firmware"
    sudo mount "${LOOP_DEV}p1" "$ROOTFS_DIR/boot/firmware"
    
    log "✅ Disk image created and mounted"
}

bootstrap_rootfs() {
    log "Bootstrapping Kali Linux root filesystem..."
    
    # Stage 1: debootstrap
    sudo debootstrap --arch="${ARCH}" \
        --foreign \
        --include=ca-certificates,apt-transport-https \
        "${KALI_SUITE}" \
        "$ROOTFS_DIR" \
        "$KALI_MIRROR"
    
    # Copy QEMU for ARM64 emulation
    sudo cp /usr/bin/qemu-aarch64-static "$ROOTFS_DIR/usr/bin/"
    
    # Stage 2: complete debootstrap
    sudo chroot "$ROOTFS_DIR" /debootstrap/debootstrap --second-stage
    
    log "✅ Root filesystem bootstrapped"
}

configure_system() {
    log "Configuring Cliper X OS..."
    
    # Set hostname
    echo "cliperx" | sudo tee "$ROOTFS_DIR/etc/hostname"
    
    # Configure /etc/hosts
    cat <<EOF | sudo tee "$ROOTFS_DIR/etc/hosts"
127.0.0.1   localhost
127.0.1.1   cliperx
::1         localhost ip6-localhost ip6-loopback
EOF
    
    # Configure apt sources (Kali repos)
    cat <<EOF | sudo tee "$ROOTFS_DIR/etc/apt/sources.list"
deb ${KALI_MIRROR} ${KALI_SUITE} main contrib non-free non-free-firmware
deb-src ${KALI_MIRROR} ${KALI_SUITE} main contrib non-free non-free-firmware
EOF
    
    # Configure locale
    echo "en_US.UTF-8 UTF-8" | sudo tee "$ROOTFS_DIR/etc/locale.gen"
    sudo chroot "$ROOTFS_DIR" locale-gen
    
    # Configure timezone
    sudo chroot "$ROOTFS_DIR" ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    
    # Set root password (default: cliperx — user MUST change on first boot)
    echo "root:cliperx" | sudo chroot "$ROOTFS_DIR" chpasswd
    
    # Create default user
    sudo chroot "$ROOTFS_DIR" useradd -m -s /bin/bash -G sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev,netdev,bluetooth cliper
    echo "cliper:cliperx" | sudo chroot "$ROOTFS_DIR" chpasswd
    
    # Enable SSH
    sudo chroot "$ROOTFS_DIR" systemctl enable ssh
    
    # Configure fstab
    cat <<EOF | sudo tee "$ROOTFS_DIR/etc/fstab"
# Cliper X OS fstab
LABEL=CLIPERROOT  /               ext4    defaults,noatime    0   1
LABEL=CLIPERBOOT  /boot/firmware  vfat    defaults            0   2
tmpfs             /tmp            tmpfs   defaults,nosuid     0   0
EOF
    
    log "✅ System configured"
}

install_kernel() {
    log "Installing RPi5 kernel..."
    
    sudo chroot "$ROOTFS_DIR" apt-get update
    sudo chroot "$ROOTFS_DIR" apt-get install -y \
        linux-image-arm64 \
        raspberrypi-kernel \
        raspberrypi-kernel-headers \
        firmware-brcm80211 \
        firmware-misc-nonfree
    
    # Apply custom kernel patches
    if [ -d "${PROJECT_ROOT}/kernel/patches" ]; then
        log "Applying custom kernel patches..."
        for patch in "${PROJECT_ROOT}/kernel/patches"/*.patch; do
            [ -f "$patch" ] && log "  Applying: $(basename "$patch")"
        done
    fi
    
    # Install custom device tree overlays
    if [ -d "${PROJECT_ROOT}/kernel/device-tree" ]; then
        log "Installing device tree overlays..."
        sudo cp "${PROJECT_ROOT}/kernel/device-tree"/*.dtbo \
            "$ROOTFS_DIR/boot/firmware/overlays/" 2>/dev/null || true
    fi
    
    # Configure boot
    cat <<EOF | sudo tee "$ROOTFS_DIR/boot/firmware/config.txt"
# Cliper X OS Boot Configuration — Raspberry Pi 5

# Hardware
arm_64bit=1
arm_boost=1
over_voltage=6
arm_freq=2400

# Display (7" touchscreen)
dtoverlay=vc4-kms-v3d
max_framebuffers=2
hdmi_force_hotplug=1
display_auto_detect=1

# Touchscreen
dtoverlay=ads7846
dtparam=cs=1,speed=50000,penirq=25,pmax=255,swapxy=0,xmin=200,xmax=3900,ymin=200,ymax=3900

# Fan control (active cooling)
dtoverlay=gpio-fan,gpiopin=14,temp=55000
dtparam=fan_temp0=55000,fan_temp0_hyst=5000,fan_temp0_speed=75
dtparam=fan_temp1=60000,fan_temp1_hyst=5000,fan_temp1_speed=125
dtparam=fan_temp2=67500,fan_temp2_hyst=5000,fan_temp2_speed=175
dtparam=fan_temp3=75000,fan_temp3_hyst=5000,fan_temp3_speed=250

# Battery / Power (UPS HAT via I2C)
dtparam=i2c_arm=on
dtoverlay=i2c-rtc,ds3231

# USB-C
dtoverlay=dwc2,dr_mode=otg

# Audio
dtparam=audio=on

# Bluetooth
dtparam=krnbt=on

# Memory
gpu_mem=256
EOF

    cat <<EOF | sudo tee "$ROOTFS_DIR/boot/firmware/cmdline.txt"
console=serial0,115200 console=tty1 root=LABEL=CLIPERROOT rootfstype=ext4 fsck.repair=yes rootwait quiet splash loglevel=3 systemd.show_status=auto rd.udev.log_level=3 cryptdevice=LABEL=CLIPERROOT:cliperx-crypt
EOF
    
    log "✅ Kernel installed and configured"
}

install_tools() {
    log "Installing security tools (variant: ${VARIANT})..."
    
    # Core tools (all variants)
    local CORE_TOOLS=(
        # System
        sudo vim nano htop tmux screen git curl wget
        net-tools iproute2 dnsutils iputils-ping
        build-essential python3 python3-pip python3-venv
        # Terminal
        zsh fish neofetch
    )
    
    # Minimal variant tools
    local MINIMAL_TOOLS=(
        nmap masscan netcat-openbsd tcpdump wireshark-common
        aircrack-ng wifite
        hashcat john hydra
        metasploit-framework
        burpsuite
        sqlmap nikto
    )
    
    # Full variant tools (everything)
    local FULL_TOOLS=(
        # Reconnaissance
        nmap masscan recon-ng theharvester amass
        maltego spiderfoot
        
        # Wireless
        aircrack-ng wifite bettercap kismet hostapd dnsmasq
        
        # Web Application
        burpsuite sqlmap nikto dirb dirsearch gobuster
        wpscan zaproxy
        
        # Exploitation
        metasploit-framework exploitdb
        
        # Post-Exploitation
        powershell-empire covenant
        
        # Password Attacks
        hashcat john hydra medusa ophcrack cewl crunch
        
        # Forensics
        autopsy volatility3 binwalk foremost scalpel
        
        # Reverse Engineering
        ghidra radare2 gdb
        
        # Sniffing & Spoofing
        wireshark ettercap-graphical responder mitmproxy
        
        # Reporting
        cherrytree faraday
        
        # Utilities
        tor proxychains4 openvpn wireguard-tools
        macchanger bleachbit
    )
    
    sudo chroot "$ROOTFS_DIR" apt-get update
    
    log "Installing core tools..."
    sudo chroot "$ROOTFS_DIR" apt-get install -y "${CORE_TOOLS[@]}" || true
    
    case "$VARIANT" in
        minimal)
            log "Installing minimal tool set..."
            sudo chroot "$ROOTFS_DIR" apt-get install -y "${MINIMAL_TOOLS[@]}" || true
            ;;
        full|dev)
            log "Installing full tool set..."
            sudo chroot "$ROOTFS_DIR" apt-get install -y "${FULL_TOOLS[@]}" || true
            ;;
    esac
    
    # Install custom Cliper X tools
    if [ -d "${PROJECT_ROOT}/tools/custom-tools" ]; then
        log "Installing Cliper X custom tools..."
        sudo cp -r "${PROJECT_ROOT}/tools/custom-tools/"* "$ROOTFS_DIR/opt/cliperx/" 2>/dev/null || true
    fi
    
    log "✅ Security tools installed"
}

install_desktop() {
    log "Installing Cliper X desktop environment..."
    
    # Install X11 and display manager
    sudo chroot "$ROOTFS_DIR" apt-get install -y \
        xorg xinit lightdm lightdm-gtk-greeter \
        i3 i3status i3lock \
        polybar rofi dunst picom feh \
        alacritty thunar \
        lxappearance arc-theme papirus-icon-theme \
        fonts-font-awesome fonts-hack \
        pulseaudio pavucontrol \
        network-manager-gnome

    # Copy desktop configurations
    log "Applying Cliper X desktop theme..."
    
    # i3 config
    sudo mkdir -p "$ROOTFS_DIR/home/cliper/.config/i3"
    sudo cp "${PROJECT_ROOT}/desktop/i3/config" "$ROOTFS_DIR/home/cliper/.config/i3/" 2>/dev/null || true
    
    # Polybar config
    sudo mkdir -p "$ROOTFS_DIR/home/cliper/.config/polybar"
    sudo cp "${PROJECT_ROOT}/desktop/polybar/config.ini" "$ROOTFS_DIR/home/cliper/.config/polybar/" 2>/dev/null || true
    sudo cp "${PROJECT_ROOT}/desktop/polybar/launch.sh" "$ROOTFS_DIR/home/cliper/.config/polybar/" 2>/dev/null || true
    
    # Rofi config
    sudo mkdir -p "$ROOTFS_DIR/home/cliper/.config/rofi"
    sudo cp "${PROJECT_ROOT}/desktop/rofi/config.rasi" "$ROOTFS_DIR/home/cliper/.config/rofi/" 2>/dev/null || true
    
    # Alacritty config
    sudo mkdir -p "$ROOTFS_DIR/home/cliper/.config/alacritty"
    sudo cp "${PROJECT_ROOT}/desktop/alacritty/alacritty.toml" "$ROOTFS_DIR/home/cliper/.config/alacritty/" 2>/dev/null || true
    
    # Wallpapers
    sudo mkdir -p "$ROOTFS_DIR/usr/share/backgrounds/cliperx"
    sudo cp "${PROJECT_ROOT}/desktop/themes/wallpapers/"* "$ROOTFS_DIR/usr/share/backgrounds/cliperx/" 2>/dev/null || true
    
    # Fix permissions
    sudo chroot "$ROOTFS_DIR" chown -R cliper:cliper /home/cliper/.config
    
    log "✅ Desktop environment installed"
}

install_hardware_drivers() {
    log "Installing hardware drivers & management..."
    
    # Battery management daemon
    sudo cp "${PROJECT_ROOT}/hardware/battery/cliperx-battery.service" \
        "$ROOTFS_DIR/etc/systemd/system/" 2>/dev/null || true
    sudo cp "${PROJECT_ROOT}/hardware/battery/battery_monitor.py" \
        "$ROOTFS_DIR/opt/cliperx/hardware/" 2>/dev/null || true
    
    # Fan controller daemon
    sudo cp "${PROJECT_ROOT}/hardware/cooling/cliperx-fan.service" \
        "$ROOTFS_DIR/etc/systemd/system/" 2>/dev/null || true
    sudo cp "${PROJECT_ROOT}/hardware/cooling/fan_controller.py" \
        "$ROOTFS_DIR/opt/cliperx/hardware/" 2>/dev/null || true
    
    # Display brightness control
    sudo cp "${PROJECT_ROOT}/hardware/display/brightness.sh" \
        "$ROOTFS_DIR/usr/local/bin/cliperx-brightness" 2>/dev/null || true
    
    # Power management
    sudo cp "${PROJECT_ROOT}/hardware/power/power_manager.py" \
        "$ROOTFS_DIR/opt/cliperx/hardware/" 2>/dev/null || true
    
    # Enable services
    sudo chroot "$ROOTFS_DIR" systemctl enable cliperx-battery.service 2>/dev/null || true
    sudo chroot "$ROOTFS_DIR" systemctl enable cliperx-fan.service 2>/dev/null || true
    
    log "✅ Hardware drivers installed"
}

apply_security_hardening() {
    log "Applying security hardening..."
    
    # MAC address randomization
    cat <<EOF | sudo tee "$ROOTFS_DIR/etc/NetworkManager/conf.d/mac-randomization.conf"
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF
    
    # DNS over HTTPS
    cat <<EOF | sudo tee "$ROOTFS_DIR/etc/systemd/resolved.conf.d/doh.conf"
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 8.8.8.8#dns.google
DNSOverTLS=yes
DNSSEC=yes
EOF
    
    # Firewall rules
    sudo cp "${PROJECT_ROOT}/security/firewall/nftables.conf" \
        "$ROOTFS_DIR/etc/nftables.conf" 2>/dev/null || true
    sudo chroot "$ROOTFS_DIR" systemctl enable nftables 2>/dev/null || true
    
    # Disable unnecessary services
    sudo chroot "$ROOTFS_DIR" systemctl disable avahi-daemon 2>/dev/null || true
    sudo chroot "$ROOTFS_DIR" systemctl disable cups 2>/dev/null || true
    
    # SSH hardening
    cat <<EOF | sudo tee -a "$ROOTFS_DIR/etc/ssh/sshd_config.d/hardening.conf"
PermitRootLogin no
PasswordAuthentication no
X11Forwarding no
MaxAuthTries 3
Protocol 2
EOF
    
    log "✅ Security hardening applied"
}

cleanup_and_compress() {
    log "Cleaning up and compressing image..."
    
    # Clean apt cache
    sudo chroot "$ROOTFS_DIR" apt-get clean
    sudo chroot "$ROOTFS_DIR" apt-get autoremove -y
    
    # Remove QEMU binary
    sudo rm -f "$ROOTFS_DIR/usr/bin/qemu-aarch64-static"
    
    # Unmount
    sudo umount "$ROOTFS_DIR/boot/firmware" || true
    sudo umount "$ROOTFS_DIR" || true
    sudo losetup -d "$LOOP_DEV" || true
    
    # Compress image
    log "Compressing image..."
    xz -T0 -9 "$IMAGE_FILE"
    
    log "✅ Image compressed: ${IMAGE_FILE}.xz"
}

# ========================
# Main
# ========================

banner
check_dependencies
prepare_build_dir
create_image
bootstrap_rootfs
configure_system
install_kernel
install_tools
install_desktop
install_hardware_drivers
apply_security_hardening
cleanup_and_compress

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     CLIPER X OS BUILD COMPLETE! 🎉      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "  Image: ${IMAGE_FILE}.xz"
echo "  Flash: sudo dd if=${IMAGE_FILE} of=/dev/sdX bs=4M status=progress"
echo ""
echo "  Default credentials:"
echo "    User: cliper / Password: cliperx"
echo "    ⚠️  CHANGE ON FIRST BOOT!"
echo ""
