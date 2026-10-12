---
sidebar_position: 7
---

# Entorno de Virtualización de Alto Rendimiento (KVM/QEMU) en Fedora 44

Esta guía detalla la instalación, configuración y optimización del entorno de virtualización de alto rendimiento implementado en [`Virtualizacion/virtualization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/Virtualizacion/virtualization.sh) y documentado en [`Virtualizacion/Notas_Virtualizacion_Fedora.md`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/Virtualizacion/Notas_Virtualizacion_Fedora.md).

El esquema utiliza el hipervisor **KVM** y el emulador **QEMU**, con pasarela de audio nativa **PipeWire**, filtrado de red **nftables**, aceleración por sockets **`vhost_vsock`**, demonios modulares de Libvirt y virtualización anidada.

---

## 1. Instalación de Paquetes (`virtualization.sh`)

Instala el hipervisor KVM, QEMU, Virt-Manager, firmware UEFI (OVMF) con soporte TPM 2.0 (`swtpm`) y controladores VirtIO para Windows:

```bash
just virtualization
# o ./Virtualizacion/virtualization.sh
```

Paquetes instalados:
- `qemu-kvm`, `libvirt-daemon-kvm`, `libvirt-client`, `virt-manager`, `virt-viewer`, `virt-top`, `virt-install`.
- `virtio-win`: Controladores paravirtualizados oficiales de Fedora para Windows.
- `swtpm`, `swtpm-tools`: Emulación de módulo TPM 2.0 para Windows 11.
- `libguestfs-tools`, `tuned`, `acl`.

---

## 2. Aceleración del Kernel, Nested KVM y `vhost_vsock`

1. **Virtualización Anidada (Nested KVM)**:
   - Configura `nested=1` en `/etc/modprobe.d/kvm_intel.conf` o `kvm_amd.conf` para permitir ejecutar Docker, Podman o hipervisores secundarios dentro de máquinas virtuales.
2. **Aceleración de Red y Sockets**:
   - Carga los módulos de kernel `vhost_net` y `vhost_vsock` en `/etc/modules-load.d/kvm-vhost.conf` para comunicación ultra-rápida a nivel de memoria entre el anfitrión y las MVs.

---

## 3. Pasarela de Audio Nativa PipeWire (`/etc/libvirt/qemu.conf`)

Permite a las MVs de QEMU reproducir audio directamente por el servidor PipeWire de tu usuario de escritorio sin retrasos ni necesidad de parches adicionales:

```ini
user = "caballero"
group = "kvm"
```

---

## 4. Backend de Firewall Nftables (`/etc/libvirt/network.conf`)

Configura `firewall_backend = "nftables"` para alinearse con el framework nativo de filtrado de paquetes de Fedora 44.

---

## 5. Sockets Modulares y Perfil Tuned (`virtual-host`)

Activa los servicios y sockets por demanda para optimizar memoria RAM y rendimiento del procesador:

```bash
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket
sudo systemctl enable --now tuned.service
sudo tuned-adm profile virtual-host
```

---

## 6. Permisos de Usuario y Directorio de Imágenes (ACL)

Asigna los grupos `libvirt` y `kvm` al usuario actual y configura listas de control de acceso (ACL) para que puedas crear y gestionar discos de máquinas virtuales sin necesidad de permisos de root:

```bash
sudo usermod -aG libvirt,kvm $USER
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

---

## Verificación

- **Estado de KVM**: Ejecuta `lsmod | grep kvm` para verificar la carga del módulo de tu procesador (`kvm_amd` o `kvm_intel`).
- **Daemon Libvirt**: Ejecuta `virsh list --all` para verificar la conexión al hipervisor local.
- **Virt-Manager**: Abre la aplicación gráfica **Gestor de máquinas virtuales** desde el menú de KDE Plasma.
