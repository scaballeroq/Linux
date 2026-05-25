# Instalación y Configuración de Virtualización (KVM/QEMU) en Debian

Este manual está optimizado para versiones modernas de Debian (como Debian 13 LTS). Utiliza el esquema estándar de `libvirtd` integrado con el sistema.

## 1. Instalación de Paquetes
Instalamos KVM, libvirt, virt-manager, y utilidades asociadas.

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager virt-viewer virt-top libguestfs-tools
```

## 2. Controladores de Windows (VirtIO)
En Debian, los controladores VirtIO no están en el repositorio oficial como un paquete RPM. Debes descargar la ISO manualmente desde el proyecto Fedora:

- [Descargar virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)

Adunta esta ISO a tu máquina virtual Windows como un segundo CD-ROM para instalar los drivers.

## 3. Configuración de Servicios
Debian utiliza el demonio `libvirtd` monolítico por defecto. Asegúrate de que esté activo:

```bash
sudo systemctl enable --now libvirtd
```

## 4. Permisos de Grupo y Entorno de Terminal
Añadimos tu usuario a los grupos clave para gestionar las máquinas virtuales sin depender de `sudo`.

```bash
# Añadir al grupo libvirt (gestión de VMs) y kvm (rendimiento hardware)
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
sudo apt install -y acl

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
Valida tu entorno con los siguientes comandos.

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
