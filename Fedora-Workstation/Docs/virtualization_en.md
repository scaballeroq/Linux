---
sidebar_position: 7
---

# High-Performance Virtualization (KVM/QEMU) on Fedora 44

This guide details the installation, configuration, and optimization of the virtualization stack automated in [`Virtualizacion/virtualization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora-Workstation/Virtualizacion/virtualization.sh) and documented in [`Virtualizacion/notas_virtualizacion_fedora.md`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora-Workstation/Virtualizacion/notas_virtualizacion_fedora.md).

The architecture utilizes the **KVM** hypervisor and **QEMU** emulator, with native **PipeWire** audio passthrough, **nftables** firewall filtering, **VirGL** 3D hardware acceleration, **VirtioFS** ultra-fast folder sharing, **`vhost_vsock`** memory sockets, **Btrfs NoCoW** storage optimization, modular Libvirt 12+ daemons, and nested virtualization.

---

## 1. Installation & Diagnostics (`virtualization.sh`)

You can inspect the virtualization health status or execute the automated provisioning:

```bash
# Non-destructive system diagnostics
just virtualization-status
# or ./Virtualizacion/virtualization.sh --status

# Full provisioning and optimization
just virtualization
# or ./Virtualizacion/virtualization.sh
```

Included packages:
- `qemu-kvm`, `libvirt-daemon-kvm`, `libvirt-client`, `virt-manager`, `virt-viewer`, `gnome-boxes`, `virt-top`, `virt-install`.
- `virglrenderer`, `virtiofsd`: GPU 3D acceleration and high-throughput shared folders.
- `spice-vdagent`, `spice-gtk3`, `usbredir`: Seamless clipboard sharing, dynamic resolution, and USB redirection.
- `swtpm`, `swtpm-tools`: Software TPM 2.0 emulation for Windows 11 and Linux UEFI SecureBoot guests.
- `edk2-ovmf`: UEFI firmware.
- `libosinfo`, `osinfo-db`, `osinfo-db-tools`: OS detection and hardware capability profiles.
- `tuned`, `tuned-ppd`, `acl`, `dnsmasq`, `nftables`, `iptables-nft`.

---

## 2. Processor Acceleration & Nested KVM

1. **Nested Virtualization & Hardware Acceleration**:
   - **AMD Ryzen**: `/etc/modprobe.d/kvm_amd.conf` -> `options kvm_amd nested=1 avic=1 npt=1`
     - Enables AMD AVIC (*Advanced Virtual Interrupt Controller*) and NPT (*Nested Page Tables*).
   - **Intel Core**: `/etc/modprobe.d/kvm_intel.conf` -> `options kvm_intel nested=1 ept=1 vpid=1 pml=1`
     - Enables Intel EPT (*Extended Page Tables*), VPID, and PML.
2. **Kernel Network & Socket Acceleration**:
   - Loads `vhost_net`, `vhost_vsock`, and `tun` in `/etc/modules-load.d/kvm-vhost.conf` for zero-copy host-to-guest communication.

---

## 3. Native PipeWire Audio Passthrough (`/etc/libvirt/qemu.conf`)

Allows QEMU virtual machines to interact directly with the active desktop user's PipeWire sound server without latency or distortion:

```ini
user = "your_username"
group = "kvm"
dynamic_ownership = 1
```

---

## 4. Nftables Firewall Backend & Firewalld

- In `/etc/libvirt/network.conf`:
  ```ini
  firewall_backend = "nftables"
  ```
- In Firewalld:
  Virtual interface `virbr0` is assigned to the `libvirt` zone with forwarding enabled (`--add-forward`), and `masquerade` is enabled on the active workstation zone (`FedoraWorkstation`).

---

## 5. Polkit Rule for GNOME Wayland

Prevents continuous root password prompts in Virt-Manager and GNOME Boxes:

```javascript
/* /etc/polkit-1/rules.d/50-libvirt.rules */
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
```

---

## 6. Modular Libvirt 12+ Sockets

Libvirt 12+ on Fedora relies on on-demand systemd socket activation:

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

When `/var/lib/libvirt/images` resides on a Btrfs filesystem (default in Fedora), the `+C` attribute is set to disable Copy-on-Write and prevent disk fragmentation:

```bash
sudo mkdir -p /var/lib/libvirt/images
sudo chattr +C /var/lib/libvirt/images
```

---

## 8. User Permissions & Groups (`libvirt`, `kvm`, `render`)

Grants necessary group memberships and POSIX ACLs to operate virtual machines without root elevation and with direct 3D acceleration over `/dev/dri/renderD128`:

```bash
sudo usermod -aG libvirt,kvm,render $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

Environment variable set automatically in `~/.config/environment.d/10-libvirt.conf` and `~/.bashrc.d/virtualization.sh`:
```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---

## 9. Verification & Best Practices for Guest VMs

- **Health check**: `just virtualization-status`
- **CPU**: Select `host-passthrough` model in Virt-Manager.
- **Graphics**: Local SPICE (no TCP listen) + OpenGL + `VirtIO` video with 3D acceleration enabled (VirGL).
- **Disk**: VirtIO SCSI with `writeback` cache, `io_uring` I/O engine, and `unmap` discard (TRIM).
- **Shared Folders**: `virtiofs` backed by `virtiofsd`.
