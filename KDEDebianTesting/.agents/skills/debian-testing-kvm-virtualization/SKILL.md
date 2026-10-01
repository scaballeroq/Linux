---
name: debian-testing-kvm-virtualization
description: >-
  Use this skill when creating, managing, optimizing, and troubleshooting KVM/QEMU virtual machines, Libvirt domains via virsh, Virt-Manager on KDE Plasma 6 Wayland, Cockpit Machines web console, 3D VirGL acceleration, VirtioFS shared folders, and virtual networks on Debian Testing.
---

# KVM/QEMU Virtualization Skill (Debian Testing + AMD Ryzen)

Esta skill proporciona las directrices operativas, comandos y configuraciones de alto rendimiento para el hipervisor **KVM/QEMU** y **Libvirt** en la estación de trabajo HP EliteBook 855 G7 con Debian Testing, KDE Plasma 6 y procesador AMD Ryzen 7 PRO 4750U.

---

## 1. Arquitectura y Diagnóstico del Hipervisor

La infraestructura de virtualización se gestiona mediante el script optimizado del repositorio:
`bash Virtualizacion/virtualization.sh`

### Diagnóstico del sistema:
```bash
# Comprobación de estado general (CPU, sockets, firewall, almacenamiento y permisos)
bash Virtualizacion/virtualization.sh --status

# Validar capacidades completas del host con virt-host-validate
virt-host-validate qemu

# Comprobar aceleración por hardware AVIC en AMD Ryzen (Zen 2)
cat /sys/module/kvm_amd/parameters/avic   # Debe ser Y o 1

# Comprobar virtualización anidada (Nested KVM)
cat /sys/module/kvm_amd/parameters/nested # Debe ser 1
```

---

## 2. Gestión de Máquinas Virtuales con `virsh`

El entorno está configurado con `LIBVIRT_DEFAULT_URI="qemu:///system"`, permitiendo gestionar el hipervisor sin necesidad de especificar la URI de conexión:

```bash
# Listar todas las máquinas virtuales (activas e inactivas)
virsh list --all

# Iniciar una máquina virtual
virsh start <nombre_vm>

# Apagado ordenado (mediante ACPI / qemu-guest-agent)
virsh shutdown <nombre_vm>

# Forzar apagado inmediato
virsh destroy <nombre_vm>

# Reiniciar máquina virtual
virsh reboot <nombre_vm>

# Obtener dirección IP asignada a una máquina en ejecución
virsh domifaddr <nombre_vm>

# Información de recursos y estado de una VM
virsh dominfo <nombre_vm>
```

---

## 3. Aceleración Gráfica 3D (VirGL en AMD Radeon Vega 7)

KVM/QEMU soporta renderizado 3D acelerado directamente en la GPU integrada del host (`/dev/dri/renderD128`) para guests Linux con KDE o GNOME.

### Configuración en Virt-Manager:
1. **Pantalla SPICE**:
   - Tipo de pantalla: `SPICE`
   - Escuchando en: `Ninguna` (solo socket local)
   - Marcar: **Aceleración OpenGL** (`Aceleración 3D`) -> Seleccionar dispositivo `/dev/dri/renderD128`.
2. **Tarjeta de Video**:
   - Modelo: `VirtIO`
   - Marcar: **Aceleración 3D** (VirGL).

---

## 4. Almacenamiento de Alto Rendimiento (ext4 en SSD NVMe)

El almacenamiento del host es un disco SSD NVMe de 1 TB en **ext4**. Para máxima velocidad de E/S y protección de la vida útil del disco:

- **Bus de disco**: `VirtIO` (en lugar de SATA o IDE).
- **Modo de caché**: `none` (E/S directa que evita doble búfer en los 32 GB de RAM del host) o `writeback`.
- **Modo de E/S**: `native` o `threads`.
- **Descarte (TRIM)**: Marcar opción `unmap` (permite que los comandos TRIM del sistema invitado liberen bloques físicos en el SSD NVMe).
- **Formato**: `qcow2` con preasignación de metadatos o formato `raw`.

```bash
# Información y tamaño real de una imagen de disco
qemu-img info /var/lib/libvirt/images/<disco>.qcow2

# Compactar espacio libre en una imagen qcow2
qemu-img convert -O qcow2 -c /var/lib/libvirt/images/origen.qcow2 /var/lib/libvirt/images/compactada.qcow2
```

---

## 5. Compartición de Carpetas Ultrarrápida (VirtIO-FS)

VirtIO-FS reemplaza al antiguo 9p ofreciendo velocidad casi nativa entre el host y las máquinas virtuales mediante el daemon `virtiofsd`:

1. En la configuración de la VM (Virt-Manager):
   - Añadir hardware -> **Sistema de archivos**.
   - Controlador: `virtiofs`.
   - Ruta de origen (Host): `/home/caballero/Workspace`.
   - Tag de destino: `host_workspace`.
2. En la máquina virtual invitada (Guest Linux):
   ```bash
   sudo mkdir -p /mnt/workspace
   sudo mount -t virtiofs host_workspace /mnt/workspace
   ```

---

## 6. Red Virtual y Cortafuegos (Firewalld)

La red NAT predeterminada (`virbr0`) está coordinada con Firewalld en la zona `libvirt`:

```bash
# Comprobar estado de la red virtual 'default'
virsh net-list --all
virsh net-info default

# Iniciar y habilitar autoinicio de la red si estuviera detenida
virsh net-start default
virsh net-autostart default

# Consultar direcciones IP asignadas por DHCP en virbr0
virsh net-dhcp-leases default
```

---

## 7. Interfaces de Gestión (Doble Vía)

- **Virt-Manager**: Interfaz nativa de escritorio KDE Wayland (`virt-manager`). Recomendada para configuración avanzada de hardware, redirección USB, VirGL 3D y sonido.
- **Cockpit Machines**: Consola web ligera accesible en el navegador en `https://localhost:9090` (puerto gestionado por `cockpit.socket` y Firewalld). Ideal para crear, pausar y monitorizar VMs de forma ágil.
