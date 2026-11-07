---
sidebar_position: 7
---

# Virtualization Environment (KVM/QEMU) in Debian GNU/Linux (GNOME Shell)

This guide details the installation, configuration, and optimization of the virtualization stack located in `Virtualizacion/`, tailored for **Debian GNU/Linux** and **GNOME Shell**.

The environment uses the **KVM** hypervisor and **QEMU** emulator, managed through **Libvirt**, providing two primary interfaces:
1. **Cockpit Web Console** (`cockpit-machines` at `https://localhost:9090`).
2. **Virt-Manager** for advanced hardware control and 3D VirGL acceleration in GNOME Shell Wayland.

---

## 1. Installation & Package Stack (`virtualization.sh`)

Installs KVM, QEMU, Virt-Manager, Cockpit Machines, UEFI/TPM utilities, and acceleration dependencies:

```bash
just virtualization
```

---

## 2. Hardware Acceleration & Nested KVM

The script detects the host CPU vendor and sets performance flags in `/etc/modprobe.d/`:
- **AMD Ryzen (`kvm_amd.conf`)**: `options kvm_amd nested=1 avic=1 npt=1`
- **Intel Core (`kvm_intel.conf`)**: `options kvm_intel nested=1 ept=1 vpid=1 pml=1`
- **Kernel Network Modules**: `vhost_net`, `vhost_vsock`, `tun` loaded automatically.

---

## 3. Storage Optimization (Btrfs NoCoW & ACLs)

- **Btrfs NoCoW (`+C`)**: If `/var/lib/libvirt/images` is on a Btrfs filesystem, `chattr +C` is applied to prevent fragmentation and maximize IOPS for `qcow2` virtual disks.
- **Access Control Lists (ACLs)**: Allows the user to manage VM disk images without requiring `sudo`.

---

## 4. Networking & Safe Wi-Fi Detection

- **Default NAT Network (`virbr0`)**: Standard virtual network protected by Firewalld (`trusted` zone and active masquerade).
- **Safe Wi-Fi Detection**: On laptops using wireless connections, bridge creation (`br0`) is intentionally skipped to prevent breaking the Wi-Fi link (802.11 standard limitation). If the active connection is wired Ethernet, `br0` is provisioned automatically.

---

## 5. Passwordless Polkit Rule

Generates `/etc/polkit-1/rules.d/50-libvirt.rules` allowing members of the `libvirt` group to start, stop, and manage VMs without password prompts.

---

## 6. Memory Deduplication (KSM)

Enables sharing identical RAM pages across virtual machines via `/etc/tmpfiles.d/ksm.conf`, balanced for laptop battery life.

---

## 7. Diagnostics with Just

```bash
# Check status of KVM hypervisor, modules, sockets, and networks
just virtualization-status
```
