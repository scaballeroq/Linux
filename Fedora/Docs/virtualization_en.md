---
sidebar_position: 7
---

# High-Performance Virtualization (KVM/QEMU) on Fedora 44

This guide details the virtualization setup automated in [`Virtualizacion/virtualization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/Virtualizacion/virtualization.sh).

---

## 1. Key Features

- **Nested Virtualization**: `nested=1` for Intel & AMD CPUs.
- **Kernel Acceleration**: `vhost_net` and `vhost_vsock` kernel modules.
- **Native PipeWire Audio Passthrough**: User & group configuration in `/etc/libvirt/qemu.conf`.
- **Nftables Firewall Backend**: `firewall_backend = "nftables"` in `/etc/libvirt/network.conf`.
- **Windows VirtIO Drivers**: Auto-download of Fedora `virtio-win.iso`.
- **Tuned Profile**: `virtual-host` performance governor.

```bash
./Virtualizacion/virtualization.sh
# Or using just:
just virtualization
```
