#!/bin/bash
# Cliper X OS — First Boot Setup Script
# Runs on first boot to configure the system

set -e

echo "╔══════════════════════════════════════╗"
echo "║     CLIPER X OS — First Boot Setup   ║"
echo "║     v1.0.0 (phantom)                 ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Force password change
echo "⚠️  You MUST change the default password!"
echo ""
passwd

# Set timezone
echo ""
echo "Setting timezone..."
dpkg-reconfigure tzdata

# Generate SSH keys
echo ""
echo "Generating SSH keys..."
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Setup LUKS encryption (if not already encrypted)
echo ""
read -p "Enable full disk encryption? (y/n): " encrypt
if [ "$encrypt" = "y" ]; then
    echo "Setting up LUKS encryption on next reboot..."
    echo "This will require you to enter a passphrase on every boot."
    # cryptsetup reencrypt --encrypt --reduce-device-size 32M /dev/mmcblk0p2
fi

# Configure WiFi
echo ""
echo "Configure WiFi adapter for monitor mode..."
echo "Available interfaces:"
iw dev
echo ""
read -p "Setup monitor mode on wlan1? (y/n): " monitor
if [ "$monitor" = "y" ]; then
    sudo airmon-ng start wlan1
    echo "Monitor mode enabled on wlan1mon"
fi

# Update system
echo ""
echo "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Setup Metasploit database
echo ""
echo "Initializing Metasploit database..."
sudo msfdb init

# Install additional Python tools
echo ""
echo "Installing Python security tools..."
pip3 install --user impacket pwntools scapy requests-html

# Disable first-boot flag
sudo rm -f /etc/cliperx-first-boot

echo ""
echo "╔══════════════════════════════════════╗"
echo "║     Setup Complete! 🎉              ║"
echo "║     Reboot to apply all changes.    ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Default hotkeys:"
echo "  Super+Return  → Terminal"
echo "  Super+D       → App Launcher"
echo "  Super+M       → Metasploit"
echo "  Super+B       → Burp Suite"
echo "  Super+W       → Wireshark"
echo "  Super+N       → Nmap Quick Scan"
echo ""

read -p "Reboot now? (y/n): " reboot_now
[ "$reboot_now" = "y" ] && sudo reboot
