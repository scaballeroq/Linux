---
sidebar_position: 7
---

# High-Performance Virtualization (KVM/QEMU) on Fedora 44

This guide details the installation, configuration, and optimization of the virtualization stack automated in [`Virtualizacion/virtualization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/Virtualizacion/virtualization.sh) and documented in [`Virtualizacion/Notas_Virtualizacion_Fedora.md`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/Virtualizacion/Notas_Virtualizacion_Fedora.md).

The architecture utilizes the **KVM** hypervisor, **QEMU** emulator, native **PipeWire** audio passthrough, **nftables** firewall backend, **`vhost_vsock`** memory sockets, modular Libvirt daemons, and nested virtualization.

---

## 1. Package Installation (`virtualization.sh`)

Installs KVM, QEMU, Virt-Manager, OVMF UEFI firmware with TPM 2.0 (`swtpm`), and Windows VirtIO drivers:

```bash
just virtualization
# or ./Virtualizacion/virtualization.sh
```

Installed packages:
- `qemu-kvm`, `libvirt-daemon-kvm`, `libvirt-client`, `virt-manager`, `virt-viewer`, `virt-top`, `virt-install`.
- `virtio-win`: Official Fedora paravirtualized drivers for Windows.
- `swtpm`, `swtpm-tools`: TPM 2.0 emulation for Windows 11 VMs.
- `libguestfs-tools`, `tuned`, `acl`.

---

## 2. Kernel Acceleration, Nested KVM & `vhost_vsock`

1. **Nested Virtualization (Nested KVM)**:
   - Configures `nested=1` in `/etc/modprobe.d/kvm_intel.conf` or `kvm_amd.conf` to allow running Docker, Podman, or nested hypervisors inside VMs.
2. **Network & Socket Acceleration**:
   - Loads `vhost_net` and `vhost_vsock` kernel modules in `/etc/modules-load.d/kvm-vhost.conf` for high-throughput zero-copy host-to-guest communications.

---

## 3. Native PipeWire Audio Passthrough (`/etc/libvirt/qemu.conf`)

Routes QEMU virtual machine audio directly through your desktop user's PipeWire audio server without latency or manual workarounds:

```ini
user = "caballero"
group = "kvm"
```

---

## 4. Nftables Firewall Backend (`/etc/libvirt/network.conf`)

Configures `firewall_backend = "nftables"` to integrate with Fedora 44's default nftables packet filtering framework.

---

## 5. Modular Sockets & Tuned Profile (`virtual-host`)

Enables on-demand sockets to optimize RAM and CPU scheduler performance:

```bash
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket
sudo systemctl enable --now tuned.service
sudo tuned-adm profile virtual-host
```

---

## 6. User Permissions & Image Storage ACLs

Grants `libvirt` and `kvm` group memberships to the current user and sets POSIX Access Control Lists (ACLs) on the images pool so you can create VMs without root permissions:

```bash
sudo usermod -aG libvirt,kvm $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

---

## Verification

- **KVM Module**: Run `lsmod | grep kvm` to check that `kvm_amd` or `kvm_intel` is loaded.
- **Libvirt Daemon**: Run `virsh list --all` to verify connectivity to the local hypervisor.
- **Virt-Manager**: Launch the graphical **Virtual Machine Manager** from the KDE Plasma application launcher.
