---
sidebar_position: 6
---

# KVM/QEMU Virtualization in OpenSUSE Tumbleweed

This guide details the deployment of high-performance KVM/QEMU virtualization on **OpenSUSE Tumbleweed** with **GNOME**.

---

## 1. Architecture

- **Hypervisor**: Native KVM with nested virtualization (`nested=1`).
- **Management**: Libvirt with virt-manager, virt-viewer, and virsh.
- **Native Audio**: Virtual machine audio mapped directly to user PipeWire.
- **VirtIO Drivers**: Automated download of `virtio-win.iso` for Windows guest support.
- **Performance**: Tuned profile `virtual-host`.

---

## 2. Installation

```bash
just virtualization
```

Or execute directly:
```bash
./Virtualizacion/virtualization.sh
```
