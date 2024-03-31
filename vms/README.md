# KubeVirt Usage

> https://kubevirt.io/user-guide/architecture/

## Basic Concepts

1. Layer 2 Network: KubeVirt supports Layer 2 network via Multus-CNI and OVS-CNI plugins.
    1. It allows VMs to be connected to the same network as the host node.
    1. CRD: `NetworkAttachmentDefinition`
1. Disks: VMs can use PVCs as disks.
    1. To do a live migration, the PVCs must be ReadWriteMany, so we use longhorn for this.

## CRDs

Virual machines:

1. `VirtualMachineInstance`: Similar to Kubernetes `Pod`, it is a running VM instance, and cannot be stopped.
1. `VirtualMachine`: Similar to a `DaemonSet` with `spec.replicas = 1`, it ensures that there is always one `VirtualMachineInstance` running, and controls its lifecycle (stop/running).

Virual machine templates(to let create VMs with the same configuration easily):

1. `VirtualMachineInstanceTemplate`: Similar to instance type in AWS(e.g. c7i.2xlarge), it defines types and size of CPU/RAM/Disk, and can be used in `VirtualMachine` via `spec.instancetype`.
    1. `VirtualMachineInstanceTemplate` is immutable, and `VirtualMachine` can only reference it and cannot override its parameters.
1. `VirtualMachinePreference`: Defines some default parameters for VMs, such as disk bus, network mode, etc, and can be used in `VirtualMachine` via `spec.preference`.
    1. `VirtualMachinePreference` is just some default values, and `VirtualMachine` can override them.


## Create VMs from qcow2 images

> https://kubevirt.io/user-guide/virtual_machines/disks_and_volumes/

By default, KubeVirt supports creating VMs from container images, the `qcow2` image must be placed in the `/disk` directory of the container image.

To avoid wrapping the `qcow2` image in a container image, we can install
[cdi](https://github.com/kubevirt/containerized-data-importer) and use it to import the `qcow2` image into a PVC.
It supports those ways to import `qcow2` images:

1. Upload your qcow2 image to a web server, and use `dataVolumeTemplates` in `VirtualMachine` to let cdi import the image automatically.
2. Use `virtctl` to upload the `qcow2` image to a PVC.
   - `virtctl image-upload --uploadproxy-url=https://cdi-uploadproxy.exam.com --pvc-name=upload-pvc --pvc-size=10Gi --image-path=./xxx.qcow2`


## CLI

```bash
# list all VMIs
kubectl get vmi -n vms

# connect to a VMI's console
virtctl console -n vms <vmi-name>
```

## VM's Snapshot, Restore, and Export

> https://kubevirt.io/user-guide/operations/snapshot_restore_api/

> https://kubevirt.io/user-guide/operations/export_api/

TODO

## LIve Migration

> https://kubevirt.io/user-guide/operations/live_migration/

TODO


## Migrate from Proxmox to KubeVirt

```bash
# 1. export and convert the proxmox VM's disk to qcow2
# qemu-img is provided by qemu.
export DISK_NAME=vm-114-disk-1
ssh root@192.168.5.172 "cat /dev/pve/${DISK_NAME} | zstd -z --stdout" | zstd -d -o ${DISK_NAME}.img
qemu-img convert -O qcow2 ${DISK_NAME}.img ${DISK_NAME}.qcow2

# 2. upload to my caddy server
rsync -avz --progress --copy-links ${DISK_NAME}.qcow2 root@rakushun:/var/lib/caddy/fileserver/vms/${DISK_NAME}.qcow2
```



