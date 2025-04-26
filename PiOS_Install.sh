#!/bin/bash

# Raspberry Pi OS Installation Script
# This script installs Raspberry Pi OS on an SD card using Raspberry Pi Imager.

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (use sudo)"
  exit 1
fi

# Update and install Raspberry Pi Imager
echo "Updating system and installing Raspberry Pi Imager..."
apt update && apt upgrade -y
apt install -y rpi-imager

# List available storage devices
echo "Available storage devices:"
lsblk

# Prompt user to select the target device
echo "Enter the device name (e.g., /dev/sdX) for the SD card:"
read TARGET_DEVICE

# Confirm the target device
echo "You selected $TARGET_DEVICE. All data on this device will be erased. Continue? (y/n)"
read CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "Installation canceled."
  exit 1
fi

# Launch Raspberry Pi Imager
echo "Launching Raspberry Pi Imager..."
rpi-imager

# Notify user to complete the process in the GUI
echo "Please use the Raspberry Pi Imager GUI to select the OS and write it to $TARGET_DEVICE."
echo "Once done, safely eject the SD card and insert it into your Raspberry Pi."

echo "Script completed."