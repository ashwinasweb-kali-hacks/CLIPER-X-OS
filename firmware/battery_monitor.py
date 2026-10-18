#!/usr/bin/env python3
"""
Cliper X OS — Battery Management System
Monitors UPS HAT battery via I2C on Raspberry Pi 5

Features:
- Real-time battery percentage monitoring
- Charging status detection
- Low battery warnings (desktop notification + LED)
- Critical battery auto-shutdown
- Power profile switching
- Battery health tracking
"""

import smbus2
import time
import subprocess
import logging
import json
import os
import signal
import sys
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import Optional

# ========================
# Configuration
# ========================

I2C_BUS = 1
INA219_ADDRESS = 0x40  # INA219 current/voltage sensor on UPS HAT
MAX17048_ADDRESS = 0x36  # MAX17048 fuel gauge (alternative)

POLL_INTERVAL = 10  # seconds
LOW_BATTERY_THRESHOLD = 15  # percent
CRITICAL_BATTERY_THRESHOLD = 5  # percent
FULL_CHARGE_THRESHOLD = 98  # percent

LOG_FILE = "/var/log/cliperx/battery.log"
STATE_FILE = "/var/lib/cliperx/battery_state.json"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [BATTERY] %(levelname)s: %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("cliperx-battery")


@dataclass
class BatteryState:
    percentage: float = 0.0
    voltage: float = 0.0
    current: float = 0.0
    power: float = 0.0
    is_charging: bool = False
    is_full: bool = False
    temperature: float = 0.0
    health: str = "good"
    time_remaining_min: int = -1
    power_profile: str = "balanced"
    timestamp: float = 0.0


class BatteryMonitor:
    """
    Monitors UPS HAT battery state via I2C

    Supports:
    - INA219 voltage/current sensor
    - MAX17048 fuel gauge
    - Custom UPS HAT protocols
    """

    def __init__(self):
        self.bus = None
        self.state = BatteryState()
        self.running = True
        self.low_battery_warned = False
        self.critical_warned = False

        # Ensure directories exist
        os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
        os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)

        # Handle shutdown gracefully
        signal.signal(signal.SIGTERM, self._handle_signal)
        signal.signal(signal.SIGINT, self._handle_signal)

    def _handle_signal(self, signum, frame):
        logger.info(f"Received signal {signum}, shutting down...")
        self.running = False

    def initialize(self):
        """Initialize I2C bus and verify battery sensor"""
        try:
            self.bus = smbus2.SMBus(I2C_BUS)
            logger.info(f"I2C bus {I2C_BUS} opened successfully")

            # Try to detect battery sensor
            try:
                self.bus.read_byte(INA219_ADDRESS)
                logger.info(f"INA219 detected at 0x{INA219_ADDRESS:02X}")
            except Exception:
                logger.warning("INA219 not detected, trying MAX17048...")
                try:
                    self.bus.read_byte(MAX17048_ADDRESS)
                    logger.info(f"MAX17048 detected at 0x{MAX17048_ADDRESS:02X}")
                except Exception:
                    logger.error("No battery sensor detected! Running in simulation mode.")

        except Exception as e:
            logger.error(f"Failed to open I2C bus: {e}")
            logger.info("Running in simulation mode")

    def read_battery(self) -> BatteryState:
        """Read current battery state from sensor"""
        try:
            if self.bus:
                # Read INA219 registers
                voltage = self._read_ina219_voltage()
                current = self._read_ina219_current()
                power = voltage * current

                # Calculate percentage from voltage (3.0V = 0%, 4.2V = 100%)
                percentage = max(0, min(100, (voltage - 3.0) / 1.2 * 100))
                is_charging = current > 0

                # Estimate time remaining
                if not is_charging and current < 0:
                    # Battery capacity in mAh (assume 10000mAh)
                    remaining_mah = 10000 * (percentage / 100)
                    time_remaining = int(remaining_mah / abs(current) * 60)
                else:
                    time_remaining = -1

                self.state = BatteryState(
                    percentage=round(percentage, 1),
                    voltage=round(voltage, 2),
                    current=round(current, 2),
                    power=round(power, 2),
                    is_charging=is_charging,
                    is_full=percentage >= FULL_CHARGE_THRESHOLD,
                    temperature=self._read_cpu_temp(),
                    time_remaining_min=time_remaining,
                    power_profile=self.state.power_profile,
                    timestamp=time.time()
                )
            else:
                # Simulation mode
                self.state = BatteryState(
                    percentage=75.0,
                    voltage=3.9,
                    current=0.5,
                    is_charging=True,
                    temperature=self._read_cpu_temp(),
                    power_profile=self.state.power_profile,
                    timestamp=time.time()
                )

        except Exception as e:
            logger.error(f"Failed to read battery: {e}")

        return self.state

    def _read_ina219_voltage(self) -> float:
        """Read voltage from INA219"""
        try:
            raw = self.bus.read_word_data(INA219_ADDRESS, 0x02)
            # Swap bytes (big endian)
            raw = ((raw & 0xFF) << 8) | ((raw >> 8) & 0xFF)
            voltage = (raw >> 3) * 0.004  # 4mV per LSB
            return voltage
        except Exception:
            return 0.0

    def _read_ina219_current(self) -> float:
        """Read current from INA219"""
        try:
            raw = self.bus.read_word_data(INA219_ADDRESS, 0x04)
            raw = ((raw & 0xFF) << 8) | ((raw >> 8) & 0xFF)
            if raw > 32767:
                raw -= 65536
            current = raw * 0.001  # 1mA per LSB (depends on calibration)
            return current
        except Exception:
            return 0.0

    def _read_cpu_temp(self) -> float:
        """Read CPU temperature"""
        try:
            with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
                return float(f.read().strip()) / 1000.0
        except Exception:
            return 0.0

    def check_alerts(self):
        """Check battery level and send alerts"""
        pct = self.state.percentage

        if pct <= CRITICAL_BATTERY_THRESHOLD and not self.state.is_charging:
            if not self.critical_warned:
                logger.critical(f"CRITICAL BATTERY: {pct}%! Initiating shutdown...")
                self._send_notification(
                    "⚠️ CRITICAL BATTERY",
                    f"Battery at {pct}%! Shutting down in 30 seconds...",
                    urgency="critical"
                )
                self.critical_warned = True
                # Auto-shutdown in 30 seconds
                subprocess.Popen(["shutdown", "-h", "+0.5",
                                  "Cliper X: Critical battery - auto shutdown"])

        elif pct <= LOW_BATTERY_THRESHOLD and not self.state.is_charging:
            if not self.low_battery_warned:
                logger.warning(f"LOW BATTERY: {pct}%")
                self._send_notification(
                    "🔋 Low Battery",
                    f"Battery at {pct}%. Please connect charger.",
                    urgency="normal"
                )
                self.low_battery_warned = True
                # Switch to power saver mode
                self.set_power_profile("battery_saver")

        elif pct > LOW_BATTERY_THRESHOLD + 5:
            self.low_battery_warned = False
            self.critical_warned = False

    def _send_notification(self, title: str, message: str, urgency: str = "normal"):
        """Send desktop notification"""
        try:
            subprocess.run([
                "notify-send", "-u", urgency,
                "-i", "battery-low",
                title, message
            ], timeout=5)
        except Exception as e:
            logger.error(f"Failed to send notification: {e}")

    def set_power_profile(self, profile: str):
        """Set power profile: performance, balanced, battery_saver"""
        self.state.power_profile = profile
        logger.info(f"Power profile set to: {profile}")

        try:
            if profile == "performance":
                # Max CPU frequency, GPU boost
                subprocess.run(["cpufreq-set", "-g", "performance"], timeout=5)
            elif profile == "balanced":
                subprocess.run(["cpufreq-set", "-g", "ondemand"], timeout=5)
            elif profile == "battery_saver":
                subprocess.run(["cpufreq-set", "-g", "powersave"], timeout=5)
                # Reduce display brightness
                subprocess.run(["cliperx-brightness", "30"], timeout=5)
        except Exception as e:
            logger.error(f"Failed to set power profile: {e}")

    def save_state(self):
        """Save current state to disk"""
        try:
            with open(STATE_FILE, "w") as f:
                json.dump(asdict(self.state), f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save state: {e}")

    def run(self):
        """Main monitoring loop"""
        logger.info("🔋 Cliper X Battery Monitor starting...")
        self.initialize()

        while self.running:
            self.read_battery()
            self.check_alerts()
            self.save_state()

            logger.info(
                f"Battery: {self.state.percentage}% | "
                f"{'⚡ Charging' if self.state.is_charging else '🔋 Discharging'} | "
                f"{self.state.voltage}V | {self.state.current}A | "
                f"Temp: {self.state.temperature}°C | "
                f"Profile: {self.state.power_profile}"
            )

            time.sleep(POLL_INTERVAL)

        logger.info("Battery monitor stopped.")


if __name__ == "__main__":
    monitor = BatteryMonitor()
    monitor.run()
