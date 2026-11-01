---
sidebar_position: 7
---

# Entorno de Virtualización (KVM/QEMU) en Soplos Linux Boro (GNOME Shell)

Esta guía detalla la instalación, configuración y optimización del entorno de virtualización nativo presente en la carpeta `Virtualizacion/`, diseñado para **Soplos Linux Boro** y **GNOME Shell**.

El esquema utiliza el hipervisor **KVM** y el emulador **QEMU**, gestionados a través de **Libvirt**, ofreciendo dos interfaces principales:
1. **Consola Web Cockpit** (`cockpit-machines` en `https://localhost:9090`).
2. **Virt-Manager** para control avanzado de hardware y aceleración 3D VirGL en GNOME Shell Wayland.

---

## 1. Instalación y Pila de Paquetes (`virtualization.sh`)

Instala KVM, QEMU, Virt-Manager, Cockpit Machines, herramientas UEFI/TPM y dependencias de aceleración:

```bash
just virtualization
```

---

## 2. Aceleración por Hardware y Virtualización Anidada (Nested KVM)

El script detecta la CPU del equipo y aplica flags de rendimiento en `/etc/modprobe.d/`:
- **AMD Ryzen (`kvm_amd.conf`)**: `options kvm_amd nested=1 avic=1 npt=1`
- **Intel Core (`kvm_intel.conf`)**: `options kvm_intel nested=1 ept=1 vpid=1 pml=1`
- **Módulos de red en el Kernel**: `vhost_net`, `vhost_vsock`, `tun` cargados automáticamente.

---

## 3. Almacenamiento Optimizado (Btrfs NoCoW y ACLs)

- **Btrfs NoCoW (`+C`)**: Si `/var/lib/libvirt/images` reside en un sistema de archivos Btrfs, aplica automáticamente el atributo `chattr +C` para evitar la fragmentación severa y maximizar los IOPS de los discos virtuales `qcow2`.
- **Listas de Control de Acceso (ACL)**: Permiten al usuario gestionar imágenes de disco sin requerir `sudo`.

---

## 4. Redes y Protección Inalámbrica (Wi-Fi)

- **Red NAT `default` (virbr0)**: Red virtual estándar protegida con Firewalld (zona `trusted` y mascarada activa).
- **Detección Segura de Wi-Fi**: En portátiles con conexión inalámbrica, se previene la creación de puentes `br0` para evitar la rotura de la conexión a internet (limitación del estándar 802.11). Si la interfaz activa es Ethernet cableada, se aprovisiona `br0` automáticamente.

---

## 5. Regla Polkit sin Contraseñas

Crea `/etc/polkit-1/rules.d/50-libvirt.rules` para que los miembros del grupo `libvirt` puedan arrancar, pausar y crear máquinas virtuales desde Virt-Manager o Cockpit sin solicitar contraseña de root.

---

## 6. Deduplicación de Memoria (KSM)

Activa la compartición de páginas idénticas de memoria RAM entre máquinas virtuales mediante `/etc/tmpfiles.d/ksm.conf`, optimizado para balancear consumo de CPU y memoria en portátiles.

---

## 7. Diagnóstico y Estado con Just

```bash
# Diagnosticar estado del hipervisor, módulos KVM, sockets y red
just virtualization-status
```
