#!/bin/bash

# Pi-hole Installation and Configuration Script
# This script installs Pi-hole on a Raspberry Pi running Raspberry Pi OS,
# configures it, adds custom blocklists, and optionally sets a static IP address.

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (use sudo)"
  exit 1
fi

# Update the system
echo "Updating the system..."
apt update && apt upgrade -y

# Install curl if not already installed
echo "Installing curl (required for Pi-hole installation)..."
apt install -y curl

# Ask the user if they want to configure a static IP address
echo "Do you want to configure a static IP address for your Raspberry Pi? (y/n)"
read CONFIGURE_STATIC_IP
if [[ "$CONFIGURE_STATIC_IP" == "y" ]]; then
  # Detect current network settings
  INTERFACE=$(ip route | grep default | awk '{print $5}')
  CURRENT_IP=$(hostname -I | awk '{print $1}')
  SUBNET_MASK=$(ifconfig "$INTERFACE" | grep -w "inet" | awk '{print $4}')
  GATEWAY=$(ip route | grep default | awk '{print $3}')
  DNS_SERVER=$(cat /etc/resolv.conf | grep "nameserver" | awk '{print $2}' | head -n 1)

  echo "Detected network settings:"
  echo "Interface: $INTERFACE"
  echo "IP Address: $CURRENT_IP"
  echo "Subnet Mask: $SUBNET_MASK"
  echo "Gateway: $GATEWAY"
  echo "DNS Server: $DNS_SERVER"

  # Confirm with the user before applying the static IP configuration
  echo "Do you want to use these settings to configure a static IP? (y/n)"
  read CONFIRM_STATIC_IP
  if [[ "$CONFIRM_STATIC_IP" == "y" ]]; then
    # Backup the current dhcpcd.conf file
    cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak

    # Write the static IP configuration to dhcpcd.conf
    cat <<EOF >> /etc/dhcpcd.conf

# Static IP configuration for Pi-hole
interface $INTERFACE
static ip_address=$CURRENT_IP/24
static routers=$GATEWAY
static domain_name_servers=$DNS_SERVER
EOF

    echo "Static IP configuration added to /etc/dhcpcd.conf."
    echo "Restarting the DHCP service to apply changes..."
    systemctl restart dhcpcd
    echo "Static IP configuration complete. Your Raspberry Pi will now use $CURRENT_IP."
  else
    echo "Static IP configuration skipped."
  fi
else
  echo "Static IP configuration skipped."
fi

# Download and run the Pi-hole installation script
echo "Downloading and running the Pi-hole installation script..."
curl -sSL https://install.pi-hole.net | bash

# Configure Pi-hole settings
echo "Configuring Pi-hole settings..."

# Add custom blocklists
echo "Adding custom blocklists..."
BLOCKLISTS=(
  "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
  "https://mirror1.malwaredomains.com/files/justdomains"
  "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
  "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
)
for BLOCKLIST in "${BLOCKLISTS[@]}"; do
  pihole -b "$BLOCKLIST"
done

# Update gravity (downloads and applies blocklists)
echo "Updating Pi-hole gravity (applying blocklists)..."
pihole -g

# Restart Pi-hole services
echo "Restarting Pi-hole services..."
pihole restartdns

# Get the Raspberry Pi's IP address
PI_IP=$(hostname -I | awk '{print $1}')

# Get the gateway IP address
GATEWAY=$(ip route | grep default | awk '{print $3}')

# Notify the user
echo "Pi-hole installation and configuration are complete!"
echo "You can access the Pi-hole admin interface by visiting http://$PI_IP/admin in your web browser."
echo "To configure your router to use Pi-hole as the DNS server:"
echo "1. Open your web browser and go to your router's settings page: http://$GATEWAY"
echo "2. Log in to your router's admin interface."
echo "3. Find the DNS server settings (usually under LAN or DHCP settings)."
echo "4. Set the DNS server to: $PI_IP"
echo "5. Save the changes and reboot your router if necessary."

echo "Script completed."