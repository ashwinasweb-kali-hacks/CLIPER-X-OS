# 🔌 Electrical & Interconnect Architecture (Wiring & PCB)

This directory documents the electrical wiring harness, HAT stack pinout, power distribution, and communication buses of the **Cliper X OS** Raspberry Pi 5 portable system.

## 📐 Visual Schematic

See [`wiring_schematic.svg`](wiring_schematic.svg) for the full vector wiring diagram.

```text
                    ┌─── MIPI DSI (22-pin FFC) ──► 7" IPS Touchscreen
                    │
┌──────────────┐    ├─── PCIe Gen 2/3 (16-pin) ──► NVMe Base HAT (256GB SSD)
│              │    │
│  RPi 5       │────┼─── USB 3.0 Port 0 ─────────► Alfa AWUS036ACH WiFi
│  (16GB RAM)  │    │
│              │────┼─── USB 3.0 Port 1 ─────────► 4-Port USB Hub (Keyboard / SDR)
│              │    │
│              │────┼─── JST-SH 4-Pin ───────────► Active PWM Cooler
│              │    │
│              │────┼─── GPIO Pins 3 & 5 (I2C1) ─► PiSugar 3 Battery Telemetry
│              │    │
│              │────┼─── GPIO Pins 2 & 6 (5V/GND)◄- PiSugar 3 5.1V/3A Power Rail
└──────────────┘    │
                    └─── External USB-C Port ────► 45W USB-PD Fast Charging
```

---

## 📌 GPIO & Bus Pinout Mapping

| Subsystem | Signal Name | RPi 5 Physical Pin | BCM GPIO / Bus | Level / Spec |
|:----------|:------------|:-------------------|:---------------|:-------------|
| **Power** | 5V Boost Rail | Pin 2, Pin 4 | 5V Power Bus | 5.1V DC (3A rated) |
| **Ground** | System GND | Pin 6, Pin 9, Pin 14 | Ground Plane | Common GND |
| **Battery I2C** | I2C1 SDA | Pin 3 | GPIO 2 | 3.3V Logic (PiSugar address `0x57` / `0x75`) |
| **Battery I2C** | I2C1 SCL | Pin 5 | GPIO 3 | 3.3V Logic (400kHz Fast Mode) |
| **Display** | MIPI DSI | Dedicated 22-pin FFC | DSI 2-lane | 1024x600 @ 60Hz |
| **Touchscreen**| Touch I2C | DSI Aux / GPIO | I2C Touch | Goodix capacitive controller |
| **Cooling** | PWM Fan | Dedicated 4-Pin JST | Fan PWM Controller | 5V PWM (Tacho feedback) |
| **Storage** | PCIe 1-lane | Dedicated 16-Pin FFC | PCIe Gen 2.0 / 3.0 | 500 MB/s sustained throughput |

---

## ⚡ Power Delivery & Current Budget

- **Max System Load (CPU All-Cores @ 2.4GHz + GPU + Monitor Mode WiFi):** ~3,700mA @ 5.1V (~18.8W)
- **Balanced Workload (i3wm, Terminal, Lightweight Recon):** ~1,600mA @ 5.1V (~8.1W)
- **Idle Power Consumption:** ~600mA @ 5.1V (~3.0W)
- **Battery Pack:** 10,000mAh (37Wh) LiPo Cell -> **~2.7 hours** continuous full load, **~6 hours** balanced runtime.
