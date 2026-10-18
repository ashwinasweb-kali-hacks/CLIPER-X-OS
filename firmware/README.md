# ⚡ Cliper X OS — Firmware & Hardware Daemons

This directory contains the embedded control software and Linux background daemons managing physical hardware subsystems on the Raspberry Pi 5.

## 🛠️ Components

### 1. Active Fan Controller (`fan_controller.py`)
- **Protocol:** PWM GPIO / Linux sysfs thermal zone
- **Function:** Dynamic fan curve management for Raspberry Pi 5 BCM2712 SoC.
- **Trip Points:**
  - `< 50°C`: Fan 0% (Silent operation)
  - `50°C - 65°C`: Fan 35% - 60% (Linear acoustic scaling)
  - `65°C - 75°C`: Fan 75% - 90% (Sustained multi-threaded offensive tooling)
  - `> 75°C`: Fan 100% emergency thermal throttle protection
- **Service:** `services/cliperx-fan.service`

### 2. Battery & Power Telemetry (`battery_monitor.py`)
- **Protocol:** I2C Bus 1 (Address `0x57` / `0x75`)
- **Hardware:** PiSugar 3 Plus 10000mAh Battery HAT
- **Function:** Reads raw battery cell voltage, percentage remaining, charge/discharge status, and generates low-battery notifications to the i3wm status bar (Polybar).
- **Service:** `services/cliperx-battery.service`

### 3. Display Backlight Controller (`brightness.sh`)
- **Protocol:** DSI backlight sysfs interface (`/sys/class/backlight/`)
- **Function:** Software PWM brightness stepping (0 - 255) mapped to keyboard hotkeys in i3wm (`Mod4 + F5` / `Mod4 + F6`).

---

## 🚀 Installation & Service Enablement

To register and activate these services on the system:

```bash
sudo cp services/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now cliperx-fan.service
sudo systemctl enable --now cliperx-battery.service
```
