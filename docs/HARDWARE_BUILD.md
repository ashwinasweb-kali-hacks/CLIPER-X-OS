# Cliper X OS — Hardware Build Guide
# Assembly Instructions for RPi5 Hacking Laptop

## Bill of Materials (BOM)

| # | Component | Model/Spec | Qty | Est. Cost |
|---|-----------|-----------|-----|-----------|
| 1 | SBC | Raspberry Pi 5 — 16GB RAM | 1 | $80 |
| 2 | Storage | NVMe SSD 256GB (Pimoroni NVMe Base) | 1 | $40 |
| 3 | Display | 7" IPS Touchscreen 1024x600 | 1 | $45 |
| 4 | Battery | 10000mAh UPS HAT (PiSugar 3 Plus) | 1 | $50 |
| 5 | Cooling | Active Cooler (Official RPi5 Cooler) | 1 | $5 |
| 6 | Keyboard | Mini Bluetooth Mechanical Keyboard | 1 | $30 |
| 7 | WiFi Adapter | Alfa AWUS036ACH (monitor mode) | 1 | $60 |
| 8 | Case/Chassis | 3D Printed Custom Laptop Shell | 1 | $25 |
| 9 | USB-C Hub | 4-port USB-C Hub with PD passthrough | 1 | $20 |
| 10 | Cables | FFC ribbon cable, USB-C cables | misc | $10 |
| 11 | Misc | M2.5 standoffs, screws, thermal pads | misc | $10 |
| **Total** | | | | **~$375** |

### Optional Upgrades

| Component | Purpose | Cost |
|-----------|---------|------|
| HackRF One | SDR (Software Defined Radio) | $350 |
| Ubertooth One | Bluetooth sniffing | $120 |
| RTL-SDR v3 | Budget SDR receiver | $30 |
| 10.1" FHD Display | Larger screen | $80 |
| 20000mAh Battery | Extended runtime | $70 |

## Assembly Steps

### Step 1: Prepare the SBC
1. Attach the NVMe Base HAT to the RPi5
2. Install NVMe SSD into the M.2 slot
3. Apply thermal pad between CPU and heatsink
4. Attach the active cooler fan

### Step 2: Battery Setup
1. Connect UPS HAT (PiSugar 3) to GPIO header
2. Ensure I2C pins (SDA/SCL) are properly connected
3. Connect battery pack to UPS HAT
4. Verify charging via USB-C PD

### Step 3: Display Connection
1. Connect 7" display via DSI ribbon cable
2. Alternatively, use HDMI for external display
3. Configure touch input (I2C or USB)

### Step 4: Chassis Assembly
1. 3D print the laptop chassis (STL files in `docs/3d-models/`)
2. Mount RPi5 + NVMe base on bottom panel
3. Mount display on top panel (with hinge)
4. Route cables through chassis channels
5. Mount USB-C hub on side panel
6. Install keyboard in palm rest area
7. Secure with M2.5 standoffs and screws

### Step 5: WiFi Adapter
1. Connect Alfa AWUS036ACH via USB 3.0
2. Mount antenna on chassis lid
3. Route USB cable through chassis

### Step 6: Final Assembly
1. Close chassis and secure all panels
2. Verify all connections
3. Power on and boot into Cliper X OS

## Wiring Diagram

```
                    ┌─── HDMI Out ──────► External Monitor
                    │
┌──────────────┐    ├─── DSI ───────────► 7" Touchscreen
│              │    │
│  RPi 5       │────┼─── USB 3.0 ───────► Alfa WiFi (Monitor Mode)
│  16GB RAM    │    │
│              │────┼─── USB 3.0 ───────► USB-C Hub
│              │    │                      ├── HackRF One
│              │    │                      ├── Ubertooth
│              │    │                      └── Keyboard
│              │    │
│  [NVMe HAT]  │────┼─── GPIO I2C ──────► UPS HAT (Battery)
│  [256GB SSD] │    │
│              │────┼─── GPIO PWM ──────► Fan (Active Cooling)
│  [Cooler]    │    │
│              │────┼─── USB-C ─────────► PD Charger (45W)
│              │    │
│              │────┼─── Ethernet ──────► RJ45 (Optional)
│              │    │
│              │────┼─── Bluetooth ─────► Keyboard/Mouse
└──────────────┘    │
                    └─── WiFi 6 ────────► Onboard WiFi
```

## Power Budget

| Component | Current Draw | Notes |
|-----------|-------------|-------|
| RPi 5 (idle) | 600mA | Base system |
| RPi 5 (load) | 2500mA | Full CPU + GPU |
| Display 7" | 500mA | Backlight on |
| NVMe SSD | 200mA | Active R/W |
| Alfa WiFi | 400mA | Monitor mode |
| Fan | 100mA | Full speed |
| **Total (max)** | **~3700mA** | |
| **Battery Life** | **~2.7 hours** | 10000mAh @ max load |
| **Battery Life** | **~6 hours** | Balanced mode |
