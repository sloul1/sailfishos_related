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
echo "====================================================="
echo "Checking status for plugin: $PLUGIN_NAME"
echo "====================================================="

# Check if the plugin is already installed
if local is_installed; then
    if pkg list | grep -q "$PLUGIN_NAME"; then
        is_installed=true
    else
        is_installed=false
    fi
fi

# --- Handle Installation Logic ---
if is_installed; then
    echo "NOTICE: Plugin '$PLUGIN_NAME' is already installed."
    read -r -p "Do you want to remove and reinstall it? (yes/no): " reinstall_choice
    if [[ "$reinstall_choice" == "yes" ]]; then
        # 1. Remove the existing package
        echo "Attempting to remove existing package..."
        if pkg remove "$PLUGIN_NAME"; then
            echo "Successfully removed '$PLUGIN_NAME'. Proceeding with installation."
        else
            echo "WARNING: Failed to remove existing '$PLUGIN_NAME'. Aborting reinstallation."
            is_installed=false # Treat failure as if it was never installed for the next step
        fi
    else
        echo "Skipping reinstallation based on user choice. Keeping existing version."
        is_installed=true
    fi
fi

# 2. Attempt to install or reinstall if necessary
if ! $is_installed || [[ "$reinstall_choice" == "yes" ]] && ! pkg list | grep -q "$PLUGIN_NAME"; then
    echo ""
    echo "Attempting to install/reinstall '$PLUGIN_NAME'..."
    if pkg install "$PLUGIN_NAME"; then
        echo "SUCCESS: '$PLUGIN_NAME' installed/reinstalled successfully."
    else
        echo "ERROR: Failed to install or reinstall '$PLUGIN_NAME'. Please check repository status."
        is_installed=false
    fi
else
    # If it was installed and the user chose not to remove/reinstall
    echo "Skipping package installation as requested."
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