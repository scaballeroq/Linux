# Manual de Virtualización de Alto Rendimiento (KVM/QEMU) en Debian 13 (Trixie)

Este manual detalla la configuración y optimización de **KVM / QEMU / virt-manager** para **Debian 13** con kernel optimizado `x86_64-v3`, aceleración de hardware y audio nativo.

---

## 1. Instalación de Paquetes
Instalamos QEMU, libvirt, virt-manager, firmware UEFI (OVMF) con soporte TPM 2.0 y herramientas de aceleración:

```bash
sudo apt update
sudo apt install -y \
    qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients \
    virt-manager virt-viewer virtinst dnsmasq-base dmidecode \
    bridge-utils netcat-openbsd iptables nftables ovmf swtpm \
    libosinfo-bin guestfs-tools tuned acl polkitd
```

> [!NOTE]
> Usamos `dnsmasq-base` en vez de `dnsmasq` para que el demonio de sistema `dnsmasq` no capture el puerto 53 del host, permitiendo a `libvirt` gestionar su propia red NAT virtual (`virbr0`).

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

## 3. Audio Nativo y Permisos QEMU
Debian gestiona QEMU bajo el usuario `libvirt-qemu` y grupo `kvm`. El audio de las máquinas virtuales se canaliza de forma transparente hacia tu sesión de PipeWire/PulseAudio mediante el cliente SPICE/virt-manager.

---

## 4. Backend de Firewall Nftables en Debian 13 (`/etc/libvirt/network.conf`)
Configurado para usar `nftables` nativo en lugar de legacy iptables:
```ini
firewall_backend = "nftables"
```

---

## 5. Controladores VirtIO para Windows (`virtio-win.iso`)
Descarga automática de la ISO estable más reciente del proyecto Fedora:
```bash
curl -fsSL -o ~/Descargas/virtio-drivers/virtio-win.iso https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

---

## 6. Sockets y Servicios de Libvirt y Perfil Tuned (`virtual-host`)
```bash
sudo systemctl enable --now virtlogd.socket virtlockd.socket
sudo systemctl enable --now libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket
sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now tuned.service
sudo tuned-adm profile virtual-host
```

---

## 7. Permisos de Usuario, Polkit y Directorio de Imágenes (ACL)

```bash
sudo usermod -aG libvirt,kvm $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

Regla de Polkit (`/etc/polkit-1/rules.d/80-libvirt.rules`):
```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
```

---
> [!IMPORTANT]
> Recuerda reiniciar la sesión o el equipo tras la instalación para aplicar los grupos `libvirt` y `kvm` a tu usuario.
