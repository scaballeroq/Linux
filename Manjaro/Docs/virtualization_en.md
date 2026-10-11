---
sidebar_position: 7
---

# High-Performance Virtualization (KVM/QEMU) on Manjaro Linux

This guide details the virtualization setup automated in [`Virtualizacion/virtualization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/ManjaroTesting/Virtualizacion/virtualization.sh).

---

## 1. Key Features

- **Nested Virtualization**: `nested=1` for Intel & AMD CPUs.
- **Kernel Acceleration**: `vhost_net` and `vhost_vsock` kernel modules.
- **Nftables Firewall Backend**: `firewall_backend = "nftables"` in `/etc/libvirt/network.conf`.
- **Windows VirtIO Drivers**: Auto-download of Fedora `virtio-win.iso`.
- **Tuned Profile**: `virtual-host` performance governor.
- **Polkit Integration**: Passwordless VM management for `libvirt` group users.

```bash
./Virtualizacion/virtualization.sh
# Or using just:
just virtualization
```
