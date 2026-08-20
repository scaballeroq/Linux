---
sidebar_position: 7
---

# Entorno de Virtualización (KVM/QEMU) en Manjaro Linux

Esta guía detalla la instalación, configuración y optimización del entorno de virtualización de alto rendimiento presente en [`Virtualizacion/virtualization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/ManjaroTesting/Virtualizacion/virtualization.sh).

El esquema utiliza el hipervisor **KVM** y el emulador **QEMU**, con integración de audio **PipeWire**, filtrado de paquetes **nftables**, aceleración por sockets **`vhost_vsock`** y virtualización anidada.

---

## 1. Instalación de Paquetes (`virtualization.sh`)

Instala el hipervisor KVM, QEMU, Virt-Manager, firmware UEFI (OVMF) con soporte TPM 2.0 y herramientas de aceleración:

```bash
./Virtualizacion/virtualization.sh
# O mediante just:
just virtualization
```

---

## 2. Aceleración del Kernel, Nested KVM y `vhost_vsock`

1. **Virtualización Anidada (Nested KVM)**:
   - Configura `nested=1` en `/etc/modprobe.d/kvm_intel.conf` o `kvm_amd.conf` para permitir ejecutar Docker o hipervisores secundarios dentro de máquinas virtuales.
2. **Aceleración de Red y Sockets**:
   - Carga los módulos de kernel `vhost_net` y `vhost_vsock` en `/etc/modules-load.d/kvm-vhost.conf` para comunicación ultra-rápida a nivel de memoria entre el anfitrión y las MVs.

---

## 3. Backend de Firewall Nftables (`/etc/libvirt/network.conf`)

Configura `firewall_backend = "nftables"` para alinearse con el framework nativo de filtrado de paquetes en Manjaro Linux.

---

## 4. Controladores VirtIO para Windows

Descarga automática de la ISO estable de Fedora `virtio-win.iso` a `~/Descargas/virtio-drivers/virtio-win.iso` para controladores de almacenamiento (`viostor`) y red (`NetKVM`).

---

## 5. Sockets y Servicios de Libvirt y Perfil Tuned (`virtual-host`)

Activa los servicios e interfaces de libvirt y el perfil de optimización del host:

```bash
sudo systemctl enable --now libvirtd.socket libvirtd.service
sudo systemctl enable --now tuned.service
sudo tuned-adm profile virtual-host
```
