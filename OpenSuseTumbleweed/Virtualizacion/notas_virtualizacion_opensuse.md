# Manual de Virtualización de Alto Rendimiento (KVM/QEMU) en openSUSE Tumbleweed + KDE Plasma 6

Este manual detalla la configuración y optimización de **KVM / QEMU / virt-manager** para **openSUSE Tumbleweed** bajo **KDE Plasma 6 (Wayland)**, con aceleración de hardware AMD Ryzen / Intel, audio nativo PipeWire, deduplicación KSM, optimización Btrfs NoCoW y reglas Polkit.

---

## 1. Instalación de Paquetes
Instalamos los patrones de KVM y herramientas de libvirt, firmware UEFI (OVMF) con soporte TPM 2.0, utilidades de red y tuned:

```bash
sudo zypper --non-interactive install -y -t pattern kvm_server kvm_tools
sudo zypper --non-interactive install -y \
    qemu-kvm qemu-tools libvirt libvirt-daemon-driver-qemu \
    libvirt-daemon-driver-network libvirt-daemon-driver-storage \
    libvirt-client virt-manager virt-viewer virt-install virt-top \
    virglrenderer virtiofsd spice-vdagent usbredir ovmf swtpm \
    libosinfo guestfs-tools dnsmasq dmidecode bridge-utils tuned acl iptables nftables
```

---

## 2. Aceleración del Kernel y Virtualización Anidada (Nested KVM)

### Virtualización Anidada y Extensiones de CPU:
- **AMD Ryzen**: `/etc/modprobe.d/kvm_amd.conf` -> `options kvm_amd nested=1 avic=1 npt=1`
- **Intel Core**: `/etc/modprobe.d/kvm_intel.conf` -> `options kvm_intel nested=1 ept=1 vpid=1 pml=1`

### Aceleración de Red y Sockets del Kernel (`vhost_net`, `vhost_vsock`, `tun`):
```bash
cat <<EOF | sudo tee /etc/modules-load.d/kvm-vhost.conf
vhost_net
vhost_vsock
tun
EOF
sudo modprobe vhost_net
sudo modprobe vhost_vsock
sudo modprobe tun
```

---

## 3. Integración de Sonido Nativo PipeWire (`/etc/libvirt/qemu.conf`)
Para que las máquinas virtuales reproduzcan audio directamente por el servidor PipeWire de tu sesión de usuario en KDE Plasma:
```ini
user = "caballero"
group = "kvm"
dynamic_ownership = 1
```

---

## 4. Controladores VirtIO para Windows (`virtio-win.iso`)
Descarga opcional de la versión estable oficial (para máquinas Windows):
```bash
./virtualization.sh --with-windows
```
El archivo se guarda en `~/Descargas/virtio-drivers/virtio-win.iso`.

---

## 5. Almacenamiento Btrfs NoCoW (+C) para Pools de Imágenes
En sistemas con Btrfs (como openSUSE Tumbleweed), el mecanismo Copy-on-Write provoca fragmentación severa y reduce el rendimiento de E/S en imágenes `.qcow2` o `.raw`. Se desactiva CoW en la carpeta de imágenes:

```bash
sudo mkdir -p /var/lib/libvirt/images
sudo chattr +C /var/lib/libvirt/images
```

---

## 6. Sockets Modulares de Libvirt (Systemd)
En libvirt moderno, se reemplaza el servicio monolítico `libvirtd` por sockets modulares activados bajo demanda:

```bash
sudo systemctl stop libvirtd.service libvirtd.socket 2>/dev/null || true
sudo systemctl disable libvirtd.service libvirtd.socket 2>/dev/null || true

sudo systemctl enable --now \
    virtqemud.socket \
    virtnetworkd.socket \
    virtstoraged.socket \
    virtnodedevd.socket \
    virtnwfilterd.socket \
    virtsecretd.socket \
    virtproxyd.socket
```

---

## 7. Integración con Firewalld
La interfaz de red virtual `virbr0` se asocia a la zona `libvirt` con reenvío NAT y enmascaramiento:

```bash
sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0
sudo firewall-cmd --permanent --zone=libvirt --add-forward
sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo firewall-cmd --reload
```

---

## 8. Regla Polkit sin Contraseña para KDE Plasma
Para abrir `virt-manager` y administrar máquinas virtuales sin continuos cuadros de diálogo solicitando la contraseña de root:

`/etc/polkit-1/rules.d/50-libvirt.rules`:
```javascript
/* Permitir a usuarios en el grupo libvirt gestionar la virtualización sin pedir contraseña en KDE Plasma */
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
```

---

## 9. Permisos de Usuario y Deduplicación KSM

```bash
sudo usermod -aG libvirt,kvm,render $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

Perfil Tuned de alto rendimiento para host de virtualización:
```bash
sudo systemctl enable --now tuned.service
sudo tuned-adm profile virtual-host
```

Configuración modular del URI por defecto:
```bash
# ~/.bashrc.d/virtualization.sh y ~/.config/environment.d/10-libvirt.conf
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---

## 10. Uso del Script de Automatización

```bash
# Diagnóstico completo del estado del host KVM:
./virtualization.sh --status

# Instalación completa con optimizaciones y drivers VirtIO de Windows:
./virtualization.sh --with-windows

# Ayuda y recomendaciones para VMs Linux:
./virtualization.sh --help
```

> [!IMPORTANT]
> Recuerda reiniciar la sesión o el equipo tras la instalación inicial para aplicar los grupos `libvirt`, `kvm` y `render` a tu usuario.
