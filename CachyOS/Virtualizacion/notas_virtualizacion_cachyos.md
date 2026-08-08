# Instalación y Configuración de Virtualización (KVM/QEMU) en CachyOS

Este manual está optimizado para **CachyOS** (Arch Linux). Utiliza el esquema estándar de `libvirt` integrado con Pacman y controladores de alto rendimiento.

## 1. Instalación de Paquetes
Instalamos KVM, libvirt, virt-manager y utilidades asociadas vía `pacman`.

```bash
sudo pacman -S --needed --noconfirm \
    qemu-desktop libvirt virt-manager virt-viewer virt-top \
    dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables-nft ovmf swtpm tuned
```

## 2. Controladores de Windows (VirtIO)
Descarga la ISO oficial de controladores VirtIO desde el proyecto Fedora:

- [Descargar virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)

Adjunta esta ISO a tu máquina virtual Windows como un segundo CD-ROM para instalar los controladores durante o después de la instalación.

## 3. Configuración de Servicios
Habilita y arranca el servicio `libvirtd`:

```bash
sudo systemctl enable --now libvirtd.service
```

## 4. Permisos de Grupo y Entorno de Terminal
Añadimos tu usuario a los grupos clave (`libvirt`, `kvm`) para gestionar las máquinas virtuales sin depender de `sudo`.

```bash
# Añadir al grupo libvirt y kvm
sudo usermod -aG libvirt,kvm $USER

# Configurar QEMU del host como destino automático en tu shell
if ! grep -q "LIBVIRT_DEFAULT_URI" ~/.bashrc; then
    echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> ~/.bashrc
fi
source ~/.bashrc
```

## 5. Accesibilidad de Directorio (ACL)
Asignamos listas de control de acceso (ACLs) al directorio principal de imágenes para facilitar la administración directa.

```bash
sudo pacman -S --needed --noconfirm acl

# Eliminar cualquier configuración ACL antigua
sudo setfacl -R -b /var/lib/libvirt/images

# Otorgar permisos completos al usuario sobre el contenido existente
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images

# Imponer una regla por defecto para que los nuevos ficheros creados mantengan tus permisos
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images

# Comprobar el resultado
getfacl /var/lib/libvirt/images
```

## 6. Verificación Final
Valida tu entorno con los siguientes comandos:

```bash
# Verificar configuraciones de hardware y kernel
sudo virt-host-validate qemu

# Comprobar que la red por defecto ("default") esté activa
sudo virsh net-list --all

# Confirmar la conexión predeterminada (debería decir "qemu:///system")
virsh uri
```

---
> [!IMPORTANT]
> La asignación de grupos de tu usuario (**paso 4**) entrará en vigor sólo tras cerrar sesión y volver a entrar, o tras reiniciar el sistema.
