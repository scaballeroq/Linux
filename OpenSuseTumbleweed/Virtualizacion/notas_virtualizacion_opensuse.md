# Manual de Virtualización de Alto Rendimiento (KVM/QEMU) en OpenSUSE Tumbleweed + GNOME

Este manual detalla la configuración y optimización de **KVM / QEMU / virt-manager** para **OpenSUSE Tumbleweed** con aceleración de hardware, audio nativo PipeWire y controladores optimizados.

---

## 1. Instalación de Paquetes
Instalamos los patrones de KVM y herramientas de libvirt, firmware UEFI (OVMF) con soporte TPM 2.0 y tuned:

```bash
sudo zypper install -y -t pattern kvm_server kvm_tools
sudo zypper install -y \
    qemu-kvm qemu-tools libvirt libvirt-daemon-driver-qemu \
    libvirt-daemon-driver-network libvirt-daemon-driver-storage \
    virt-manager virt-viewer virt-install dnsmasq dmidecode \
    bridge-utils ovmf swtpm libosinfo guestfs-tools tuned acl
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
Para que las máquinas virtuales reproduzcan audio directamente por el servidor PipeWire de tu usuario:
```ini
user = "caballero"
group = "kvm"
```

---

## 4. Controladores VirtIO para Windows (`virtio-win.iso`)
Descarga automática de la ISO estable más reciente:
```bash
curl -fsSL -o ~/Descargas/virtio-drivers/virtio-win.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

---

## 5. Servicios y Perfil Tuned (`virtual-host`)
```bash
sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now tuned.service
sudo tuned-adm profile virtual-host
```

---

## 6. Permisos de Usuario y Directorio de Imágenes (ACL)

```bash
sudo usermod -aG libvirt,kvm $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---
> [!IMPORTANT]
> Recuerda reiniciar la sesión o el equipo tras la instalación para aplicar los grupos `libvirt` y `kvm` a tu usuario.
