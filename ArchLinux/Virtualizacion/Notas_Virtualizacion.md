# Notas de Virtualización en Arch Linux

## Instalación de KVM/QEMU/Libvirt

### Paquetes necesarios

```bash
sudo pacman -S libvirt qemu-base qemu-desktop bridge-utils virt-top python-virtinst libguestfs ebtables dnsmasq
```

### VirtIO Drivers para Windows

Los drivers VirtIO para máquinas virtuales Windows se pueden descargar desde:
- GitHub: https://github.com/virtio-win/virtio-win-pkg-scripts/releases
- ISO directa: Se descarga automáticamente con el script `virtualization.sh`

### Servicio Libvirt

Arch Linux usa `libvirtd.service` en lugar de los sockets modulares de Fedora:

```bash
sudo systemctl enable --now libvirtd.service
```

### Permisos de usuario

Añadir usuario a los grupos necesarios:

```bash
sudo usermod -aG libvirt,kvm $USER
```

### Directorio de imágenes

Configurar ACLs para acceso sin sudo:

```bash
sudo mkdir -p /var/lib/libvirt/images
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

### Verificación

```bash
virt-host-validate qemu
```

### Variables de entorno

Añadir a `~/.bashrc`:

```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

### Comandos útiles

```bash
virsh list --all          # Listar VMs
virsh start <vm>          # Iniciar VM
virsh shutdown <vm>       # Apagar VM
virt-manager              # GUI de gestión
```
