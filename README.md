# 🚀 Custom OpenWRT x86 Image Build & VM Conversion Script (using nix)

### A simplfied approach to creating custom OpenWRT firmware images:
- Manage your own list(s) of OpenWRT packages to install
- Optionally resize default embedded partitions to unlock extra filesystem storage
- Optionally convert new OpenWRT builds into into QEMU, Virtualbox, HyperV or VMware virtual machine images
- Automated installation of all Linux dependencies required to build OpenWRT images using the nix package manager

#### ⚙️ Script Option Prompts

1. Enter your preferred OpenWRT release version (or hit enter for latest snapshot version)
2. Modify partition sizes or keep OpenWRT defaults? [y/n] (Y = follow the prompt's instructions for paritition resize)
3. Enter an image filename tag (to help uniquely identify your new build image)
4. **Optional**: Convert OpenWRT builds into virtual machine images? [y/n] (Y = select a VM disk format: qcow2, qed, vdi, vhdx or vmdk)
5. **Optional**: Copy your custom OpenWRT config files into the build tree to permanently bake these into the new image
   
   ![image](https://github.com/itiligent/OpenWRT-ImageBuilder/assets/94789708/2f3ff65a-1195-4fd1-bf32-44852cb82acd)

6. When the script completes, your new set of build images is located at `$(pwd)/openwrt_build_output/firmware_images`, and their corresponding converted VM images at `$(pwd)/openwrt_build_output/vm`.

## 🛠️ Prerequisites

Any recent x86 linux should work fine. 
Installer looks for the nix package manager. If it doesn't find it, it asks you if you want to install it.
Dependencies are subsequently installed using nix.
Windows subsystem for Linux users have a few more steps: https://openwrt.org/docs/guide-developer/toolchain/wsl

## 📖 Instructions


1. 📥 Clone the git repo then run the install script:
   ```
   ./install.sh
   ```
   this will create the `buildimage` script

2. 🛠️ Customize your package list in the `packages.txt` file. The included list of packages are examples and can be removed. Ensure each package is compatible with your OpenWRT build target & doesn't conflict with others. *(Search https://openwrt.org/packages/start for your desired package names or use the OpenWRT online firmware selector to check for any package conflicts.)*

3. (ADVANCED) - target platform and architecture can be changed by editing the `target.txt` file 

4. ▶️ Run the `buildimage` script and follow the setup prompts:
   ```
   ./buildimage
   ```


## 📂 Persistent filesystem expansion WITHOUT resizing partitions

It is possible to combine default SquashFS with a third **persistent** EXT4 data partition that won't be wiped by future sysupgrades.

1. After image flash or vm launch, simply create a new EXT4 partition and add its new PART-UUID details into the OpenWRT /etc/fstab file.
2. Next, re-run the script and add the new fstab file (along with any other custom files) to `$(pwd)/openwrt_inject_files` when prompted.
3. Reflash or relaunch your system with the new fstab build. Now the EXT4 partition's location and details are permanently baked into the build.

## ⚠️ Notes

- **Note 1:** Unless expert, this script should only be used with x86 builds. Do not attempt to resize partitions of firmware images intended for specific router models with NAND flash memory.
- **Note 2:** Images with modified default partition sizes may have issues with online attended sysupgrades. Resized paritions may require manual re-flashing with upgraded images created with the same resized settings.

