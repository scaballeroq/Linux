# Instalación y Configuración de Virtualización (KVM/QEMU) en Fedora

Este manual está optimizado para versiones modernas de Fedora (como Fedora 40/44). Evita el uso del esquema monolítico antiguo (`libvirtd`) e implementa la arquitectura moderna de demonios modulares (*socket activation*), que ahorra batería y memoria. También elimina `tuned` tal como solicitaste, manteniendo el sistema liviano y acorde a tus preferencias.

## 1. Instalación de Paquetes
Instalamos el grupo completo de virtualización que incluye automáticamente KVM, libvirt, virt-manager, y utilidades asociadas.

```bash
sudo dnf group install -y --with-optional virtualization
```

## 2. Controladores de Windows (VirtIO)
Si planeas virtualizar máquinas Windows, es fundamental instalar los controladores VirtIO para obtener el máximo rendimiento nativo en discos y adaptadores de red.

```bash
sudo curl -o /etc/yum.repos.d/virtio-win.repo https://fedorapeople.org/groups/virt/virtio-win/virtio-win.repo
sudo dnf install -y virtio-win
```

## 3. Configuración de Servicios (Demonios Modulares)
Históricamente se habilitaba el servicio obsoleto `libvirtd` o se arrancaban múltiples demonios (`virtqemud.service`, etc.). Las versiones modernas recomiendan usar **sockets**. Al habilitar los sockets, el servicio sólo se iniciará automáticamente cuando utilices `virt-manager` o `virsh`, ahorrando recursos el resto del tiempo.

```bash
# Habilitamos y arrancamos los sockets principales de QEMU y Red
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket
```

## 4. Permisos de Grupo y Entorno de Terminal
Añadimos tu usuario a los grupos clave para no depender de contraseñas de administrador para gestionar las máquinas virtuales, y redirigimos la variable predeterminada para que conectes siempre a nivel de sistema.

```bash
# Añadir al grupo libvirt (gestión de VMs) y kvm (rendimiento hardware)
sudo usermod -aG libvirt,kvm $USER

# Configurar QEMU del host como destino automático en tu shell
echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> ~/.zshrc
source ~/.zshrc
```

## 5. Accesibilidad de Directorio (ACL)
Para facilitarte la tarea de agregar ISOs o administrar directamente los discos duros virtuales, asignamos listas de control de acceso (ACLs) al directorio principal usando la variable `$USER` genérica, reemplazando el nombre manual para que sea replicable.

```bash
# Eliminar cualquier configuración ACL antigua
sudo setfacl -R -b /var/lib/libvirt/images

# Otorgar permisos completos al usuario sobre el contenido existente (X mayúscula respeta ejecutabilidad)
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images

# Imponer una regla por defecto para que los nuevos ficheros creados mantengan tus permisos
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images

# Comprobar el resultado
getfacl /var/lib/libvirt/images
```

## 6. Verificación Final
Por último, puedes utilizar estos comandos para validar tu entorno. Tu hardware (IOMMU, KVM, etc.) debería mostrar "PASS".

```bash
# Verificar configuraciones de hardware y kernel
sudo virt-host-validate qemu

# Comprobar que la red por defecto ("default") esté activa
sudo virsh net-list --all

# Confirmar la conexión predeterminada (debería decir "qemu:///system")
virsh uri
```

> [!IMPORTANT]
> A diferencia de los servicios o configuraciones, **la asignación de grupos de tu usuario (paso 4)** entrará en vigor sólo en una nueva sesión o una vez que reinicies el sistema.
