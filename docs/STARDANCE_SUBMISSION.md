# 🌟 Hack Club Stardance — Hardware Submission

## Project: CLIPER X OS + JARVIS AI Wearable System

**Applicant:** Avi  
**Requested Tier:** ⭐ **X Tier** (up to $600)  
**Estimated Total Cost:** ~$375 (core build)  
**Date:** October 18, 2026

---

## 🎯 Project Summary

**Cliper X OS** is a custom Kali Linux distribution built from scratch for the Raspberry Pi 5 (16GB RAM), designed to transform it into a fully portable **hacking laptop** with a custom 3D-printed chassis, integrated battery, touchscreen display, and active cooling.

Paired with **JARVIS** — an AI assistant running on Ray-Ban Meta Smart Glasses + Google Pixel phone with distributed inference — these two projects form a complete wearable + portable security research platform.

---

## 🔧 What I'm Building

### Hardware: RPi5 Hacking Laptop (Cliper X OS)

A fully integrated, battery-powered, portable cybersecurity workstation:

| Component | Model/Spec | Cost |
|-----------|-----------|------|
| Raspberry Pi 5 — 16GB RAM | SBC (Broadcom BCM2712, Quad-core A76 @ 2.4GHz) | $80 |
| NVMe SSD 256GB | Pimoroni NVMe Base (M.2 HAT) | $40 |
| 7" IPS Touchscreen | 1024×600, DSI ribbon cable | $45 |
| 10000mAh UPS HAT | PiSugar 3 Plus (LiPo + PD charging) | $50 |
| Active Cooler | Official RPi5 Cooler (fan + heatsink) | $5 |
| Mini BT Mech Keyboard | Bluetooth Mechanical Keyboard | $30 |
| Alfa AWUS036ACH | Dual-band USB WiFi (monitor mode) | $60 |
| 3D Printed Laptop Shell | Custom designed chassis (STL files) | $25 |
| USB-C Hub | 4-port USB-C with PD passthrough | $20 |
| Cables + Hardware | FFC, USB-C, M2.5 standoffs, thermal pads | $20 |
| **Total** | | **~$375** |

### Software: Custom Linux Distribution

- **Base:** Kali Linux ARM64 (Kernel 6.6 LTS)
- **Desktop:** i3wm + Polybar + Rofi + Alacritty (keyboard-driven tiling WM)
- **Pre-loaded Tools:** 50+ security tools across 10 categories (recon, wireless, web, exploit, forensics, SDR, BLE, password, OSINT, post-exploit)
- **Security Hardening:** LUKS full-disk encryption, MAC randomization, DNS-over-HTTPS, Tor integration, nftables firewall
- **Hardware Drivers:** Custom fan controller (Python), battery monitor, display brightness control, power profiles

### Companion Project: JARVIS AI Assistant

- **Platform:** Android (Kotlin) on Google Pixel + Ray-Ban Meta Smart Glasses
- **Inference:** Hybrid edge + cloud model sharding (llama.cpp, ONNX Runtime, vLLM)
- **Features:** Voice activation ("Hey JARVIS"), real-time vision processing, tool execution framework
- **Communication:** gRPC + Protobuf between glasses ↔ phone ↔ cloud

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│                   CLIPER X OS                        │
│  ┌─────────────────────────────────────────────────┐ │
│  │          Custom Desktop (i3wm + Polybar)        │ │
│  ├─────────────────────────────────────────────────┤ │
│  │    Tool Framework (50+ Security Tools)          │ │
│  ├─────────────────────────────────────────────────┤ │
│  │    Hardware Abstraction Layer                   │ │
│  │  Display │ Battery │ Cooling │ WiFi │ BT │ SDR  │ │
│  ├─────────────────────────────────────────────────┤ │
│  │    Kali Linux Kernel 6.6 LTS (ARM64)           │ │
│  └─────────────────────────────────────────────────┘ │
│              Raspberry Pi 5 (16GB RAM)               │
└──────────────────────────────────────────────────────┘
         │                              │
    USB / WiFi                     BLE / WiFi
         │                              │
         ▼                              ▼
┌─────────────────┐          ┌─────────────────────┐
│  JARVIS (Pixel) │◄────────►│ Ray-Ban Meta Glasses │
│  AI Inference   │   BLE    │ Camera + Mic + HUD   │
└─────────────────┘          └─────────────────────┘
```

---

## 📊 Wiring Diagram

```
                    ┌─── HDMI Out ──────► External Monitor
                    │
┌──────────────┐    ├─── DSI ───────────► 7" Touchscreen
│              │    │
│  RPi 5       │────┼─── USB 3.0 ───────► Alfa WiFi (Monitor Mode)
│  16GB RAM    │    │
│              │────┼─── USB 3.0 ───────► USB-C Hub
│              │    │                      ├── HackRF One
│  [NVMe HAT]  │    │                      ├── Ubertooth
│  [256GB SSD] │    │                      └── Keyboard
│              │────┼─── GPIO I2C ──────► UPS HAT (Battery)
│  [Cooler]    │────┼─── GPIO PWM ──────► Fan (Active Cooling)
│              │────┼─── USB-C ─────────► PD Charger (45W)
└──────────────┘    │
                    └─── WiFi 6 ────────► Onboard WiFi
```

---

## ⚡ Power Budget

| Component | Draw | Notes |
|-----------|------|-------|
| RPi 5 (load) | 2500mA | Full CPU + GPU |
| 7" Display | 500mA | Backlight on |
| NVMe SSD | 200mA | Active R/W |
| Alfa WiFi | 400mA | Monitor mode |
| Fan | 100mA | Full speed |
| **Total (max)** | **~3700mA** | |
| **Battery Life** | **~2.7 hrs** | Max load |
| **Battery Life** | **~6 hrs** | Balanced mode |

---

## 📂 Code Already Written

The project is actively being developed with working code:

- ✅ Full project structure and build system
- ✅ Custom i3wm desktop configuration
- ✅ Fan controller (`hardware/cooling/fan_controller.py`)
- ✅ Battery management drivers
- ✅ Display driver integration
- ✅ First-boot setup script
- ✅ Security hardening scripts (LUKS, MAC randomization, firewall)
- ✅ JARVIS Android app scaffolding (Kotlin)
- ✅ Voice pipeline with wake-word detection
- ✅ Ray-Ban Meta glasses BLE bridge
- ✅ gRPC/Protobuf communication layer
- ✅ Hardware build documentation

---

## 🎯 Why X Tier?

1. **Multi-layer hardware integration** — SBC + display + battery + cooling + WiFi adapter + 3D-printed chassis
2. **Custom OS from scratch** — Not just installing Kali, but building a full custom distro with hardware drivers, desktop environment, and security hardening
3. **Production-quality build** — Complete BOM, wiring diagrams, power budget, assembly instructions, 3D-printable chassis STLs
4. **Companion AI system** — JARVIS adds wearable AI with distributed inference across glasses ↔ phone ↔ cloud
5. **Real-world utility** — A functional, portable cybersecurity workstation for ethical security research

---

## 🔗 Repository

**GitHub:** *(add your repo link here)*

---

## 📸 Build Progress

*(Add photos/videos of your build progress, 3D-printed chassis, assembled hardware, and demo recordings here)*

---

> Built with ❤️ for **Hack Club Stardance** 🌟
