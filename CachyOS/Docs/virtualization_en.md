# KVM/QEMU Virtualization Setup on CachyOS

This manual is optimized for **CachyOS** (Arch Linux based). It uses the standard `libvirt` framework.

## 1. Package Installation
```bash
sudo pacman -S --needed --noconfirm qemu-desktop libvirt virt-manager virt-viewer virt-top dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables-nft ovmf swtpm tuned
```

## 2. Windows VirtIO Drivers
Download `virtio-win.iso` from the Fedora project repository:
- [Download virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)

## 3. Service Configuration
```bash
sudo systemctl enable --now libvirtd.service
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
