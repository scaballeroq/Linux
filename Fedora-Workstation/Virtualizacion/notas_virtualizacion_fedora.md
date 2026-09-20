# Manual de Virtualización de Alto Rendimiento (KVM/QEMU) en Fedora 44 Workstation

Este manual detalla la configuración, optimización y mejores prácticas para **KVM / QEMU / virt-manager / GNOME Boxes** en **Fedora 44 Workstation (GNOME Wayland)** con audio nativo PipeWire, aceleración por hardware (AMD Ryzen e Intel Core), aceleración 3D VirGL, almacenamiento Btrfs NoCoW y demonios modulares de Libvirt 12+.

---

## 1. Instalación del Stack Completo de Paquetes (DNF5)

Instalamos los componentes principales del hipervisor, interfaces gráficas, firmware UEFI SecureBoot con emulación TPM 2.0 (`swtpm`), herramientas de inspección y aceleración gráfica/red:

```bash
sudo dnf5 install -y \
    qemu-kvm \
    libvirt-daemon-kvm \
    libvirt-client \
    virt-manager \
    virt-viewer \
    gnome-boxes \
    virt-top \
    virt-install \
    virglrenderer \
    virtiofsd \
    spice-vdagent \
    spice-gtk3 \
    usbredir \
    edk2-ovmf \
    swtpm \
    swtpm-tools \
    libosinfo \
    osinfo-db \
    osinfo-db-tools \
    tuned \
    tuned-ppd \
    acl \
    guestfs-tools \
    dnsmasq \
    nftables \
    iptables-nft
```

---

## 2. Aceleración del Procesador y Virtualización Anidada (Nested KVM)

### 2.1. Opciones de Virtualización de CPU por Hardware
- **AMD Ryzen (Zen / Zen 2 / Zen 3 / Zen 4 / Zen 5)**:
  Crea `/etc/modprobe.d/kvm_amd.conf`:
  ```ini
  options kvm_amd nested=1 avic=1 npt=1
  ```
  - `nested=1`: Habilita virtualización anidada (ejecutar VMs, Podman o Docker dentro de VMs).
  - `avic=1`: *Advanced Virtual Interrupt Controller* para reducir drásticamente la latencia de interrupciones.
  - `npt=1`: *Nested Page Tables* para paginación de memoria acelerada por hardware.

- **Intel Core / Xeon**:
  Crea `/etc/modprobe.d/kvm_intel.conf`:
  ```ini
  options kvm_intel nested=1 ept=1 vpid=1 pml=1
  ```
  - `ept=1`: *Extended Page Tables*.
  - `vpid=1`: *Virtual Processor ID* (evita vaciados innecesarios de TLB al cambiar de contexto).
  - `pml=1`: *Page Modification Logging*.

### 2.2. Aceleración de Red y Sockets en Kernel (`/etc/modules-load.d/kvm-vhost.conf`)
```ini
vhost_net
vhost_vsock
tun
```

---

## 3. Integración de Sonido Nativo PipeWire (`/etc/libvirt/qemu.conf`)

Permite que las máquinas virtuales reproduzcan y graben audio directamente a través del servidor PipeWire de la sesión de usuario activa:

```ini
user = "tu_usuario"
group = "kvm"
dynamic_ownership = 1
```

---

## 4. Backend de Red y Firewall Nftables en Fedora 44

Fedora 44 utiliza `nftables` y `firewalld` por defecto.

### 4.1. Configuración de Libvirt (`/etc/libvirt/network.conf`)
```ini
firewall_backend = "nftables"
```

### 4.2. Configuración en Firewalld
La interfaz de red virtual `virbr0` se asocia a la zona `libvirt` y se habilita el reenvío y masquerade en la zona activa de Fedora (`FedoraWorkstation`):
```bash
sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0
sudo firewall-cmd --permanent --zone=libvirt --add-forward
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-masquerade
sudo firewall-cmd --reload
```

---

## 5. Regla Polkit para GNOME Wayland (Sin contraseñas de Root)

Para evitar que GNOME Boxes y Virt-Manager soliciten la contraseña de root cada vez que se abren o administran recursos, se configura `/etc/polkit-1/rules.d/50-libvirt.rules`:

```javascript
/* Permitir a usuarios en el grupo libvirt gestionar la virtualización sin pedir contraseña en GNOME */
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
```

---

## 6. Sockets Modulares de Libvirt 12+ (Systemd Socket Activation)

Libvirt moderno reemplaza el servicio monolítico `libvirtd` por daemons modulares activados por socket bajo demanda, reduciendo el consumo de memoria en reposo:

```bash
# Desactivar demonio monolítico heredado
sudo systemctl disable --now libvirtd.service libvirtd.socket 2>/dev/null || true

# Habilitar sockets modulares bajo demanda
sudo systemctl enable --now \
    virtqemud.socket \
    virtnetworkd.socket \
    virtstoraged.socket \
    virtnodedevd.socket \
    virtnwfilterd.socket \
    virtsecretd.socket \
    virtproxyd.socket
```
> [!NOTE]
> `virtproxyd.socket` expone `/run/libvirt/libvirt-sock`, garantizando retrocompatibilidad transparente con `virt-manager`, `gnome-boxes` y comandos estándar de `virsh`.

---

## 7. Almacenamiento y Optimización Btrfs NoCoW (+C)

Fedora Workstation utiliza **Btrfs** por defecto. Si el directorio de imágenes `/var/lib/libvirt/images` reside en Btrfs, el mecanismo Copy-on-Write (CoW) genera severa fragmentación y perjudica el rendimiento de E/S.

Se desactiva CoW en la carpeta de imágenes antes de crear discos virtuales:
```bash
sudo mkdir -p /var/lib/libvirt/images
sudo chattr +C /var/lib/libvirt/images
```

---

## 8. Deduplicación de Memoria RAM (KSM)

Habilita Kernel Samepage Merging (KSM) de forma persistente mediante `systemd-tmpfiles` para consolidar páginas de memoria idénticas compartidas entre máquinas virtuales:

`/etc/tmpfiles.d/ksm.conf`:
```ini
w /sys/kernel/mm/ksm/run - - - - 1
w /sys/kernel/mm/ksm/sleep_millisecs - - - - 100
```

---

## 9. Permisos de Usuario y Grupos (`libvirt`, `kvm`, `render`)

Para permitir la gestión sin root y la aceleración 3D VirGL sobre `/dev/dri/renderD128`:

```bash
sudo usermod -aG libvirt,kvm,render $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

Y en el entorno de usuario (`~/.config/environment.d/10-libvirt.conf` y `~/.bashrc.d/virtualization.sh`):
```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---

## 10. Protección de Red: Detección de Wi-Fi vs Ethernet

Por limitaciones del estándar IEEE 802.11 (3 direcciones MAC por trama), vincular un puente Linux directo (`br0`) a una interfaz Wi-Fi degrada o rompe la conexión inalámbrica.
- En **Wi-Fi**: Se utiliza la red virtual NAT predeterminada (`virbr0` + `vhost_net`), que proporciona rendimiento a velocidad de enlace y acceso transparente a Internet.
- En **Ethernet cableada**: Se puede crear un puente `br0` con NetworkManager para que las máquinas virtuales obtengan una IP directa en la misma subred LAN local.

---

## 11. Guía de Configuración Óptima para Máquinas Virtuales Linux en Virt-Manager

Al crear o ajustar una máquina virtual Linux en **Virt-Manager**:

1. **CPU**:
   - Modelo: `host-passthrough` (acceso directo a todas las instrucciones nativas del procesador anfitrión).
2. **Pantalla y Gráficos (60+ FPS Wayland)**:
   - Pantalla: **SPICE**, Tipo de escucha: **Ninguno** (socket Unix local).
   - Marcar: **Aceleración OpenGL**.
   - Video: **VirtIO** con casilla **Aceleración 3D** marcada (utiliza `virglrenderer` sobre tu GPU AMD/Intel).
3. **Almacenamiento (Disco)**:
   - Bus de disco: **VirtIO** o **SCSI** (con controlador VirtIO SCSI).
   - Rendimiento: Modo de caché `writeback`, Motor de E/S `io_uring`, Descarte `unmap` (TRIM para recuperar espacio).
4. **Compartir Carpetas Host <-> Guest**:
   - Añadir Hardware -> Sistema de archivos -> Modo de acceso: `virtiofs` (requiere habilitar memoria compartida en la VM).
5. **Agentes de Integración**:
   - Instala en la máquina invitada:
     ```bash
     # En Fedora guest:
     sudo dnf install -y spice-vdagent qemu-guest-agent
     # En Arch/CachyOS guest:
     sudo pacman -S spice-vdagent qemu-guest-agent
     # En Debian/Ubuntu guest:
     sudo apt install -y spice-vdagent qemu-guest-agent
     ```
