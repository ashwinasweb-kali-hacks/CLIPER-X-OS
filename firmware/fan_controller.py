#!/usr/bin/env python3
"""
Cliper X OS — Active Cooling Fan Controller
PWM fan speed control based on CPU temperature for Raspberry Pi 5

Temperature Zones:
- < 45°C: Fan OFF (silent)
- 45-55°C: Low speed (25%)
- 55-65°C: Medium speed (50%)
- 65-75°C: High speed (75%)
- > 75°C: Maximum speed (100%)

Uses GPIO PWM for variable fan speed control.
"""

import time
import logging
import signal
import sys
import os

try:
    import RPi.GPIO as GPIO
except ImportError:
    # Mock GPIO for development
    class MockGPIO:
        BCM = "BCM"
        OUT = "OUT"
        def setmode(self, mode): pass
        def setup(self, pin, mode): pass
        def cleanup(self): pass
        class PWM:
            def __init__(self, pin, freq):
                self.pin = pin
                self.freq = freq
            def start(self, dc): pass
            def ChangeDutyCycle(self, dc): pass
            def stop(self): pass
    GPIO = MockGPIO()

# Configuration
FAN_PIN = 14  # GPIO pin for fan PWM
PWM_FREQ = 25000  # 25kHz PWM frequency

TEMP_ZONES = [
    (45, 0),    # Below 45°C → fan off
    (55, 25),   # 45-55°C → 25% speed
    (65, 50),   # 55-65°C → 50% speed
    (75, 75),   # 65-75°C → 75% speed
    (100, 100), # Above 75°C → 100% speed
]

POLL_INTERVAL = 5  # seconds
HYSTERESIS = 3     # °C hysteresis to prevent rapid switching

LOG_FILE = "/var/log/cliperx/fan.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [FAN] %(levelname)s: %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("cliperx-fan")


class FanController:
    """PWM fan speed controller with temperature-based zones"""

    def __init__(self):
        self.running = True
        self.fan_pwm = None
        self.current_speed = 0
        self.current_temp = 0
        self.last_zone = -1

        os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
        signal.signal(signal.SIGTERM, self._handle_signal)
        signal.signal(signal.SIGINT, self._handle_signal)

    def _handle_signal(self, signum, frame):
        logger.info(f"Received signal {signum}, shutting down fan controller...")
        self.running = False

    def initialize(self):
        """Initialize GPIO and PWM"""
        try:
            GPIO.setmode(GPIO.BCM)
            GPIO.setup(FAN_PIN, GPIO.OUT)
            self.fan_pwm = GPIO.PWM(FAN_PIN, PWM_FREQ)
            self.fan_pwm.start(0)
            logger.info(f"Fan controller initialized on GPIO {FAN_PIN} @ {PWM_FREQ}Hz")
        except Exception as e:
            logger.error(f"Failed to initialize GPIO: {e}")

    def read_temperature(self) -> float:
        """Read CPU temperature"""
        try:
            with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
                return float(f.read().strip()) / 1000.0
        except Exception:
            return 50.0  # Default safe temperature

    def get_fan_speed(self, temp: float) -> int:
        """Calculate fan speed based on temperature zones"""
        speed = 0
        for zone_temp, zone_speed in TEMP_ZONES:
            if temp < zone_temp:
                speed = zone_speed
                break
            speed = zone_speed
        return speed

    def set_fan_speed(self, speed: int):
        """Set fan PWM duty cycle (0-100%)"""
        speed = max(0, min(100, speed))
        if speed != self.current_speed:
            if self.fan_pwm:
                self.fan_pwm.ChangeDutyCycle(speed)
            self.current_speed = speed
            logger.info(f"Fan speed: {speed}% (temp: {self.current_temp}°C)")

    def run(self):
        """Main control loop"""
        logger.info("🌀 Cliper X Fan Controller starting...")
        self.initialize()

        while self.running:
            self.current_temp = self.read_temperature()
            target_speed = self.get_fan_speed(self.current_temp)

            # Apply hysteresis
            if abs(target_speed - self.current_speed) > 5 or target_speed == 0 or target_speed == 100:
                self.set_fan_speed(target_speed)

            time.sleep(POLL_INTERVAL)

        # Cleanup
        logger.info("Stopping fan...")
        if self.fan_pwm:
            self.fan_pwm.ChangeDutyCycle(0)
            self.fan_pwm.stop()
        GPIO.cleanup()
        logger.info("Fan controller stopped.")


if __name__ == "__main__":
    controller = FanController()
    controller.run()
