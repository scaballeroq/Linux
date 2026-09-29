---
sidebar_position: 7
---

# High-Performance Virtualization Environment (KVM/QEMU) on Debian Testing

This guide details the installation, configuration, and optimization of the high-performance virtualization environment implemented in [`Virtualizacion/virtualization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebianTesting/Virtualizacion/virtualization.sh).

The setup leverages the **KVM** hypervisor and **QEMU** emulator, native **PipeWire** audio passthrough, **KDE Plasma 6 (Wayland)** desktop integration, **VirGL** 3D hardware acceleration, **VirtioFS** ultra-fast shared folders, socket zero-copy **`vhost_net`** and **`vhost_vsock`**, **Btrfs NoCoW** virtual disk storage, Libvirt modular daemons, and nested virtualization.

---

## 1. Installation and Diagnostics (`virtualization.sh`)

Check system state or run automated setup:

```bash
# Full diagnostics without making modifications
just virtualization-status
# or ./Virtualizacion/virtualization.sh --status

# Full installation and provisioning
just virtualization
# or ./Virtualizacion/virtualization.sh

# Installation with Windows VirtIO drivers ISO download
./Virtualizacion/virtualization.sh --with-windows
```

Included packages:
- `qemu-system-x86`, `qemu-utils`, `libvirt-daemon-system`, `libvirt-clients`, `virt-manager`, `virt-viewer`, `virt-top`, `virtinst`.
- `libvirglrenderer1`, `virtiofsd`: GPU 3D acceleration and high-speed shared folders.
- `spice-vdagent`, `usbredir`: Seamless clipboard sync, dynamic display resize, and USB redirection.
- `swtpm`, `ovmf`: TPM 2.0 emulation and UEFI SecureBoot firmware.
- `libosinfo-1.0-0`, `guestfs-tools`: Guest OS detection and provisioning.
- `tuned`, `acl`, `dnsmasq-base`, `bridge-utils`, `iptables`, `nftables`.

---

## 2. Processor Acceleration and Nested Virtualization

1. **Nested KVM and Hardware Acceleration**:
   - **AMD Ryzen**: `/etc/modprobe.d/kvm_amd.conf` -> `options kvm_amd nested=1 avic=1 npt=1` (enables AVIC and Nested Page Tables).
   - **Intel Core**: `/etc/modprobe.d/kvm_intel.conf` -> `options kvm_intel nested=1 ept=1 vpid=1 pml=1` (enables EPT, VPID, and PML).
2. **Kernel Socket Zero-Copy Acceleration**:
   - Loads `vhost_net`, `vhost_vsock`, and `tun` in `/etc/modules-load.d/kvm-vhost.conf`.

---

## 3. Native PipeWire Audio Integration (`/etc/libvirt/qemu.conf`)

Enables guest VMs to talk directly to your desktop PipeWire daemon with zero latency:

```ini
user = "your_username"
group = "kvm"
dynamic_ownership = 1
```

---

## 4. Network and Firewall Backend

`virbr0` is assigned to the `trusted` firewall zone with masquerading and IP forwarding enabled for guest internet access.

---

## 5. Polkit Rule for KDE Plasma 6

Bypasses password prompts in Virt-Manager for members of the `libvirt` group:

```javascript
/* /etc/polkit-1/rules.d/80-libvirt.rules */
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
```

---

## 6. Storage with Btrfs NoCoW (+C)

Disables Copy-on-Write for VM disk images to avoid fragmentation on Btrfs:

```bash
sudo mkdir -p /var/lib/libvirt/images
sudo chattr +C /var/lib/libvirt/images 2>/dev/null || true
```

---

## 7. User Permissions and Groups (`libvirt`, `kvm`, `render`)

```bash
sudo usermod -aG libvirt,kvm,render $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

Environment variable registered in `~/.config/environment.d/10-libvirt.conf` and `~/.bashrc.d/environment.sh`:
```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---

## 8. Verification and VM Best Practices

- **Diagnostics**: `just virtualization-status`
- **CPU**: Select `host-passthrough` model.
- **Graphics**: Local SPICE + OpenGL + Video `VirtIO` with 3D acceleration (VirGL).
- **Disk**: VirtIO SCSI with `writeback` cache, `io_uring` IO mode, and `unmap` discard.
- **Shared Folders**: `virtiofs` backed by `virtiofsd`.
