# Manual de Virtualización de Alto Rendimiento (KVM/QEMU) en CachyOS

Este manual detalla la configuración y optimización de **KVM / QEMU / virt-manager** para **CachyOS**, aprovechando al máximo el kernel de CachyOS, sockets modulares de `libvirt` y aceleración de hardware.

---

## 1. Instalación de Paquetes
Instalamos QEMU, libvirt, virt-manager, firmware UEFI (OVMF) con soporte TPM 2.0 y herramientas de aceleración:

```bash
sudo pacman -S --needed --noconfirm \
    qemu-desktop libvirt virt-manager virt-viewer virt-top \
    dnsmasq dmidecode vde2 bridge-utils openbsd-netcat \
    iptables-nft nftables ovmf swtpm guestfs-tools tuned
```

---

## 2. Aceleración del Kernel y Virtualización Anidada (Nested KVM)

### Virtualización Anidada (Permite ejecutar contenedores o VMs dentro de una VM):
- **Intel**: `/etc/modprobe.d/kvm_intel.conf` -> `options kvm_intel nested=1`
- **AMD**: `/etc/modprobe.d/kvm_amd.conf` -> `options kvm_amd nested=1`

### Aceleración de Red por Kernel (`vhost_net`):
Aumenta drásticamente la velocidad de transferencia de red entre el Host y las VMs:
```bash
echo "vhost_net" | sudo tee /etc/modules-load.d/kvm-vhost.conf
sudo modprobe vhost_net
```

---

## 3. Controladores VirtIO para Windows (`virtio-win.iso`)
Descarga automática de la ISO estable más reciente del proyecto Fedora:
```bash
curl -fsSL -o ~/Descargas/virtio-drivers/virtio-win.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

---

## 4. Servicios y Sockets Modulares de `libvirt`
Habilitar los sockets modulares bajo demanda de `libvirt 9.0+`:

```bash
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket
sudo systemctl enable --now libvirtd.service
```

---

## 5. Optimizaciones de Rendimiento del Host (`tuned`)
Activa el perfil `virtual-host` para optimizar la gestión de memoria y CPU del kernel durante la ejecución de VMs:

```bash
sudo systemctl enable --now tuned.service
sudo tuned-adm profile virtual-host
```

---

## 6. Permisos de Usuario y Directorio de Imágenes (ACL)

```bash
# Añadir usuario a grupos libvirt y kvm
sudo usermod -aG libvirt,kvm $USER

# Asignar permisos ACL en /var/lib/libvirt/images
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images

# Configurar el URI por defecto en Bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---

## 7. Verificación del Sistema
```bash
sudo virt-host-validate qemu
virsh net-list --all
virsh uri
```

---
> [!IMPORTANT]
> Recuerda reiniciar la sesión o el equipo tras la instalación para aplicar los grupos `libvirt` y `kvm` a tu usuario.
