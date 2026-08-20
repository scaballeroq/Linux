# Manual de Virtualización de Alto Rendimiento (KVM/QEMU) en Manjaro Linux

Este manual detalla la configuración y optimización de **KVM / QEMU / virt-manager** para **Manjaro Linux** con soporte para aceleración de hardware, UEFI OVMF, TPM 2.0 y sockets modulares.

---

## 1. Instalación de Paquetes
Instalamos QEMU, libvirt, virt-manager, firmware UEFI (OVMF) con soporte TPM 2.0 y herramientas de red:

```bash
sudo pacman -S --needed --noconfirm \
    qemu-desktop libvirt virt-manager virt-viewer dnsmasq \
    dmidecode vde2 bridge-utils openbsd-netcat iptables-nft \
    nftables ovmf swtpm tuned
```

---

## 2. Aceleración del Kernel y Virtualización Anidada (Nested KVM)

### Virtualización Anidada:
- **Intel**: `/etc/modprobe.d/kvm_intel.conf` -> `options kvm_intel nested=1`
- **AMD**: `/etc/modprobe.d/kvm_amd.conf` -> `options kvm_amd nested=1`

### Aceleración de Red del Kernel (`vhost_net`):
```bash
echo "vhost_net" | sudo tee /etc/modules-load.d/kvm-vhost.conf
sudo modprobe vhost_net
```

---

## 3. Red NAT Virtual y Backend Nftables

En Manjaro, libvirt utiliza `nftables` como backend moderno de filtrado en `/etc/libvirt/network.conf`:
```ini
firewall_backend = "nftables"
```

Para activar la red por defecto:
```bash
sudo virsh net-start default
sudo virsh net-autostart default
```

---

## 4. Controladores VirtIO para Windows (`virtio-win.iso`)
Descarga automática de los drivers paravirtualizados estables:
```bash
curl -fsSL -o ~/Descargas/virtio-drivers/virtio-win.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

---

## 5. Permisos de Usuario
Para gestionar VMs sin pedir contraseña de root en virt-manager:
```bash
sudo usermod -aG libvirt,kvm $USER
```
*(Requiere cerrar e iniciar sesión para aplicar)*.
