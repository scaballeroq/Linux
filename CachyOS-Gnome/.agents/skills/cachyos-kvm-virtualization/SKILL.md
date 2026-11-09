---
name: cachyos-kvm-virtualization
description: Despliegue, gestión, optimización y resolución de problemas de máquinas virtuales KVM/QEMU, Libvirt en CachyOS, virsh, Virt-Manager en GNOME Wayland, Cockpit Machines web console, aceleración 3D VirGL y red virbr0 con Firewalld en CachyOS Workstation (AMD Ryzen 7 7730U).
---

# Virtualización KVM/QEMU y Libvirt (CachyOS Workstation + GNOME)

Esta skill proporciona las directrices operativas, comandos y configuraciones de alto rendimiento para el hipervisor **KVM/QEMU** y **Libvirt** en la estación de trabajo HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8) bajo **CachyOS Workstation (GNOME Shell Wayland)**.

---

## 1. Arquitectura y Diagnóstico de KVM/Libvirt en CachyOS

En CachyOS / Arch Linux, la pila se compone de `qemu-desktop`, `libvirt`, `virt-manager`, `edk2-ovmf`, `virtiofsd` y `dnsmasq`.

### 1.1. Diagnóstico Integral del Sistema de Virtualización:
```bash
./Virtualizacion/virtualization.sh --status
just virtualization-status

# Validación de capacidades completas del hipervisor
virt-host-validate qemu
```

### 1.2. Servicios y Sockets de Libvirt:
```bash
# Estado del demonio libvirtd y sockets
systemctl status libvirtd.service
systemctl status virtlogd.socket
```

---

## 2. Optimización para AMD Ryzen y Radeon Graphics

- **Módulos KVM**: `kvm_amd` con virtualización anidada (`nested=1`) y AVIC (`avic=1`).
- **Aceleración 3D VirGL**: Soporte `virglrenderer` con asignación del usuario a los grupos `kvm`, `libvirt` e `input`.
- **Almacenamiento NoCoW**: Al usar Btrfs, `/var/lib/libvirt/images` debe tener desactivado el Copy-on-Write (`chattr +C /var/lib/libvirt/images`).
- **VirtioFS**: Compartición de carpetas ultrarrápida mediante el daemon de Rust `virtiofsd`.

---

## 3. Red y Cortafuegos (Firewalld)

La red virtual `default` (`virbr0`) se asocia a la zona `libvirt` de Firewalld, permitiendo tráfico y habilitando mascarada hacia la red activa (`home` o `public`):
```bash
sudo firewall-cmd --zone=libvirt --list-all
sudo virsh net-list --all
```
