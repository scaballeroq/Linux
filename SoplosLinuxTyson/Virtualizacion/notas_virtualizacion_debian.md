# Manual de Virtualización de Alto Rendimiento (KVM/QEMU) en Soplos Linux Tyson

Este manual detalla la configuración y optimización de **KVM / QEMU / virt-manager** para **Soplos Linux Tyson** (Debian Testing / Trixie) en portátiles y estaciones de trabajo, con audio nativo PipeWire, aceleración de hardware y compatibilidad con UEFI/TPM 2.0.

---

## 1. Instalación de Paquetes
Instalamos QEMU, libvirt, virt-manager, firmware UEFI (OVMF) con soporte TPM 2.0 (para Windows 11) y herramientas SPICE:

```bash
sudo apt update
sudo apt install -y \
    qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients \
    virt-manager virt-viewer virtinst dnsmasq dmidecode netcat-openbsd \
    iptables nftables ovmf swtpm libosinfo-bin guestfs-tools \
    spice-vdagent acl
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
Para que las máquinas virtuales (Windows, macOS o Linux) reproduzcan audio fluidamente por el servidor PipeWire de tu usuario:
```ini
user = "caballero"
group = "kvm"
```

---

## 4. Backend de Firewall Nftables (`/etc/libvirt/network.conf`)
Configurado para usar `nftables` nativo en lugar de legacy iptables:
```ini
firewall_backend = "nftables"
```

---

## 5. Controladores VirtIO para Windows (`virtio-win.iso`)
Descarga automática de la ISO estable más reciente del proyecto Fedora en `~/Descargas/virtio-drivers/`:
```bash
curl -fsSL -o ~/Descargas/virtio-drivers/virtio-win.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

---

## 6. Sockets Modulares de Libvirt en systemd
En Debian 13 / Trixie se activan los sockets bajo demanda:
```bash
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket virtnodedevd.socket
```

---

## 7. Red Virtual NAT por Defecto (`default`)
Red segura mediante NAT (`virbr0`) gestionada por `dnsmasq` y `nftables` (100% compatible con WiFi y Ethernet en portátiles sin riesgo de cortes de red):
```bash
sudo virsh net-start default
sudo virsh net-autostart default
```

---

## 8. Permisos de Usuario y Directorio de Imágenes (ACL)

```bash
sudo usermod -aG libvirt,kvm caballero
sudo setfacl -R -m u:caballero:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:caballero:rwX /var/lib/libvirt/images
```

Y en tu entorno (`~/.bashrc.d/virtualization.sh` y `~/.zshrc.d/virtualization.sh`):
```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---
> [!IMPORTANT]
> Recuerda reiniciar la sesión o el equipo tras la primera ejecución para aplicar los grupos `libvirt` y `kvm` a tu usuario.
