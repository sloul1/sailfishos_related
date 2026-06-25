# Created 2026/06

# Tested on: 
# HW: Sony Xperia 10 III
# OS: Sailfish OS v.5.1.0.11 (Pispala)
# (Android 13 as base before installing SFOS)

 
# This script was created for enabling Mullvad VPN configuration
# on Sailfish OS v.5.1.0.11 (Pispala)
# The code functionality is copied from the SFOS Wiki:
# https://sailfishos.wiki/books/network/page/installing-wireguard 

##!/bin/bash

# Packages to potentially remove
PACKAGES_TO_REMOVE=("wireguard-go" "wireguard-tools")
# Flag to track if the plugin was successfully installed
PLUGIN_SUCCESS=false

# --- 1. Uninstall existing packages (Wireguard Go and Tools) ---
echo "=================================================="
echo "Checking for and removing conflicting VPN packages..."
echo "=================================================="

# Loop through the list of packages
for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    # Check if the package is installed
    if pkcon list | grep -q "$pkg"; then
        echo "--> Found $pkg. Attempting removal..."
        # Execute the removal command for the current package
        devel-su pkcon remove "$pkg"
    else
        echo "--> $pkg not found. Skipping removal."
    fi
done
echo "Removal process complete."

# --- 2. Install the required plugin ---

PLUGIN_NAME="jolla-settings-networking-plugin-vpn-wireguard"
echo ""
echo "=================================================="
echo "Attempting to install plugin: $PLUGIN_NAME"
echo "=================================================="

# Check if the plugin exists and is available in the repository
if pkcon search "$PLUGIN_NAME" > /dev/null 2>&1; then
    # Attempt installation
    if devel-su pkcon install "$PLUGIN_NAME"; then
        echo "--> Successfully installed $PLUGIN_NAME."
        PLUGIN_SUCCESS=true # Set the success flag
    else
        echo "--> ERROR: Failed to install $PLUGIN_NAME. Check logs."
        PLUGIN_SUCCESS=false
    fi
else
    echo "WARNING: Plugin $PLUGIN_NAME not found or not available. Skipping installation."
    PLUGIN_SUCCESS=false
fi


# --- 3. Finalization ---

# Check the success flag before restarting connman
if $PLUGIN_SUCCESS; then
    echo ""
    echo "=================================================="
    echo "Plugin installed successfully. Restarting connman..."
    echo "=================================================="
    devel-su systemctl restart connman
else
    echo ""
    echo "=================================================="
    echo "Skipping connman restart because the plugin was not installed or setup failed."
    echo "=================================================="
fi

echo "Script execution finished."