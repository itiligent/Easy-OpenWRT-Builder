# 🚀 Custom OpenWRT Image Build & VM Conversion Script

## A repeatable approach to custom OpenWRT image creation:
- Manage & track your OpenWRT build recipes
- Optionally resize default partitions to unlock extra root filesystem storage
- Optionally convert OpenWRT images into into QEMU, Virtualbox, HyperV or VMware images
- Automatic installation of OpenWRT Imagebuilder dependencies

---

## ⚙️ Script Option Prompts

1. Enter OpenWRT STABLE release version _(or hit enter for latest snapshot)_
2. Modify partition sizes or keep OpenWRT defaults? [y/n] _(Y = follow the prompts)_
3. Enter an image filename tag _(to uniquely identify your new image)_
4. **Optional**: Convert OpenWRT images to VM disk image? [y/n] _(Y = select a VM format: qcow2, qed, vdi, vhdx or vmdk)_
5. **Optional**: Bake a custom OpenWRT config into new OpenWRT images? _(follow on-screen directions)_
6. When the script completes new images are located at:
    -  Native Firmware: `$(pwd)/openwrt_build_output/firmware_images`
    - Virtual Machine:`$(pwd)/openwrt_build_output/vm`

      
   ![image](https://github.com/itiligent/Easy-OpenWRT-Builder/blob/main/Screenshot.png)



---

## 🛠️ Prerequisites

**Any recent x86 Debian-flavored OS with the sudo package installed should be fine**. 
- All image building dependencies are automatically installed on first run.
- Windows subsystem for Linux users have additional steps. See here: https://openwrt.org/docs/guide-developer/toolchain/wsl
- If building old OpenWRT versions (< = 19.x), using a Linux distro from the same era will save you some troubles with older Python build machine prerequisities.

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
   -  OpenWRT Image Builder for x86 **does not support sysupgrade**.
   -  Instead, for x86 upgrades simply overwrite your virtual machine disk with a newly built vdisk image.

---

## ⚠️ WARNING: Resize of OpenWRT partitions on flash memory devices

- **Parition resize should only be used with x86 builds**.
  - Resize of firmware paritions on router hardware flash memory **will 99.99999% brick your device!!**
    
    
- **For OpenWRT experts only**:
    - Make sure you know what you are doing (you alter this script's protections and flash at your own risk).
    - Have a plan to unbrick before proceeding.
    - Understand you will no longer be able to use attended sysupgrade:
      - Attended sysupgrade returns the default partition schema (which may likely be a bad thing).
      - You must manually create all future upgrade images with the same resized partition schema via this script.

