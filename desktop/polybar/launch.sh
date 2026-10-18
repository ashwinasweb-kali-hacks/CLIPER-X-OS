#!/bin/bash
# Polybar launch script for Cliper X OS

# Terminate already running bar instances
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.5; done

# Launch Cliper X bar
polybar cliperx --config=~/.config/polybar/config.ini &

echo "Polybar launched..."
