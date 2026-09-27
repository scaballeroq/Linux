---
sidebar_position: 7
---

# High-Performance Virtualization (KVM/QEMU) on openSUSE Tumbleweed

This guide covers the installation, setup, and optimization of the high-performance virtualization environment implemented in [`Virtualizacion/virtualization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Virtualizacion/virtualization.sh) and documented in [`Virtualizacion/notas_virtualizacion_opensuse.md`](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Virtualizacion/notas_virtualizacion_opensuse.md).

The architecture uses **KVM** and **QEMU**, with native **PipeWire** audio passthrough, **KDE Plasma 6 (Wayland)** desktop integration, **VirGL** 3D acceleration, **VirtioFS** ultra-fast folder sharing, kernel-level socket acceleration via **`vhost_net`** and **`vhost_vsock`**, **Btrfs NoCoW** image storage, modular Libvirt daemons, and nested virtualization.

---

## 1. Installation & Diagnostics (`virtualization.sh`)

Check system capabilities or run the full setup:

```bash
# Complete diagnostic without making changes
just virtualization-status
# or ./Virtualizacion/virtualization.sh --status

# Full provisioning and optimization
just virtualization
# or ./Virtualizacion/virtualization.sh

# Install with Windows VirtIO drivers download
./Virtualizacion/virtualization.sh --with-windows
```

Included packages:
- `qemu-kvm`, `qemu-tools`, `libvirt`, `libvirt-daemon-driver-qemu`, `libvirt-client`, `virt-manager`, `virt-viewer`, `virt-top`, `virt-install`.
- `virglrenderer`, `virtiofsd`: GPU 3D acceleration and high-performance shared filesystems.
- `spice-vdagent`, `usbredir`: Seamless clipboard sharing, dynamic display resolution, and USB redirection.
- `swtpm`, `ovmf`: TPM 2.0 emulation and UEFI SecureBoot firmware.
- `libosinfo`, `guestfs-tools`: Operating system detection and optimal hardware profiles.
- `tuned`, `acl`, `dnsmasq`, `bridge-utils`, `iptables`, `nftables`.

---

## 2. Processor Acceleration & Nested KVM

1. **Nested Virtualization & Hardware Acceleration**:
   - **AMD Ryzen**: `/etc/modprobe.d/kvm_amd.conf` -> `options kvm_amd nested=1 avic=1 npt=1`
     - Enables AMD AVIC (*Advanced Virtual Interrupt Controller*) and NPT (*Nested Page Tables*).
   - **Intel Core**: `/etc/modprobe.d/kvm_intel.conf` -> `options kvm_intel nested=1 ept=1 vpid=1 pml=1`
     - Enables Intel EPT (*Extended Page Tables*), VPID, and PML.
2. **Network Acceleration & Kernel Sockets**:
   - Loads `vhost_net`, `vhost_vsock`, and `tun` via `/etc/modules-load.d/kvm-vhost.conf` for zero-copy host-guest communication.

---

## 3. Native PipeWire Audio Passthrough (`/etc/libvirt/qemu.conf`)

Allows QEMU virtual machines to interact directly with the user's desktop PipeWire server in KDE Plasma without latency:

```ini
user = "your_user"
group = "kvm"
dynamic_ownership = 1
```

---

## 4. Firewall Backend & Firewalld

- In `/etc/libvirt/network.conf`:
  ```ini
  firewall_backend = "iptables"
  ```
- In Firewalld:
  Virtual interface `virbr0` is placed in zone `libvirt` with forwarding enabled (`--add-forward`), and `masquerade` is enabled on the default network zone.

---

## 5. Polkit Rule for KDE Plasma 6

Prevents repeated root password prompts when managing virtual machines in Virt-Manager:

```javascript
/* /etc/polkit-1/rules.d/50-libvirt.rules */
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
```

---

## 6. Libvirt Modular Sockets

Libvirt operates via on-demand socket activation:

```bash
sudo systemctl enable --now \
    virtqemud.socket \
    virtnetworkd.socket \
    virtstoraged.socket \
    virtnodedevd.socket \
    virtnwfilterd.socket \
    virtsecretd.socket \
    virtproxyd.socket
```

---

## 7. Storage with Btrfs NoCoW (+C)

On openSUSE Tumbleweed with Btrfs, the `+C` attribute is set on `/var/lib/libvirt/images` to disable Copy-on-Write and prevent disk fragmentation:

```bash
sudo mkdir -p /var/lib/libvirt/images
sudo chattr +C /var/lib/libvirt/images
```

---

## 8. User Permissions & Groups (`libvirt`, `kvm`, `render`)

Configures necessary groups and ACL permissions for non-root management and direct 3D acceleration over `/dev/dri/renderD128`:

```bash
sudo usermod -aG libvirt,kvm,render $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

Environment variable configured automatically in `~/.config/environment.d/10-libvirt.conf` and `~/.bashrc.d/virtualization.sh`:
```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---

## 9. Verification & Best Practices for Guest VMs

- **Diagnostics**: `just virtualization-status`
- **CPU**: Select model `host-passthrough` in Virt-Manager.
- **Graphics**: Local SPICE (no TCP listener) + OpenGL + Video `VirtIO` with 3D acceleration enabled (VirGL).
- **Disk**: VirtIO SCSI with `writeback` cache, `io_uring` IO engine, and `unmap` discard.
- **Shared Folders**: `virtiofs` managed by `virtiofsd`.
