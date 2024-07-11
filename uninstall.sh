#!/usr/bin/env bash
echo "Uninstaller for openwrt image builder"
if [ -e "installer_files/nix-installer" ]; then
    read -p "Do you want to uninstall nix? (y/n): " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]
    then
        echo "Uninstalling nix"
        installer_files/nix-installer uninstall
    fi
fi
