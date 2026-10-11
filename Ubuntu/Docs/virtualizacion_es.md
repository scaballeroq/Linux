---
sidebar_position: 7
---

# Entorno de Virtualización (KVM/QEMU) en Debian 13

Esta guía detalla la instalación, configuración y optimización del entorno de virtualización nativo presente en la carpeta `Virtualizacion`.

El esquema utiliza el hipervisor **KVM** y el emulador **QEMU**, gestionados a través del demonio del sistema `libvirtd`, con soporte para entornos modernos y optimizaciones de rendimiento de red y disco.

---

## 1. Instalación de Paquetes (`virtualization.sh`)

Se instalan el hipervisor KVM, QEMU, el gestor de interfaz gráfica Virt-Manager y utilidades de soporte (incluyendo compatibilidad con UEFI/TPM necesario para instalar Windows 11):

```bash
sudo apt update
sudo apt install -y qemu-system-x86 qemu-kvm libvirt-daemon-system libvirt-clients \
    bridge-utils virtinst virt-manager virt-viewer virt-top libguestfs-tools \
    qemu-utils ovmf swtpm guestfs-tools libosinfo-bin tuned
```

---

## 2. Controladores VirtIO para Windows

Las máquinas virtuales Windows requieren controladores específicos (`VirtIO`) para un óptimo rendimiento en almacenamiento y red virtual. El script descarga automáticamente la ISO oficial del proyecto Fedora:

- Ruta de descarga: `~/Descargas/virtio-drivers/virtio-win-0.1.271.iso`
- Esta ISO debe montarse como una unidad de CD-ROM secundaria en las máquinas virtuales Windows para instalar los controladores de disco (`viostor`) y red (`NetKVM`).

---

## 3. Configuración y Optimización de Red

El script de virtualización automatiza la conectividad en red:

1. **Red por Defecto (NAT)**:
   Activa e inicia automáticamente la red virtual nativa `default`:
   ```bash
   sudo virsh net-start default
   sudo virsh net-autostart default
   ```

2. **Puente de Red Físico (`br0` / Bridged)**:
   Para que las máquinas virtuales tengan su propia dirección IP dentro de la misma red local del host (LAN), se configura un puente de red usando `NetworkManager` (`nmcli`) sobre la interfaz física activa. Además, se registra en Libvirt como `host-bridge`:
   ```bash
   # Definición XML registrada en Libvirt
   <network>
     <name>host-bridge</name>
     <forward mode='bridge'/>
     <bridge name='br0'/>
   </network>
   ```

---

## 4. Ajustes de Rendimiento y Permisos de Usuario

Para simplificar la administración diaria y potenciar el rendimiento del host:

1. **Perfil de Tuning del Host (`tuned`)**:
   Activa el perfil `virtual-host` de la herramienta `tuned` para optimizar la planificación de CPU y memoria de cara a las máquinas virtuales:
   ```bash
   sudo systemctl enable --now tuned
   sudo tuned-adm profile virtual-host
   ```

2. **Permisos sin Sudo**:
   Añade tu usuario al grupo `libvirt` para crear y gestionar máquinas virtuales desde tu entorno sin necesidad de anteponer `sudo`:
   ```bash
   sudo usermod -aG libvirt "$USER"
   ```

3. **Acceso al Almacenamiento mediante Listas de Control de Acceso (ACL)**:
   Para que el usuario pueda mover, crear o modificar archivos de discos virtuales directamente en la ruta protegida `/var/lib/libvirt/images`, se configuran reglas ACL seguras:
   ```bash
   sudo apt install -y acl
   sudo setfacl -R -b /var/lib/libvirt/images
   sudo setfacl -R -m u:"$USER":rwX /var/lib/libvirt/images
   sudo setfacl -d -m u:"$USER":rwX /var/lib/libvirt/images
   ```

4. **Variables de Entorno de Shell**:
   Se define en `~/.bashrc.d/virtualization.sh` el destino por defecto de la shell para que apunte directamente al hipervisor del sistema:
   ```bash
   export LIBVIRT_DEFAULT_URI="qemu:///system"
   ```

---

## Verificación

Para comprobar que el entorno es completamente funcional:

- **Validación del Host**:
  ```bash
  virt-host-validate qemu
  ```
  *(Debe mostrar resultados satisfactorios en la mayoría de sus módulos. Si fallan los módulos KVM, comprueba que la virtualización VT-x/AMD-V esté habilitada en la BIOS/UEFI de tu ordenador).*
- **Destino predeterminado de Libvirt**:
  ```bash
  virsh uri
  # Debería devolver: qemu:///system
  ```
- **Listado de Redes Virtuales**:
  ```bash
  virsh net-list --all
  ```
  *(Debe mostrar activas tanto 'default' como 'host-bridge').*
