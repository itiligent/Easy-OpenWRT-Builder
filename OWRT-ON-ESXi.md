### "Unsupported or invalid disk type 2" fix:
Qemu converted images will not boot in later versions of Esxi as qemu coverversions use the **VMware Workstation disk format**.
This problem is easily fixed from the ESXi CLI:

1. Create your ESXi OWRT VM as "Other 5.x Linux (64-bit)"
2. Upload the converted vmdk image to the OWRT VM's ESXi directory and run:
`vmkfstools -i source.vmdk destintation.vmdk`
3. Point your new OWRT vm to `destintation.vmdk`. Make sure to use a SCSI or SAS disk controller.
4. Finish any other VM configs you need and boot. If you still can't boot, check secure boot settings on the VM are disabled.

### OWRT and thin provisioning
Qemu does not support coversion to thin vmdk files. To create an thin OWRT image on ESXi you will need to **dd** copy the contents of the raw image to an existing thin provisioned OS boot disk. See this tutotial https://www.youtube.com/watch?v=gJoTYxk-EYU
