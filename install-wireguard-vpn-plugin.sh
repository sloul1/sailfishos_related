# Created 2026/06

# Tested on: 
# HW: Sony Xperia 10 III
# OS: Sailfish OS v.5.1.0.11 (Pispala)
# (Android 13 as base before installing SFOS)

 
# This script was created for enabling Mullvad VPN configuration
# on Sailfish OS v.5.1.0.11 (Pispala)
# The code functionality is copied from the SFOS Wiki:
# https://sailfishos.wiki/books/network/page/installing-wireguard 

#!/bin/bash

devel-su pkcon remove wireguard-go wireguard-tools  # for those whom previously installed those two packages in a previous setup or attempt
devel-su pkcon install jolla-settings-networking-plugin-vpn-wireguard  # adds Wireguard among the proposed VPN in the settings
devel-su systemctl restart connman  # restart the connexion manager to load the new Wireguard plugin