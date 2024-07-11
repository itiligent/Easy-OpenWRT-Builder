#!/usr/bin/env bash

pushd installer_files || exit
# Check if nix is installed
if ! command -v nix &> /dev/null
then
    echo "The nix package manager is not installed."
    read -p "Do you want to install nix? (y/n): " answer

    if [[ "$answer" == "y" || "$answer" == "Y" ]]
    then
        echo "Installing nix"
        curl -sL -o nix-installer https://install.determinate.systems/nix/nix-installer-x86_64-linux
        chmod +x nix-installer
        ./nix-installer install
        echo "Nix installed!"
    else
        echo "Unable to proceed."
        popd
        exit
    fi
fi
echo "Installing openwrt image builder ..."
nix build
popd
rm -f buildimage
ln -s "$(readlink installer_files/result)/bin/my-script" buildimage
echo "Files installed!"
echo "Now run ./buildimage everytime you want to (re)build an openwrt image."
