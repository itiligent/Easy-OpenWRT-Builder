# 🚀 Custom OpenWRT Image Build & VM Conversion Script

### A simplfied approach to creating custom OpenWRT firmware images:
- Manage your own list(s) of OpenWRT packages
- Optionally resize default partitions to unlock extra filesystem storage
- Optionally convert OpenWRT images into into QEMU, Virtualbox, HyperV or VMware images
- Automated installation of all Linux dependencies required to build OpenWRT

#### ⚙️ Script Option Prompts

1. Enter desired OpenWRT release version (hit enter for latest snapshot)
2. Modify partition sizes or keep OpenWRT defaults? [y/n] (Y = follow the prompts)
3. Enter an image filename tag (to uniquely identify your new image)
4. **Optional**: Convert OWRT images to VM disk? [y/n] (Y = select a VM format: qcow2, qed, vdi, vhdx or vmdk)
5. **Optional**: Permanently bake custom OpenWRT config files into the new OWRT image
   
   ![image](https://github.com/itiligent/OpenWRT-ImageBuilder/assets/94789708/2f3ff65a-1195-4fd1-bf32-44852cb82acd)

6. When the script completes, new images are located at `$(pwd)/openwrt_build_output/firmware_images`, and corresponding VM images at `$(pwd)openwrt_build_output/vm`.

## 🛠️ Prerequisites

Any recent x86 Debian-flavored OS with the sudo package installed. All other image building dependencies are automatically installed on first run.
Windows subsystem for Linux users see here: https://openwrt.org/docs/guide-developer/toolchain/wsl

## 📖 Instructions


1. 📥 Download the image builder script and make it executable:
   ```
   chmod +x x86-imagebuilder.sh
   ```

2. 🛠️ Customize your package recipie in the `CUSTOM_PACKAGES` section. The included list of packages are examples and can be edited. If you have issues building, check the build output for package conflicts.


3. ▶️ Run the script **without** sudo (it will prompt for sudo) and follow the prompts:
   ```
   ./x86-imagebuilder.sh
   ```
4. VMware ESXi users see [here](https://github.com/itiligent/Easy-OpenWRT-Builder/blob/main/OWRT-ON-ESXi.md) for extra required steps.

## 📂 Persistent filesystem expansion WITHOUT resizing partitions

It is possible to add a third **persistent** EXT4 data partition that, unike resized partitions, won't be wiped by sysupgrade.

1. After image flash or vm launch, create a new EXT4 partition and add its new PART-UUID details into the /etc/fstab file.
2. Next, re-run the script, this time adding the new fstab file to `$(pwd)/openwrt_inject_files` when prompted.
3. Reflash your system with this new build. The fstab file containing the EXT4 partition details is now baked into the build and will be persistent even after a reset.

## ⚠️ WARNING

- Unless extreme expert, parition resize should only be used with x86 builds. Resize of firmware paritions intended for router NAND flash memory will 99.999% brick your device. Do this at your own risk.
- Images with modified partition sizes are not compatible with sysupgrade. Instead, use this script to create ugraded images with your current config and the same resized settings as before, then reflash.
