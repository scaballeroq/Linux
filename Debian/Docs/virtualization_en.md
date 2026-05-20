---
sidebar_position: 7
---

# Virtualization Environment (KVM/QEMU) on Debian 13

This guide details the installation, configuration, and optimization of the native virtualization environment managed in the `Virtualizacion` folder.

The schema uses the **KVM** hypervisor and the **QEMU** emulator, managed through the system daemon `libvirtd`, featuring support for modern setups, network bridging, and host performance optimizations.

---

## 1. Package Installation (`virtualization.sh`)

Installs the KVM hypervisor, QEMU, the Virt-Manager graphical interface, and supporting utilities (including UEFI/TPM support needed for Windows 11 VMs):

```bash
sudo apt update
sudo apt install -y qemu-system-x86 qemu-kvm libvirt-daemon-system libvirt-clients \
    bridge-utils virtinst virt-manager virt-viewer virt-top libguestfs-tools \
    qemu-utils ovmf swtpm guestfs-tools libosinfo-bin tuned
```

---

## 2. VirtIO Drivers for Windows

Windows virtual machines require specialized drivers (`VirtIO`) for optimal disk storage and network performance. The script automatically downloads the official ISO from the Fedora project:

- Download location: `~/Descargas/virtio-drivers/virtio-win-0.1.271.iso`
- This ISO should be mounted as a secondary CD-ROM drive in Windows virtual machines to install disk (`viostor`) and network (`NetKVM`) drivers.

---

## 3. Network Configuration and Optimization

The virtualization script automates network connectivity setups:

1. **Default Network (NAT)**:
   Enables and starts the native `default` virtual network automatically:
   ```bash
   sudo virsh net-start default
   sudo virsh net-autostart default
   ```

2. **Physical Network Bridge (`br0` / Bridged)**:
   To allow virtual machines to receive their own IP addresses on the host's local area network (LAN), a network bridge is configured via `NetworkManager` (`nmcli`) over the active physical interface. This is also registered in Libvirt as `host-bridge`:
   ```bash
   # XML definition registered in Libvirt
   <network>
     <name>host-bridge</name>
     <forward mode='bridge'/>
     <bridge name='br0'/>
   </network>
   ```

---

## 4. Performance Tuning and User Permissions

To simplify daily virtual machine management and enhance host resource consumption:

1. **Host Tuning Profile (`tuned`)**:
   Enables the `virtual-host` performance profile in the `tuned` daemon to optimize CPU scheduling and memory allocation for virtual machines:
   ```bash
   sudo systemctl enable --now tuned
   sudo tuned-adm profile virtual-host
   ```

2. **Non-Root VM Management**:
   Adds your user to the `libvirt` group to create and manage virtual machines without needing `sudo` privileges:
   ```bash
   sudo usermod -aG libvirt "$USER"
   ```

3. **Storage Access using Access Control Lists (ACL)**:
   Configures secure ACL rules so the user can modify, copy, or create virtual disk files directly in the protected `/var/lib/libvirt/images` directory:
   ```bash
   sudo apt install -y acl
   sudo setfacl -R -b /var/lib/libvirt/images
   sudo setfacl -R -m u:"$USER":rwX /var/lib/libvirt/images
   sudo setfacl -d -m u:"$USER":rwX /var/lib/libvirt/images
   ```

4. **Shell Environment Variables**:
   Defines the default Libvirt connection endpoint in `~/.bashrc.d/virtualization.sh`:
   ```bash
   export LIBVIRT_DEFAULT_URI="qemu:///system"
   ```

---

## Verification

To verify that the virtualization environment is fully operational:

- **Host Capabilities Check**:
  ```bash
  virt-host-validate qemu
  ```
  *(Most modules should return PASS. If KVM modules fail, check that hardware virtualization is enabled in your BIOS/UEFI).*
- **Default Libvirt URI**:
  ```bash
  virsh uri
  # Should return: qemu:///system
  ```
- **Virtual Network Listing**:
  ```bash
  virsh net-list --all
  # Should show both 'default' and 'host-bridge' active.
  ```
