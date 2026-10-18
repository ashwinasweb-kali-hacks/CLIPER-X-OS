# 🔒 CLIPER X OS — Custom Kali Linux for Raspberry Pi 5

> A purpose-built offensive security operating system for the Raspberry Pi 5 (16GB RAM)
> Hardware: Display, Battery/Charger, Active Cooling, USB-C, Custom Laptop Form Factor

---

## Overview

**Cliper X OS** is a custom Linux distribution based on **Kali Linux**, optimized for the **Raspberry Pi 5 (16GB RAM)**. It transforms the Pi into a portable, powerful hacking laptop with integrated hardware (display, battery, cooling, Type-C) running a fully customized security-focused operating system.

## Hardware Specifications

| Component | Specification |
|-----------|--------------|
| **SBC** | Raspberry Pi 5 — 16GB RAM |
| **CPU** | Broadcom BCM2712, Quad-core Cortex-A76 @ 2.4GHz |
| **GPU** | VideoCore VII |
| **RAM** | 16GB LPDDR4X-4267 |
| **Storage** | NVMe SSD via M.2 HAT (256GB+) |
| **Display** | 7" IPS Touchscreen (1024x600) / 10.1" FHD |
| **Battery** | 10000mAh LiPo + PD Charging Circuit |
| **Charger** | USB-C PD 45W Fast Charging |
| **Cooling** | Active Fan + Heatsink + Thermal Pad |
| **Ports** | USB-C (PD + Data), USB 3.0 x2, HDMI, Ethernet |
| **WiFi** | Dual-band WiFi 6 + External Alfa AWUS036ACH |
| **Bluetooth** | BT 5.0 + External Ubertooth One |
| **SDR** | HackRF One / RTL-SDR (optional) |
| **Form Factor** | Custom 3D-printed laptop chassis |

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                   CLIPER X OS                        │
│  ┌─────────────────────────────────────────────────┐ │
│  │          Custom Desktop Environment             │ │
│  │    (i3wm + Polybar + Rofi + Custom Themes)      │ │
│  ├─────────────────────────────────────────────────┤ │
│  │              Tool Framework Layer               │ │
│  │  ┌─────────┐ ┌──────────┐ ┌──────────────────┐ │ │
│  │  │ Recon   │ │ Exploit  │ │ Post-Exploit     │ │ │
│  │  │ Tools   │ │ Tools    │ │ Tools            │ │ │
│  │  └─────────┘ └──────────┘ └──────────────────┘ │ │
│  ├─────────────────────────────────────────────────┤ │
│  │            Hardware Abstraction Layer            │ │
│  │  Display │ Battery │ Cooling │ WiFi │ BT │ SDR  │ │
│  ├─────────────────────────────────────────────────┤ │
│  │     Kali Linux Kernel (6.6 LTS - ARM64)         │ │
│  │     Custom Device Tree + Drivers + Patches      │ │
│  └─────────────────────────────────────────────────┘ │
│                  Raspberry Pi 5 Hardware             │
└──────────────────────────────────────────────────────┘
```

## Features

### 🖥️ Custom Desktop
- **i3wm** tiling window manager (keyboard-driven)
- **Polybar** status bar (battery, CPU, WiFi, BT, temp)
- **Rofi** application launcher
- **Alacritty** GPU-accelerated terminal
- **Custom Kali themes** + wallpapers

### 🔧 Pre-installed Tool Categories
- **Reconnaissance**: nmap, masscan, recon-ng, theHarvester, Shodan CLI
- **Wireless**: aircrack-ng, wifite, bettercap, kismet, hostapd
- **Web**: Burp Suite, sqlmap, nikto, dirsearch, ffuf, httpx
- **Exploitation**: Metasploit, searchsploit, crackmapexec
- **Post-Exploitation**: Mimikatz, BloodHound, Covenant, Sliver
- **Forensics**: Autopsy, Volatility, binwalk, foremost
- **SDR**: GNU Radio, GQRX, Universal Radio Hacker
- **Bluetooth**: Ubertooth tools, BtleJuice, Bettercap BLE
- **Password**: hashcat, John the Ripper, hydra, medusa
- **OSINT**: Maltego, SpiderFoot, Photon, sherlock

### ⚡ Hardware Management
- Battery monitoring + low-power alerts
- Fan speed control (thermal management)
- Display brightness control
- Power profiles (performance / balanced / battery saver)

### 🛡️ Security Hardening
- Full disk encryption (LUKS)
- MAC address randomization on boot
- DNS-over-HTTPS (DoH) by default
- Tor integration
- Firewall (nftables) pre-configured

## Quick Start

```bash
# Flash Cliper X OS to NVMe SSD
sudo ./scripts/flash-os.sh /dev/nvme0n1

# Or build from source
./build.sh --target rpi5 --variant full

# First boot setup
# 1. Connect display, keyboard, power
# 2. Boot into Cliper X installer
# 3. Set up encryption passphrase
# 4. Configure WiFi + user account
```

## Project Structure

```
CLIPER-X-OS/
├── build/                    # Build system
│   ├── build.sh              # Main build script
│   ├── Dockerfile            # Build environment
│   └── config/               # Build configurations
├── kernel/                   # Custom kernel patches
│   ├── patches/              # RPi5 kernel patches
│   ├── config                # Kernel .config
│   └── device-tree/          # Custom device tree overlays
├── rootfs/                   # Root filesystem customizations
│   ├── etc/                  # System configuration
│   ├── usr/                  # Custom binaries & scripts
│   └── opt/                  # Tool installations
├── desktop/                  # Desktop environment
│   ├── i3/                   # i3wm configuration
│   ├── polybar/              # Status bar config
│   ├── rofi/                 # Launcher config
│   ├── alacritty/            # Terminal config
│   └── themes/               # Custom themes & wallpapers
├── tools/                    # Tool management
│   ├── install-tools.sh      # Tool installer
│   ├── tool-configs/         # Pre-configured tool settings
│   └── custom-tools/         # Cliper X exclusive tools
├── hardware/                 # Hardware drivers & management
│   ├── display/              # Touchscreen drivers
│   ├── battery/              # Battery management system
│   ├── cooling/              # Fan controller
│   ├── wifi/                 # WiFi adapter drivers
│   └── power/                # Power management
├── security/                 # Security configurations
│   ├── encryption/           # LUKS + dm-crypt
│   ├── firewall/             # nftables rules
│   ├── privacy/              # MAC randomization, Tor
│   └── hardening/            # System hardening scripts
├── scripts/                  # Utility scripts
│   ├── flash-os.sh           # OS flashing script
│   ├── first-boot.sh         # First boot setup
│   └── update.sh             # System update script
├── docs/                     # Documentation
│   ├── HARDWARE_BUILD.md     # Hardware assembly guide
│   ├── USER_GUIDE.md         # User manual
│   └── DEVELOPMENT.md        # Development guide
└── LICENSE
```

## License

GPL v3 — Based on Kali Linux (Offensive Security)

Built for **Stardance Hackclub Foundation** 🌟
