# Instalación y Configuración de Virtualización (KVM/QEMU) en CachyOS

Este manual está optimizado para **CachyOS** (basado en Arch Linux). Utiliza el esquema estándar de `libvirt` integrado con el sistema.

## 1. Instalación de Paquetes
Instalamos KVM, libvirt, virt-manager y utilidades asociadas vía `pacman`.

```bash
sudo pacman -S --needed --noconfirm qemu-desktop libvirt virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat iptables-nft edk2-ovmf swtpm tuned virglrenderer virtiofsd
```

## 2. Controladores de Windows (VirtIO)
Descarga la ISO oficial de controladores VirtIO desde el proyecto Fedora:

- [Descargar virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)

## 3. Configuración de Servicios
En Libvirt moderno (12+) se recomiendan los sockets modulares bajo demanda:

```bash
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket virtnodedevd.socket virtproxyd.socket
```

## 4. Permisos de Grupo
Añadimos tu usuario a los grupos clave (`libvirt`, `kvm`).

```bash
sudo usermod -aG libvirt,kvm $USER
```

## 5. Accesibilidad de Directorio (ACL)
```bash
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

## 6. Verificación Final
```bash
sudo virt-host-validate qemu
sudo virsh net-list --all
virsh uri
```
