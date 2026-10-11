# KVM/QEMU Virtualization Setup on CachyOS

This manual is optimized for **CachyOS** (Arch Linux based). It uses the standard `libvirt` framework.

## 1. Package Installation
```bash
sudo pacman -S --needed --noconfirm qemu-desktop libvirt virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat iptables-nft edk2-ovmf swtpm tuned virglrenderer virtiofsd
```

## 2. Windows VirtIO Drivers
Download `virtio-win.iso` from the Fedora project repository:
- [Download virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)

## 3. Service Configuration
In modern Libvirt (12+), modular socket activation is recommended:
```bash
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket virtnodedevd.socket virtproxyd.socket
```

## 4. Group Permissions
```bash
sudo usermod -aG libvirt,kvm $USER
```

## 5. Directory Permissions (ACL)
```bash
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

## 6. Network and Firewall Setup (NAT)
To grant virtual machines outbound Internet access through the default NAT network (`virbr0`):

1. **Firewalld**: Enable inter-zone forwarding and masquerading:
   ```bash
   sudo firewall-cmd --permanent --zone=libvirt --add-forward
   sudo firewall-cmd --permanent --zone=public --add-masquerade
   sudo firewall-cmd --reload
   ```

2. **Avoid UFW Conflicts**:
   If `ufw` is active alongside Firewalld, it blocks `virbr0` and virtual interfaces (`vnet*`) by default. Disable it:
   ```bash
   sudo systemctl disable --now ufw
   ```

3. **Libvirt Firewall Backend**:
   With Firewalld running, `firewall_backend = "iptables"` (using `iptables-nft`) is recommended:
   ```bash
   sudo sed -i 's/^#*firewall_backend = .*/firewall_backend = "iptables"/' /etc/libvirt/network.conf
   sudo systemctl restart virtnetworkd.service
   ```

4. **Arch Linux Installer Console Troubleshooting (Guest)**:
   If the guest does not obtain an IP automatically upon booting the Arch ISO:
   ```bash
   # Check interface name (e.g., ens3 or enp1s0)
   ip a
   # Restart network daemon to renew DHCP lease
   systemctl restart systemd-networkd
   # Test connectivity
   ping -c 3 archlinux.org
   ```

## 7. Verification
```bash
sudo virt-host-validate qemu
sudo virsh net-list --all
virsh uri
```
