# Windows Virtual Machine

How to create a Windows virtual machine:

1. Copy `ryan-windows-11.yaml` to another file, e.g. `windows-11-test.yaml`.
2. Modify the `metadata.name` field in the new file.
3. Commit and push the changes, wait for fluxcd to apply the changes.
4. Run `kubectl get vmi -n vms` to check the status of the VM.
5. Run `virtctl vnc -n vms <vmi-name>` to connect to the VM's console.
    1. You need to have `virtctl` and `virt-viewer` pre-installed.
6. In the UEFI's boot menu, select the CD-ROM to boot from the Windows installation ISO.
7. Windows will complain about the lack of drivers, we need to install the VirtIO drivers.
   1. The VirtIO drivers are already mounted as a CD-ROM in the VM.
   2. Click on "Load driver" and select the VirtIO CD-ROM, select the appropriate driver folder(e.g. `amd64/win10`).
   3. Install on the drivers Windows Setup has found.
   4. After the drivers are installed, Windows will detect the disk and you can proceed with the installation.
8. After the installation is complete
   1. Adjust your vm's boot order to boot from the root disk, and remove the Windows installation ISO & VirtIO drivers CD-ROM.


