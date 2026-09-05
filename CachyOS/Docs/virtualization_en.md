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

## 6. Verification
```bash
sudo virt-host-validate qemu
sudo virsh net-list --all
virsh uri
```
