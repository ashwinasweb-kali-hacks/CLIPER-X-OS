#!/bin/bash
# Cliper X OS — Display Brightness Control
# For 7" IPS touchscreen on Raspberry Pi 5

BRIGHTNESS_FILE="/sys/class/backlight/rpi_backlight/brightness"
MAX_BRIGHTNESS_FILE="/sys/class/backlight/rpi_backlight/max_brightness"

if [ ! -f "$BRIGHTNESS_FILE" ]; then
    # Try alternative backlight path
    BRIGHTNESS_FILE="/sys/class/backlight/10-0045/brightness"
    MAX_BRIGHTNESS_FILE="/sys/class/backlight/10-0045/max_brightness"
fi

if [ ! -f "$BRIGHTNESS_FILE" ]; then
    echo "Error: No backlight device found"
    exit 1
fi

MAX_BRIGHTNESS=$(cat "$MAX_BRIGHTNESS_FILE" 2>/dev/null || echo 255)
CURRENT=$(cat "$BRIGHTNESS_FILE" 2>/dev/null || echo 128)
STEP=$((MAX_BRIGHTNESS / 10))

case "${1:-}" in
    up)
        NEW=$((CURRENT + STEP))
        [ $NEW -gt $MAX_BRIGHTNESS ] && NEW=$MAX_BRIGHTNESS
        echo $NEW > "$BRIGHTNESS_FILE"
        echo "Brightness: $NEW / $MAX_BRIGHTNESS"
        ;;
    down)
        NEW=$((CURRENT - STEP))
        [ $NEW -lt 10 ] && NEW=10
        echo $NEW > "$BRIGHTNESS_FILE"
        echo "Brightness: $NEW / $MAX_BRIGHTNESS"
        ;;
    [0-9]|[0-9][0-9]|100)
        # Set percentage
        NEW=$(($1 * MAX_BRIGHTNESS / 100))
        [ $NEW -lt 10 ] && NEW=10
        echo $NEW > "$BRIGHTNESS_FILE"
        echo "Brightness: $1% ($NEW / $MAX_BRIGHTNESS)"
        ;;
    status)
        PCT=$((CURRENT * 100 / MAX_BRIGHTNESS))
        echo "Brightness: ${PCT}% ($CURRENT / $MAX_BRIGHTNESS)"
        ;;
    *)
        echo "Usage: cliperx-brightness {up|down|0-100|status}"
        exit 1
        ;;
esac
