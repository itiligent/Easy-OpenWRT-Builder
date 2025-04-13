# 🚀 Custom OpenWRT Image Build & VM Conversion Script

## A repeatable approach to custom OpenWRT image creation:
- Manage & track your OpenWRT build recipes
- Optionally resize default partitions to unlock extra root filesystem storage
- Optionally convert OpenWRT images into into QEMU, Virtualbox, HyperV or VMware images
- Automatic installation of OpenWRT Imagebuilder dependencies

---

## ⚙️ Script Option Prompts

1. Enter OpenWRT STABLE release version, or hit enter for latest snapshot
2. Modify partition sizes or keep OpenWRT defaults? [y/n] _(Y = follow the prompts)_
3. Enter an image filename tag _(to uniquely identify your new image)_
4. **Optional**: Convert OpenWRT images to VM disk image? [y/n] _(Y = select a VM format: qcow2, qed, vdi, vhdx or vmdk)_
5. **Optional**: Bake a custom OpenWRT config into new OpenWRT images? _(follow the prompts)_
6. When the script completes new images are located at:
    - New Firmware Images: `$(pwd)/openwrt_build_output/firmware_images`
    - Virtual Machine Images:`$(pwd)/openwrt_build_output/vm`

      
   ![image](https://github.com/itiligent/Easy-OpenWRT-Builder/blob/main/Screenshot.png)



---

## 🛠️ Prerequisites

**Any recent x86 Debian-flavored OS with the sudo package installed should be fine**. 
- All image building dependencies are automatically installed on first run.
- If building old OpenWRT versions (< = 19.x), using a Linux distro from the same era will save you some troubles with older Python build machine prerequisities.
- Windows subsystem for Linux users have additional steps. See below WSL section 
---

## 📖 Instructions

1. 📥 Download the image builder script and make it executable:
   ```
   chmod +x x86-imagebuilder.sh
   ```

2. 🛠️ Customise your package recipie in the `CUSTOM_PACKAGES` section at the top of the script.
   - The included default packages are examples only and can be changed.
   - If you have issues with your build, check screen output for package selection errors or conflicts.

4. ▶️ Run the script **without** sudo (it will prompt for sudo) and follow the prompts:
   ```
   ./x86-imagebuilder.sh
   ```
5. **VMware ESXi VM users only**: Please see [here](https://github.com/itiligent/Easy-OpenWRT-Builder/blob/main/OWRT-ON-ESXi.md) for final ESXi VM conversion steps.

---

## 📂 Persistent filesystem expansion WITHOUT resizing partitions

It is possible to add a large **persistent** EXT4 data partition that, unike any resized partitions, won't be wiped by a reset or sysupgrade.

1. Add a usb drive (or vdisk) with an EXT4 partition and mount this with:
   ```
   block detect | uci import fstab
   uci set fstab.@mount[-1].enabled='1'
   uci commit fstab
   reboot
   ```
Alternately, in Luci see http://your-routername/cgi-bin/luci/admin/system/mounts to mount the new disk via gui.
   
2. From OpenWRT, copy the (now updated) `/etc/fstab file`
3. Re-run the build script, this time adding the copied `/etc/fstab` file to `$(pwd)/openwrt_inject_files` when prompted.
   - The updated fstab file referencing the extra EXT4 partition will now be baked into the new build, making this storage persistent after a reset or sysupgrade.
4. Update to this new build

## 🌐 Sysupgrades with x86
   -  **OpenWRT 23.x and below**: If resizing partitions, attended sysupgrade returns the default partition schema - which will likely be a bad thing! Instead, for x86 upgrades you must recreate a new image and re-flash.
   - **OpenWRT Version 24.x onwards**: Supports attended sysupgrade with a resized root partitions up to 1024mb (with a few extra config settings).

---

## 🛠️ Windows Subsystem for Linux Users: (tested WSL Debian 12).
1. OpenWRT Imagebuilder needs a CASE SENSITIVE filesysyem
    - From within Windows, create a new working directory for the script (eg. C:\users\\%username%\OWRT)
    - From powershell `fsutil.exe file setCaseSensitiveInfo "C:\users\%username%\OWRT" enable`
2. Remove Windows paths from Debian $PATH (spaces in paths breaks things) 
```
sudo tee -a /etc/wsl.conf << EOF > /dev/null
[interop]
appendWindowsPath = false
EOF
exit
```
3. Shutdown Debian `wsl --shutdown`
4. Restart Debian `wsl -d Debian`
5. From Windows or Debian, copy/save the build script `x86-imagebuilder.sh` to the newly created working dir above
6. In Debian, change to the new working dir and make the script executable `chmod +x x86-imagebuilder.sh`
7. From the new working dir in Debian, run the script with `./x86-imagebuilder.sh`
   See here for more about OpenWRT Imagebuilder & WSL: https://openwrt.org/docs/guide-developer/toolchain/wsl


## ⚠️ WARNING: Resize of OpenWRT partitions on flash memory devices
- **For OpenWRT experts only**:
    - Partition resize is for x86 builds. (You’ll need to manually edit the script for other architectures).
    - Know what you are doing (use this script at your own risk).
    - Resizing firmware partitions on router flash will likely **brick your device!!**
    - Have a plan to unbrick before proceeding.

      
