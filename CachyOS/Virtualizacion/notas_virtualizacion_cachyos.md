# Manual de Virtualización de Alto Rendimiento (KVM/QEMU) en CachyOS
## Optimizado para Distribuciones Linux (Kernel 7.x, GNOME Wayland, AMD Ryzen / Intel)

Este manual detalla la arquitectura, configuración y optimización de **KVM / QEMU / virt-manager / GNOME Boxes** en **CachyOS**, aprovechando al máximo el kernel optimizado de CachyOS, los sockets modulares de `libvirt 12+`, aceleración 3D por hardware (VirGL sobre AMD Vega/Radeon), almacenamiento Btrfs NoCoW, integración con GNOME Wayland (Polkit sin contraseñas) y compartición de archivos ultrarrápida (VirtioFS).

---

## 1. Automatización con `virtualization.sh`

El repositorio incluye el script modular [`virtualization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/CachyOS/Virtualizacion/virtualization.sh):

```bash
# Diagnóstico rápido y exhaustivo del entorno (GNOME, KVM, Btrfs, Polkit, Firewalld, grupos)
./Virtualizacion/virtualization.sh --status

# Instalación y optimización completa para CachyOS con GNOME
./Virtualizacion/virtualization.sh

# Instalación incluyendo también controladores VirtIO para Windows
./Virtualizacion/virtualization.sh --with-windows
```

---

## 2. Aceleración del Kernel y Virtualización Anidada (Nested KVM)

### Procesadores AMD Ryzen / Zen (como Ryzen 7 PRO 4750U):
En `/etc/modprobe.d/kvm_amd.conf`:
```ini
options kvm_amd nested=1 avic=1 npt=1
```
- **`nested=1`**: Permite virtualización anidada (ejecutar Docker, Podman o KVM dentro de la máquina virtual).
- **`avic=1`** (*Advanced Virtual Interrupt Controller*): Reduce significativamente las salidas de VM (*VM exits*) y la sobrecarga de interrupciones en CPUs AMD Zen.
- **`npt=1`** (*Nested Page Tables*): Paginación asistida por hardware para eliminar latencia en la gestión de memoria.

### Procesadores Intel Core / Xeon:
En `/etc/modprobe.d/kvm_intel.conf`:
```ini
options kvm_intel nested=1 ept=1 vpid=1 pml=1
```

### Aceleración de Red y Sockets en Kernel (`/etc/modules-load.d/kvm-vhost.conf`):
- `vhost_net`: Acelera drásticamente el tráfico entre el host y las VMs mediante procesamiento directo en el kernel.
- `vhost_vsock`: Comunicación de baja latencia entre host y guest mediante sockets `AF_VSOCK`.
- `tun`: Módulo para interfaces de túnel de red virtual.

---

## 3. Arquitectura Modular de Daemons en Libvirt 12+

En sistemas modernos como CachyOS y Arch Linux, el servicio monolítico tradicional `libvirtd.service` está en desuso y **no debe** habilitarse simultáneamente con los sockets modulares.

Los servicios se activan bajo demanda (*Systemd Socket Activation*) a través de:
- `virtqemud.socket`: Controlador del hipervisor QEMU.
- `virtnetworkd.socket`: Gestión de redes virtuales (NAT `default`, bridges).
- `virtstoraged.socket`: Gestión de pools de almacenamiento (`/var/lib/libvirt/images`).
- `virtnodedevd.socket`: Asignación de dispositivos PCI/USB.
- `virtnwfilterd.socket`: Filtrado de red y reglas nwfilter para interfaces virtuales.
- `virtsecretd.socket`: Gestión de claves y secretos cifrados (LUKS/TLS).
- `virtproxyd.socket`: Provee compatibilidad hacia atrás escuchando en `/run/libvirt/libvirt-sock` para que `virt-manager`, `gnome-boxes`, `virsh` y Cockpit funcionen de forma transparente.

---

## 4. Integración con GNOME (Wayland) y Seguridad Polkit

### A. Regla Polkit sin Contraseñas (`/etc/polkit-1/rules.d/50-libvirt.rules`)
Para evitar que GNOME Shell muestre continuos cuadros de diálogo emergentes pidiendo contraseña de administrador al abrir `virt-manager` o gestionar máquinas virtuales:
```javascript
/* Permitir a usuarios en el grupo libvirt gestionar la virtualización sin pedir contraseña en GNOME */
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
```

### B. Grupos de Usuario
El usuario debe pertenecer a:
- `libvirt`: Gestión del hipervisor a través de sockets y Polkit.
- `kvm`: Acceso de lectura/escritura directo a `/dev/kvm`.
- `render`: Acceso directo al nodo de renderizado DRI (`/dev/dri/renderD128`) para aceleración GPU 3D VirGL (AMD Vega/Radeon).

### C. Variable de Entorno `LIBVIRT_DEFAULT_URI`
Configurada en `$HOME/.config/environment.d/10-libvirt.conf`, `$HOME/.zshrc.d/` y `$HOME/.bashrc.d/`:
```ini
LIBVIRT_DEFAULT_URI=qemu:///system
```
Garantiza que tanto las herramientas de terminal (`virsh`) como las aplicaciones gráficas de GNOME se conecten de inmediato al hipervisor del sistema.

---

## 5. Almacenamiento Btrfs NoCoW (`chattr +C`)

CachyOS instala por defecto el sistema de archivos **Btrfs**. Los discos virtuales (`.qcow2`, `.raw`) sufren una grave degradación de rendimiento y alta fragmentación si Copy-on-Write (CoW) permanece activo.

El script configura automáticamente el directorio de imágenes:
```bash
sudo mkdir -p /var/lib/libvirt/images
sudo chattr +C /var/lib/libvirt/images
```
Esto garantiza que todos los discos virtuales nuevos hereden el atributo `NoCoW`, eliminando la sobrecarga en el SSD NVMe.

---

## 6. Configuración Óptima para VMs Linux en GNOME

### A. Procesador (CPU)
1. Abre los detalles de la máquina virtual -> **CPUs**.
2. Modelo: Desmarca la opción por defecto y escribe **`host-passthrough`**.
   - *Beneficio*: La máquina invitada tendrá acceso a todas las instrucciones nativas de tu procesador (AVX2, AES, Zen/SSE4a), acelerando compilaciones, criptografía y ejecución general.
3. Topología: Configura 1 socket, N núcleos y 2 hilos (si tu CPU tiene SMT).

### B. Gráficos y Pantalla (GNOME Wayland Fluido a 60+ FPS)
1. **Pantalla SPICE**:
   - Tipo de escucha: **Ninguno** (Listen: None). Utiliza un socket Unix local seguro y de máxima velocidad.
   - Marca la casilla: **Aceleración OpenGL**.
2. **Video VirtIO (VirGL)**:
   - Modelo: **VirtIO**.
   - Marca la casilla: **Aceleración 3D**.
   - *Beneficio*: Gracias a `virglrenderer` y al grupo `render`, la VM utilizará la GPU física AMD Radeon Vega para renderizar el escritorio Wayland a 60+ FPS sin recurrir al pesado renderizado por CPU (`llvmpipe`).

### C. Almacenamiento (Disco Virtual)
1. Bus del disco: **VirtIO** o **SCSI** (con controlador VirtIO SCSI).
2. Opciones de rendimiento:
   - Modo de caché: **`writeback`**.
   - Modo de descarte: **`unmap`** (permite que el comando `fstrim` en el Linux invitado libere espacio real en el SSD del host).
   - Motor de E/S: **`io_uring`** (proporciona la mayor tasa de IOPS y menor latencia en el Kernel 7.x de CachyOS).

### D. Red Virtual y Firewalld
- Dispositivo de red: Modelo **VirtIO**.
- Fuente de red: Red virtual `default` (NAT con `virbr0`).
- *Firewalld*: La interfaz `virbr0` se asocia a la zona `libvirt` con reenvío (*forwarding*) activo y masquerade en la zona `home`.
- *Nota sobre Wi-Fi*: En portátiles conectados por Wi-Fi, la red NAT `default` con `vhost_net` es la opción ideal, ya que el estándar Wi-Fi no permite bridges directos en modo cliente.

---

## 7. Compartir Carpetas a Velocidad Nativa con VirtioFS

`VirtioFS` (gestionado por `virtiofsd` en Rust) reemplaza al anticuado protocolo 9p con un rendimiento idéntico al disco SSD local y soporte POSIX completo.

### Paso 1: Habilitar Memoria Compartida en la VM
En `virt-manager`, edita el XML de la máquina virtual (o en detalles de memoria) asegurando:
```xml
<memoryBacking>
  <source type='memfd'/>
  <access mode='shared'/>
</memoryBacking>
```

### Paso 2: Añadir el Sistema de Archivos
1. En `virt-manager` -> **Añadir hardware** -> **Sistema de archivos**.
2. Modo de controlador: **virtiofs**.
3. Ruta de origen: Directorio del host que deseas compartir (ej. `/home/caballero/Workspace`).
4. Etiqueta de destino: Un identificador arbitrario (ej. `workspace_host`).

### Paso 3: Montar dentro de la Distribución Linux Invitada
Dentro de la máquina virtual:
```bash
sudo mkdir -p /mnt/workspace
sudo mount -t virtiofs workspace_host /mnt/workspace
```

Para montaje automático permanente, añade a `/etc/fstab` del invitado:
```ini
workspace_host /mnt/workspace virtiofs defaults,_netdev 0 0
```

---

## 8. Paquetes Recomendados Dentro del Linux Invitado

Para disfrutar de resolución de pantalla dinámica que se adapte al tamaño de ventana de GNOME / virt-manager, sincronización bidireccional del portapapeles y apagado limpio:

### Arch Linux / CachyOS / Manjaro:
```bash
sudo pacman -S --needed spice-vdagent qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

### Fedora / RHEL / Rocky / AlmaLinux:
```bash
sudo dnf install -y spice-vdagent qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

### Ubuntu / Debian / Linux Mint:
```bash
sudo apt update && sudo apt install -y spice-vdagent qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

### openSUSE Tumbleweed / Leap:
```bash
sudo zypper install -y spice-vdagent qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

---

## 9. Diagnóstico y Verificación

```bash
# Diagnóstico integral del script
./Virtualizacion/virtualization.sh --status

# Validación oficial de capacidades KVM
virt-host-validate qemu

# Listado de redes y pools activos
virsh net-list --all
virsh pool-list --all
```
