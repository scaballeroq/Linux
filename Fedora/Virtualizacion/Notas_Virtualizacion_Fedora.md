# Manual de Virtualización de Alto Rendimiento (KVM/QEMU) en Fedora 44 Workstation

Este manual detalla la configuración y optimización de **KVM / QEMU / virt-manager** para **Fedora 44** con audio nativo PipeWire, aceleración por hardware y demonios modulares de Libvirt.

---

## 1. Instalación de Paquetes
Instalamos QEMU, libvirt, virt-manager, firmware UEFI (OVMF) con soporte TPM 2.0, controladores VirtIO y herramientas de aceleración:

```bash
sudo dnf5 group install -y --with-optional "Virtualization"
sudo dnf5 install -y \
    qemu-kvm \
    libvirt-daemon-kvm \
    libvirt-client \
    virt-manager \
    virt-viewer \
    virt-top \
    virt-install \
    virtio-win \
    libguestfs-tools \
    guestfs-tools \
    bridge-utils \
    swtpm \
    swtpm-tools \
    libosinfo \
    tuned \
    acl
```

---

## 2. Aceleración del Kernel y Virtualización Anidada (Nested KVM)

### Virtualización Anidada:
- **Intel**: `/etc/modprobe.d/kvm_intel.conf` -> `options kvm_intel nested=1`
- **AMD**: `/etc/modprobe.d/kvm_amd.conf` -> `options kvm_amd nested=1`

### Aceleración de Red y Sockets del Kernel (`vhost_net` y `vhost_vsock`):
```bash
cat <<EOF | sudo tee /etc/modules-load.d/kvm-vhost.conf
vhost_net
vhost_vsock
EOF
sudo modprobe vhost_net
sudo modprobe vhost_vsock
```

---

## 3. Integración de Sonido Nativo PipeWire (`/etc/libvirt/qemu.conf`)
Para que las máquinas virtuales reproduzcan audio directamente por el servidor PipeWire de tu usuario de escritorio:
```ini
user = "caballero"
group = "kvm"
```

---

## 4. Backend de Firewall Nftables en Fedora 44 (`/etc/libvirt/network.conf`)
Configurado para usar `nftables` nativo en lugar de legacy iptables:
```ini
firewall_backend = "nftables"
```

---

## 5. Controladores VirtIO para Windows (`virtio-win`)
En Fedora 44, los controladores VirtIO oficiales para Windows se instalan y actualizan mediante el paquete oficial `virtio-win`:
```bash
sudo dnf5 install -y virtio-win
# Las ISOs quedan disponibles en: /usr/share/virtio-win/virtio-win.iso
```

---

## 6. Sockets Modulares y Perfil Tuned (`virtual-host`)
```bash
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket
sudo systemctl enable --now tuned.service
sudo tuned-adm profile virtual-host
```

---

## 7. Permisos de Usuario y Directorio de Imágenes (ACL)

```bash
sudo usermod -aG libvirt,kvm $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---

> [!IMPORTANT]
> Recuerda reiniciar la sesión o el equipo tras la instalación para aplicar los grupos `libvirt` y `kvm` a tu usuario.
