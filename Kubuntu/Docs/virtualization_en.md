---
sidebar_position: 7
---

# Virtualization Environment (KVM/QEMU) in Kubuntu

This guide details the installation, configuration, and optimization of the native virtualization environment in the `Virtualizacion` directory.

The setup utilizes the **KVM** hypervisor and **QEMU** emulator, managed via the `libvirtd` system daemon, with modern guest support (UEFI/TPM) and network/disk optimizations.

---

## 1. Package Installation (`virtualization.sh`)

Installs KVM hypervisor, QEMU, Virt-Manager GUI, and supporting utilities:

```bash
sudo apt update
sudo apt install -y qemu-system-x86 qemu-kvm libvirt-daemon-system libvirt-clients \
    bridge-utils virtinst virt-manager virt-viewer virt-top libguestfs-tools \
    qemu-utils ovmf swtpm guestfs-tools libosinfo-bin tuned
```

---

## 2. Windows VirtIO Drivers

Windows virtual machines require specialized VirtIO drivers for optimal storage and network performance. The script downloads the official ISO from Fedora:

- Download path: `~/Descargas/virtio-drivers/virtio-win-0.1.271.iso`
- Attach this ISO as a secondary CD-ROM in Windows guest VMs to install storage (`viostor`) and network (`NetKVM`) drivers.

---

## 3. Network Configuration & Optimization

The script configures:

1. **Default NAT Network**:
   ```bash
   sudo virsh net-start default
   sudo virsh net-autostart default
   ```

2. **Physical Bridged Network (`br0`)**:
   Configured via NetworkManager (`nmcli`) on the active physical network interface and registered in Libvirt as `host-bridge`:
   ```bash
   <network>
     <name>host-bridge</name>
     <forward mode='bridge'/>
     <bridge name='br0'/>
   </network>
   ```

---

## 4. Performance Tuning & User Permissions

1. **Host Tuning Profile (`tuned`)**:
   Enables `virtual-host` profile for optimized CPU and memory scheduling:
   ```bash
   sudo systemctl enable --now tuned
   sudo tuned-adm profile virtual-host
   ```

2. **Passwordless VM Management**:
   Adds user to `libvirt` and `kvm` groups:
   ```bash
   sudo usermod -aG libvirt,kvm "$USER"
   ```

3. **Storage Access via Access Control Lists (ACL)**:
   ```bash
   sudo apt install -y acl
   sudo setfacl -R -b /var/lib/libvirt/images
   sudo setfacl -R -m u:"$USER":rwX /var/lib/libvirt/images
   sudo setfacl -d -m u:"$USER":rwX /var/lib/libvirt/images
   ```

4. **Shell Environment**:
   Configures `~/.bashrc.d/virtualization.sh`:
   ```bash
   export LIBVIRT_DEFAULT_URI="qemu:///system"
   ```

---

## Verification

- **Host Validation**:
  ```bash
  virt-host-validate qemu
  ```
- **Libvirt Default URI**:
  ```bash
  virsh uri
  ```
- **Virtual Networks**:
  ```bash
  virsh net-list --all
  ```
