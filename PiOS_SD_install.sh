#!/bin/bash

# Raspberry Pi OS Installation Script
# This script is meant to be run from an SD card. It makes a copy of the script on the user's home directory
# and then runs the script from there, so the user can re-use the SD card for the OS.

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (use sudo)"
  exit 1
fi

# Check if the script is running from an external device (e.g., SD card)
SCRIPT_PATH=$(realpath "$0")
TARGET_DIR="$HOME/PiOS_Installer"

if [[ "$SCRIPT_PATH" != "$TARGET_DIR/PiOS_Install.sh" ]]; then
  echo "Copying script to $TARGET_DIR..."
  mkdir -p "$TARGET_DIR"
  cp "$SCRIPT_PATH" "$TARGET_DIR/PiOS_Install.sh"
  echo "Running the script from $TARGET_DIR..."
  sudo bash "$TARGET_DIR/PiOS_Install.sh"
  exit 0
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