---
name: fedora-kvm-virtualization
description: Despliegue, gestión, optimización y resolución de problemas de máquinas virtuales KVM/QEMU, Libvirt modular (virtqemud), virsh, Virt-Manager en GNOME 51 Wayland, Cockpit Machines web console, aceleración 3D VirGL y red virbr0 con Firewalld en Fedora 45 Workstation (AMD Ryzen 7 7730U).
---

# Virtualización KVM/QEMU y Libvirt Modular (Fedora 45 Workstation + GNOME 51)

Esta skill proporciona las directrices operativas, comandos y configuraciones de alto rendimiento para el hipervisor de tipo 1 **KVM/QEMU** y la suite de demonios modulares de **Libvirt** en la estación de trabajo HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8) bajo **Fedora 45 Workstation (GNOME Shell 51 Wayland)**.

---

## 1. Arquitectura y Diagnóstico del Hipervisor KVM

Fedora 45 implementa la arquitectura de demonios modulares de Libvirt (`virtqemud`, `virtnetworkd`, `virtstoraged`, `virtnodedevd`), activados bajo demanda mediante sockets de Systemd.

### 1.1. Diagnóstico Integral del Sistema de Virtualización:
```bash
# Diagnóstico automatizado del script del repositorio
./Virtualizacion/virtualization.sh --status
just virtualization-status

# Validación de capacidades completas del hipervisor con virt-host-validate
virt-host-validate qemu
```

### 1.2. Módulos del Kernel y Aceleración AMD Ryzen (Zen 3 / Barcelo-R):
```bash
# Comprobar módulo KVM para AMD
lsmod | grep kvm_amd

# Comprobar AVIC (Advanced Virtual Interrupt Controller)
cat /sys/module/kvm_amd/parameters/avic   # Debe devolver Y o 1

# Comprobar virtualización anidada (Nested KVM)
cat /sys/module/kvm_amd/parameters/nested # Debe devolver 1
```

### 1.3. Almacenamiento en Btrfs con atributo NoCoW:
Para evitar la degradación de IOPS por fragmentación en sistemas de archivos Btrfs, el directorio de imágenes debe tener activado el atributo NoCoW (`+C`):
```bash
lsattr -d /var/lib/libvirt/images | grep -i c
```

---

## 2. Gestión de Máquinas Virtuales con `virsh`

El entorno tiene configurado `LIBVIRT_DEFAULT_URI="qemu:///system"` y reglas Polkit en `/etc/polkit-1/rules.d/80-libvirt.rules` para operar sin pedir contraseña de `root` a los miembros del grupo `libvirt`.

```bash
# Listar todas las máquinas virtuales (activas e inactivas)
virsh list --all

# Iniciar una máquina virtual
virsh start <nombre_vm>

# Apagado ordenado mediante ACPI / QEMU Guest Agent
virsh shutdown <nombre_vm>

# Forzar apagado inmediato
virsh destroy <nombre_vm>

# Reiniciar máquina virtual
virsh reboot <nombre_vm>

# Consultar dirección IP asignada a una máquina en ejecución
virsh domifaddr <nombre_vm>

# Consultar uso de recursos de una VM
virsh dominfo <nombre_vm>
```

---

## 3. Redes Virtuales y Cortafuegos (`Firewalld`)

La red NAT por defecto `default` crea el puente `virbr0` con direccionamiento `192.168.122.0/24`.

### 3.1. Diagnóstico de Red en Libvirt y Firewalld:
```bash
# Estado de redes virtuales en Libvirt
virsh net-list --all

# Inspeccionar la zona dedicada 'libvirt' en Firewalld
sudo firewall-cmd --zone=libvirt --list-all

# Asegurar masquerade en la zona principal FedoraWorkstation
sudo firewall-cmd --zone=FedoraWorkstation --query-masquerade
```

### 3.2. Sockets Modulares de Libvirt:
```bash
systemctl status virtqemud.socket virtnetworkd.socket virtstoraged.socket
```

---

## 4. Consolas Gráficas: Virt-Manager, GNOME Boxes y Cockpit Machines

### 4.1. Virt-Manager y GNOME Boxes en Wayland (GNOME 51):
- **Virt-Manager:** Soporte nativo para aceleración 3D VirGL (`virtio-gpu-gl` con renderizador en `/dev/dri/renderD128`) y carpetas compartidas con **VirtioFS** (`virtiofsd`).
- **GNOME Boxes:** Interfaz moderna e integrada en el flujo de GNOME 51 para pruebas rápidas de ISOs.

### 4.2. Consola Web Cockpit Machines (Puerto 9090):
```bash
# Acceso web a la gestión de máquinas virtuales:
sudo systemctl enable --now cockpit.socket
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=cockpit
sudo firewall-cmd --reload
# Acceso desde el navegador: https://localhost:9090
```

---

## 5. Recetas Justfile para Virtualización

```bash
# Instalar y optimizar la infraestructura de KVM/QEMU, Libvirt y Virt-Manager
just virtualization

# Diagnóstico de virtualización
just virtualization-status
```
