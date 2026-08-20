---
sidebar_position: 6
---

# Virtualización KVM/QEMU en OpenSUSE Tumbleweed

Esta guía detalla la configuración y el despliegue del entorno de virtualización de alto rendimiento en **OpenSUSE Tumbleweed** con **GNOME**.

---

## 1. Arquitectura

- **Hipervisor**: KVM nativo del kernel con virtualización anidada (`nested=1`).
- **Gestor**: Libvirt con virt-manager, virt-viewer y virsh.
- **Audio Nativo**: Redirección de sonido de máquinas virtuales a PipeWire de usuario mediante `/etc/libvirt/qemu.conf`.
- **Controladores VirtIO**: Descarga automatizada de `virtio-win.iso` para soporte de alto rendimiento en Windows.
- **Optimización de Rendimiento**: Perfil Tuned `virtual-host`.

---

## 2. Instalación y Despliegue

```bash
just virtualization
```

O ejecutando directamente el script:
```bash
./Virtualizacion/virtualization.sh
```

---

## 3. Comandos Útiles de virsh

- Listar todas las máquinas virtuales: `just vms` o `virsh list --all`
- Iniciar una máquina virtual: `virsh start <nombre_mv>`
- Apagar una máquina virtual: `virsh shutdown <nombre_mv>`
- Información de dominio: `virsh dominfo <nombre_mv>`
