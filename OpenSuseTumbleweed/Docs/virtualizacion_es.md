---
sidebar_position: 7
---

# Entorno de Virtualización de Alto Rendimiento (KVM/QEMU) en openSUSE Tumbleweed

Esta guía detalla la instalación, configuración y optimización del entorno de virtualización de alto rendimiento implementado en [`Virtualizacion/virtualization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Virtualizacion/virtualization.sh) y documentado en [`Virtualizacion/notas_virtualizacion_opensuse.md`](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Virtualizacion/notas_virtualizacion_opensuse.md).

El esquema utiliza el hipervisor **KVM** y el emulador **QEMU**, con pasarela de audio nativa **PipeWire**, integración en **KDE Plasma 6 (Wayland)**, aceleración 3D **VirGL**, compartición de carpetas ultrarrápida **VirtioFS**, aceleración de red y memoria por sockets **`vhost_net`** y **`vhost_vsock`**, almacenamiento **Btrfs NoCoW**, demonios modulares de Libvirt y virtualización anidada.

---

## 1. Instalación y Diagnóstico (`virtualization.sh`)

Puedes comprobar el estado de los componentes o ejecutar la instalación y optimización automática:

```bash
# Diagnóstico completo sin realizar modificaciones
just virtualization-status
# o ./Virtualizacion/virtualization.sh --status

# Instalación y aprovisionamiento completo
just virtualization
# o ./Virtualizacion/virtualization.sh

# Instalación con descarga de controladores VirtIO para Windows
./Virtualizacion/virtualization.sh --with-windows
```

Paquetes incluidos:
- `qemu-kvm`, `qemu-tools`, `libvirt`, `libvirt-daemon-driver-qemu`, `libvirt-client`, `virt-manager`, `virt-viewer`, `virt-top`, `virt-install`.
- `virglrenderer`, `virtiofsd`: Aceleración 3D por GPU y carpetas compartidas de alto rendimiento.
- `spice-vdagent`, `usbredir`: Integración fluida de portapapeles, resolución dinámica y redirección USB.
- `swtpm`, `ovmf`: Emulación de módulo TPM 2.0 y firmware UEFI para SecureBoot.
- `libosinfo`, `guestfs-tools`: Detección automática de sistemas operativos y perfiles óptimos.
- `tuned`, `acl`, `dnsmasq`, `bridge-utils`, `iptables`, `nftables`.

---

## 2. Aceleración del Procesador y Virtualización Anidada (Nested KVM)

1. **Virtualización Anidada y Aceleración por Hardware**:
   - **AMD Ryzen**: `/etc/modprobe.d/kvm_amd.conf` -> `options kvm_amd nested=1 avic=1 npt=1`
     - Habilita AMD AVIC (*Advanced Virtual Interrupt Controller*) y NPT (*Nested Page Tables*).
   - **Intel Core**: `/etc/modprobe.d/kvm_intel.conf` -> `options kvm_intel nested=1 ept=1 vpid=1 pml=1`
     - Habilita Intel EPT (*Extended Page Tables*), VPID y PML.
2. **Aceleración de Red y Sockets de Kernel**:
   - Carga `vhost_net`, `vhost_vsock` y `tun` en `/etc/modules-load.d/kvm-vhost.conf` para comunicación host-guest con cero copias.

---

## 3. Integración de Sonido Nativo PipeWire (`/etc/libvirt/qemu.conf`)

Permite a las MVs de QEMU interactuar directamente con el servidor de sonido PipeWire del usuario de escritorio en KDE Plasma sin latencia ni distorsión:

```ini
user = "tu_usuario"
group = "kvm"
dynamic_ownership = 1
```

---

## 4. Backend de Firewall y Firewalld

- En `/etc/libvirt/network.conf`:
  ```ini
  firewall_backend = "iptables"
  ```
- En Firewalld:
  La interfaz virtual `virbr0` se ubica en la zona `libvirt` con reenvío habilitado (`--add-forward`), y se activa `masquerade` en la zona de red predeterminada.

---

## 5. Regla Polkit para KDE Plasma 6

Para evitar la solicitud constante de contraseñas de root en Virt-Manager:

```javascript
/* /etc/polkit-1/rules.d/50-libvirt.rules */
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
```

---

## 6. Sockets Modulares de Libvirt

Libvirt funciona mediante activación por socket bajo demanda:

```bash
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

## 7. Almacenamiento con Btrfs NoCoW (+C)

En openSUSE Tumbleweed (con Btrfs como sistema de archivos predeterminado), se aplica el atributo `+C` en `/var/lib/libvirt/images` para desactivar Copy-on-Write y evitar fragmentación grave en discos virtuales:

```bash
sudo mkdir -p /var/lib/libvirt/images
sudo chattr +C /var/lib/libvirt/images
```

---

## 8. Permisos de Usuario y Grupos (`libvirt`, `kvm`, `render`)

Se configuran los grupos y permisos ACL necesarios para operar máquinas virtuales sin elevación continua de privilegios y con aceleración 3D directa sobre `/dev/dri/renderD128`:

```bash
sudo usermod -aG libvirt,kvm,render $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

Variable de entorno configurada automáticamente en `~/.config/environment.d/10-libvirt.conf` y `~/.bashrc.d/virtualization.sh`:
```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---

## 9. Verificación y Mejores Prácticas para VMs Invitadas

- **Diagnóstico rápido**: `just virtualization-status`
- **CPU**: Selecciona modelo `host-passthrough` en Virt-Manager.
- **Gráficos**: SPICE local (sin escucha TCP) + OpenGL + Video `VirtIO` con aceleración 3D habilitada (VirGL).
- **Disco**: VirtIO SCSI con caché `writeback`, motor `io_uring` y descarte `unmap`.
- **Carpetas compartidas**: `virtiofs` gestionado por `virtiofsd`.
