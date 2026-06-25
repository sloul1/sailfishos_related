#!/bin/bash

# Set robust error handling
set -e

# Global Flag to track if the plugin was successfully installed
PLUGIN_SUCCESS=false

# --- 1. Uninstall existing packages (Wireguard Go and Tools) ---
PACKAGES_TO_REMOVE="wireguard-go wireguard-tools"
echo "=================================================="
echo "Checking for and removing conflicting VPN packages..."
echo "=================================================="

# Loop through the list of packages
for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    echo "--> Checking for $pkg..."
    # Use 'pkcon list' to check existence *before* attempting removal, minimizing failures.
    if devel-su pkcon list | grep -q "$pkg"; then
        echo "--> Found $pkg. Attempting removal..."
        # Use devel-su prefix for removal
        if devel-su pkcon remove "$pkg"; then
            echo "Successfully removed '$pkg'."
        else
            echo "WARNING: Could not remove '$pkg'. It might be locked or permissions failed."
        fi
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
# We rely on checking the output of pkcon list
if devel-su pkcon list | grep -q "$PLUGIN_NAME"; then
    echo "NOTICE: Plugin '$PLUGIN_NAME' is already installed."
    read -r -p "Do you want to remove and reinstall it? (yes/no): " reinstall_choice
    if [[ "$reinstall_choice" == "yes" ]]; then
        # Attempt to remove first
        echo "Attempting to remove existing package..."
        if devel-su pkcon remove "$PLUGIN_NAME"; then
            echo "Successfully removed '$PLUGIN_NAME'. Proceeding with reinstallation."
        else
            echo "WARNING: Failed to remove existing '$PLUGIN_NAME'. Aborting reinstallation."
            # Exit the reinstallation path
            is_installed=false
        fi
    else
        echo "Skipping reinstallation based on user choice. Keeping existing version."
        is_installed=true # Assume success if user chooses not to reinstall
    fi
else
    is_installed=false
fi


# 2. Attempt to install or reinstall if necessary
# This condition handles: 1) If it was never installed, OR 2) If we explicitly decided to reinstall.
if ! $is_installed || [[ "$reinstall_choice" == "yes" ]] && ! devel-su pkcon list | grep -q "$PLUGIN_NAME"; then
    echo ""
    echo "Attempting to install/reinstall '$PLUGIN_NAME'..."
    
    # Use devel-su prefix for installation
    if devel-su pkcon install "$PLUGIN_NAME"; then
        echo "SUCCESS: '$PLUGIN_NAME' installed/reinstalled successfully."
        # Crucial: Set the success flag
        PLUGIN_SUCCESS=true 
    else
        echo "ERROR: Failed to install or reinstall '$PLUGIN_NAME'. Please check repository status or package name."
        PLUGIN_SUCCESS=false
    fi
else
    # If we skipped installation, the flag remains its initial state (false, unless manually set to true earlier)
    echo "Package installation skipped."
fi

# --- 3. Finalization ---

# Check the success flag before restarting connman
if $PLUGIN_SUCCESS; then
    echo ""
    echo "=================================================="
    echo "Plugin installed successfully. Restarting connman..."
    echo "=================================================="
    # Use devel-su prefix for systemctl
    if devel-su systemctl restart connman; then
        echo "SUCCESS: ConnMan restarted successfully."
    else
        echo "WARNING: Failed to restart connman. You may need to run 'devel-su systemctl restart connman' manually."
    fi
else
    echo ""
    echo "=================================================="
    echo "Skipping connman restart because the plugin was not successfully installed or setup failed."
    echo "=================================================="
fi

echo "Script execution finished."