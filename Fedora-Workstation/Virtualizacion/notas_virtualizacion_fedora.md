# Manual de Virtualización de Alto Rendimiento (KVM/QEMU) en Fedora 45 Workstation

Este manual detalla la configuración, optimización y mejores prácticas para **KVM / QEMU / virt-manager / GNOME Boxes / Cockpit Machines** en **Fedora 45 Workstation (GNOME Shell 51 Wayland)** optimizado para la estación de trabajo **HP ProBook 455 G10** (AMD Ryzen 7 7730U, Radeon Graphics Vega 8, 32 GB RAM, SSD NVMe Kioxia Btrfs) con audio nativo PipeWire, aceleración por hardware (AMD AVIC, NPT y Nested KVM), aceleración 3D VirGL, almacenamiento Btrfs NoCoW y demonios modulares de Libvirt 12+.

---

## 1. Opciones del Script y Comandos de Ejecución

El script [`Virtualizacion/virtualization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora-Workstation/Virtualizacion/virtualization.sh) soporta ejecución modular e idempotente:

```bash
# Diagnóstico completo sin realizar modificaciones (rápido y no bloqueante)
just virtualization-status
# o: ./Virtualizacion/virtualization.sh --status

# Aprovisionamiento e instalación completa
just virtualization
# o: ./Virtualizacion/virtualization.sh

# Aprovisionamiento con utilidades adicionales:
./Virtualizacion/virtualization.sh --with-windows   # Descarga/instala virtio-win.iso
./Virtualizacion/virtualization.sh --with-cockpit   # Instala y activa Cockpit Machines (web 9090)
./Virtualizacion/virtualization.sh --with-bridge    # Crea puente br0 sobre Ethernet cableada
```

---

## 2. Instalación del Stack Completo de Paquetes (DNF5)

Instala los componentes principales del hipervisor, interfaces gráficas, firmware UEFI SecureBoot con emulación TPM 2.0 (`swtpm`), herramientas de inspección y aceleración gráfica/red:

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

## 3. Aceleración del Procesador y Virtualización Anidada (Nested KVM)

### 3.1. Opciones de Virtualización de CPU por Hardware
- **AMD Ryzen (Zen 3 Barcelo-R / 7730U)**:
  Configurado en `/etc/modprobe.d/kvm_amd.conf`:
  ```ini
  options kvm_amd nested=1 avic=1 npt=1
  ```
  - `nested=1`: Habilita virtualización anidada (ejecutar VMs, Podman o Docker dentro de VMs).
  - `avic=1`: *Advanced Virtual Interrupt Controller* para reducir drásticamente la latencia de interrupciones.
  - `npt=1`: *Nested Page Tables* para paginación de memoria acelerada por hardware.

- **Intel Core / Xeon**:
  Configurado en `/etc/modprobe.d/kvm_intel.conf`:
  ```ini
  options kvm_intel nested=1 ept=1 vpid=1 pml=1
  ```
  - `ept=1`: *Extended Page Tables*.
  - `vpid=1`: *Virtual Processor ID* (evita vaciados innecesarios de TLB al cambiar de contexto).
  - `pml=1`: *Page Modification Logging*.

### 3.2. Aceleración de Red y Sockets en Kernel (`/etc/modules-load.d/kvm-vhost.conf`)
```ini
vhost_net
vhost_vsock
tun
```

---

## 4. Integración de Sonido Nativo PipeWire (`/etc/libvirt/qemu.conf`)

Permite a los procesos de QEMU interactuar adecuadamente con la sesión de usuario y dispositivos de renderizado directo:

```ini
user = "caballero"
group = "kvm"
dynamic_ownership = 1
```

> [!NOTE]
> Además de la configuración en `qemu.conf`, los clientes SPICE nativos en GNOME Wayland (**Virt-Manager**, **virt-viewer** y **GNOME Boxes**) enrutan el audio dinámicamente hacia el daemon de usuario de **PipeWire / WirePlumber** con latencia ultra-baja.

---

## 5. Backend de Red y Firewall Nftables en Fedora 45

Fedora 45 utiliza `nftables` y `firewalld` por defecto.

### 5.1. Configuración de Libvirt (`/etc/libvirt/network.conf`)
```ini
firewall_backend = "nftables"
```

### 5.2. Configuración en Firewalld
La interfaz de red virtual `virbr0` se asocia a la zona `libvirt` y se habilita el reenvío y masquerade en la zona activa de Fedora (`FedoraWorkstation`):
```bash
sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0
sudo firewall-cmd --permanent --zone=libvirt --add-forward
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-masquerade
sudo firewall-cmd --reload
```

---

## 6. Regla Polkit para GNOME Wayland (Sin contraseñas de Root)

Para permitir a los miembros del grupo `libvirt` administrar máquinas virtuales sin continuas solicitudes de elevación de privilegios en GNOME Boxes y Virt-Manager:

`/etc/polkit-1/rules.d/50-libvirt.rules`:
```javascript
/* Permitir a usuarios en el grupo libvirt gestionar la virtualización sin pedir contraseña en GNOME */
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
```

---

## 7. Sockets Modulares de Libvirt 12+ (Systemd Socket Activation)

Libvirt moderno reemplaza el servicio monolítico `libvirtd` por daemons modulares activados por socket bajo demanda, reduciendo drásticamente el consumo de memoria en reposo:

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
> `virtproxyd.socket` expone `/run/libvirt/libvirt-sock`, garantizando retrocompatibilidad transparente con `virt-manager`, `gnome-boxes`, `virsh` y Cockpit Machines.

---

## 8. Almacenamiento y Optimización Btrfs NoCoW (+C)

Fedora Workstation utiliza **Btrfs** por defecto. Si el directorio de imágenes `/var/lib/libvirt/images` reside en Btrfs, el mecanismo Copy-on-Write (CoW) genera severa fragmentación y perjudica el rendimiento de E/S.

Se desactiva CoW recursivamente en la carpeta de imágenes antes de aprovisionar discos virtuales:
```bash
sudo mkdir -p /var/lib/libvirt/images
sudo chattr -R +C /var/lib/libvirt/images
```

Y se asegura el pool de almacenamiento `default`:
```bash
virsh pool-define-as --name default --type dir --target /var/lib/libvirt/images
virsh pool-build default
virsh pool-start default
virsh pool-autostart default
```

---

## 9. Deduplicación de Memoria RAM (KSM)

Habilita Kernel Samepage Merging (KSM) de forma persistente mediante `systemd-tmpfiles` para consolidar páginas de memoria idénticas compartidas entre máquinas virtuales:

`/etc/tmpfiles.d/ksm.conf`:
```ini
w /sys/kernel/mm/ksm/run - - - - 1
w /sys/kernel/mm/ksm/sleep_millisecs - - - - 100
```

---

## 10. Permisos de Usuario y Grupos (`libvirt`, `kvm`, `render`)

Para permitir la gestión sin root y la aceleración 3D VirGL sobre `/dev/dri/renderD128`:

```bash
sudo usermod -aG libvirt,kvm,render $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

Variable de entorno global en `~/.config/environment.d/10-libvirt.conf` y `Bash.Setup/environment.sh`:
```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

---

## 11. Protección de Red: Detección de Wi-Fi vs Ethernet

Por limitaciones del estándar IEEE 802.11 (3 direcciones MAC por trama), vincular un puente Linux directo (`br0`) a una interfaz Wi-Fi degrada o rompe la conexión inalámbrica en portátiles.
- **En Wi-Fi (wlp1s0)**: Se utiliza la red virtual NAT predeterminada (`virbr0` + `vhost_net`), que proporciona velocidad de enlace completa y acceso transparente a Internet.
- **En Ethernet cableada**: Con la opción `--with-bridge`, se crea un puente `br0` con NetworkManager para que las máquinas virtuales obtengan una IP directa en la misma subred LAN local.

---

## 12. Consolas Gráficas: Virt-Manager, GNOME Boxes y Cockpit Machines

1. **GNOME Boxes**: Experiencia nativa GNOME Shell 51, fluida y minimalista, ideal para pruebas rápidas de ISOs y escritorios efímeros.
2. **Virt-Manager**: Herramienta avanzada para configuración detallada de hardware virtualizado, topología de vCPUs, passthrough PCIe y storage pools.
3. **Cockpit Machines (Web UI en https://localhost:9090)**:
   ```bash
   sudo dnf5 install -y cockpit cockpit-machines
   sudo systemctl enable --now cockpit.socket
   sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=cockpit
   sudo firewall-cmd --reload
   ```

---

## 13. Guía de Configuración Óptima para Máquinas Virtuales Linux en Virt-Manager

Al crear o ajustar una máquina virtual Linux en **Virt-Manager**:

1. **CPU**:
   - Modelo: `host-passthrough` (acceso directo a todas las instrucciones nativas Zen 3, AVX2, AES-NI).
   - Topología: Asignar núcleos acordes (p. ej. 4 núcleos / 1 hilo o 4 núcleos / 2 hilos).
2. **Pantalla y Gráficos (60+ FPS Wayland)**:
   - Pantalla: **SPICE**, Tipo de escucha: **Ninguno** (socket Unix local).
   - Marcar: **Aceleración OpenGL**.
   - Video: **VirtIO** con casilla **Aceleración 3D** marcada (utiliza `virglrenderer` sobre AMD Radeon Graphics).
3. **Almacenamiento (Disco)**:
   - Bus de disco: **VirtIO** o **SCSI** (con controlador VirtIO SCSI).
   - Rendimiento: Modo de caché `writeback`, Motor de E/S `io_uring`, Descarte `unmap` (TRIM para recuperar espacio NVMe).
4. **Compartir Carpetas Host <-> Guest**:
   - Añadir Hardware -> Sistema de archivos -> Modo de acceso: `virtiofs` (requiere habilitar memoria compartida memfd en la VM).
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
