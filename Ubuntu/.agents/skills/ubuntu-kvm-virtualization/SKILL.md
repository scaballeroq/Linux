---
name: ubuntu-kvm-virtualization
description: >-
  Use this skill when creating, managing, optimizing, and troubleshooting KVM/QEMU virtual machines, Libvirt domains via virsh, Virt-Manager on GNOME Shell Wayland, Cockpit Machines web console, 3D VirGL acceleration, VirtioFS shared folders, and virtual networks on Ubuntu Workstation.
---

# KVM/QEMU Virtualization Skill (Ubuntu Workstation + AMD Ryzen)

Esta skill proporciona las directrices operativas, comandos y configuraciones de alto rendimiento para el hipervisor **KVM/QEMU** y **Libvirt** en la estación de trabajo HP ProBook 455 G10 con Ubuntu Workstation, GNOME Shell 50 y procesador AMD Ryzen 7 7730U.

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

# Comprobar aceleración por hardware AVIC en AMD Ryzen (Zen 3)
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

## 3. Red Virtual y Cortafuegos (Firewalld)

La red virtual por defecto `default` crea el puente `virbr0` con direccionamiento NAT `192.168.122.0/24`.

### Integración con Firewalld:
`Setup/seguridad.sh` asigna automáticamente `virbr0` a la zona `libvirt` de Firewalld para permitir reenvío de paquetes y DHCP/DNS:
```bash
# Verificar zona libvirt en firewalld
sudo firewall-cmd --zone=libvirt --list-all

# Comprobar estado de la red virsh
virsh net-list --all
```
