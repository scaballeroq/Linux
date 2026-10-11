# Manual de Virtualización de Alto Rendimiento (KVM/QEMU) en openSUSE Tumbleweed

Este manual detalla la configuración y optimización de **KVM / QEMU** para **openSUSE Tumbleweed**, integrando tanto la **Consola Web Cockpit (`cockpit-machines`)** como la interfaz de escritorio **Virt-Manager** bajo **KDE Plasma 6 (Wayland)**, con aceleración por hardware AMD Ryzen 7 PRO (AVIC/NPT), gráficos AMD Radeon Vega (VirGL 3D), deduplicación KSM, optimización Btrfs NoCoW y reglas Polkit.

---

## 1. Vías de Gestión Disponibles

El entorno está preparado para coexistir con dos interfaces complementarias:

| Interfaz | Tipo | Acceso | Ideal para |
| :--- | :--- | :--- | :--- |
| **Cockpit Machines** | Web Console | `https://localhost:9090` o `https://<IP-HOST>:9090` | Creación rápida de VMs, arranque/parada, monitorización web de CPU/RAM, gestión remota desde cualquier navegador. |
| **Virt-Manager** | GUI de Escritorio | Lanzador KDE o comando `virt-manager` | Configuración avanzada de hardware, gráficos 3D acelerados (VirGL/OpenGL), redirección USB directa, VirtIO-FS y audio nativo. |

---

## 2. Paquetes Oficiales en openSUSE Tumbleweed

En openSUSE Tumbleweed, los paquetes están integrados directamente en el repositorio oficial `repo-oss`:

```bash
sudo zypper --non-interactive install -y \
    qemu qemu-x86 qemu-tools qemu-ovmf-x86_64 qemu-ksm \
    libvirt libvirt-daemon-config-network libvirt-client \
    virt-manager virt-viewer virt-install virt-top \
    libvirglrenderer1 cockpit cockpit-machines cockpit-ws cockpit-bridge \
    virtiofsd spice-vdagent usbredir swtpm libosinfo \
    dnsmasq dmidecode tuned acl guestfs-tools nftables
```

> [!NOTE]
> El paquete `libvirt-daemon-config-network` es fundamental en openSUSE: suministra los archivos de configuración inicial para la red NAT predeterminada (`virbr0`).
> Asimismo, el paquete de aceleración 3D para la GPU se denomina `libvirglrenderer1`.

---

## 3. Aceleración del Kernel y Virtualización Anidada (Nested KVM)

### Extensiones de CPU AMD Ryzen (Zen 2):
Archivo `/etc/modprobe.d/kvm_amd.conf`:
```ini
# Optimización KVM para procesadores AMD Ryzen / Zen
options kvm_amd nested=1 avic=1 npt=1
```
- **`nested=1`**: Permite ejecutar máquinas virtuales o contenedores con KVM dentro de las VMs invitadas.
- **`avic=1`**: *Advanced Virtual Interrupt Controller*, reduce la sobrecarga de interrupciones en procesadores AMD.
- **`npt=1`**: *Nested Page Tables*, traslación de memoria por hardware a máxima velocidad.

### Aceleración de Red y Sockets del Kernel:
Archivo `/etc/modules-load.d/kvm-vhost.conf`:
```ini
vhost_net
vhost_vsock
tun
```
Cargar inmediatamente:
```bash
sudo modprobe vhost_net vhost_vsock tun
```

---

## 4. Almacenamiento Btrfs NoCoW (+C) para Imágenes de Disco

En sistemas de archivos Btrfs (predeterminado en openSUSE), el mecanismo Copy-on-Write provoca fragmentación severa y reduce drásticamente las IOPS en imágenes de disco `.qcow2` o `.raw`. Se desactiva CoW en el pool de almacenamiento:

```bash
sudo mkdir -p /var/lib/libvirt/images
sudo chattr +C /var/lib/libvirt/images
```

---

## 5. Sockets Modulares de Libvirt y Cockpit (Systemd)

openSUSE Tumbleweed utiliza la arquitectura de daemons modulares bajo demanda:

```bash
# Detener/deshabilitar el servicio monolítico libvirtd heredado si existiera
sudo systemctl stop libvirtd.service libvirtd.socket 2>/dev/null || true
sudo systemctl disable libvirtd.service libvirtd.socket 2>/dev/null || true

# Habilitar sockets modulares de Libvirt y el servicio Cockpit
sudo systemctl enable --now \
    virtqemud.socket \
    virtnetworkd.socket \
    virtstoraged.socket \
    virtnodedevd.socket \
    virtnwfilterd.socket \
    virtsecretd.socket \
    virtproxyd.socket \
    cockpit.socket
```

---

## 6. Integración con Firewalld y Backend Nftables

En openSUSE Tumbleweed, libvirt utiliza `nftables` de forma nativa.
Archivo `/etc/libvirt/network.conf`:
```ini
firewall_backend = "nftables"
```

Reglas en Firewalld para el servicio web Cockpit y el puente virtual `virbr0`:
```bash
# Permitir Cockpit en la zona predeterminada
sudo firewall-cmd --permanent --add-service=cockpit

# Configurar zona libvirt y enmascaramiento NAT
sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0
sudo firewall-cmd --permanent --zone=libvirt --add-forward
sudo firewall-cmd --permanent --add-masquerade
sudo firewall-cmd --reload
```

---

## 7. Regla Polkit sin Contraseña para KDE Plasma y Cockpit

Permite a los usuarios del grupo `libvirt` administrar máquinas virtuales sin continuos cuadros de diálogo solicitando la contraseña de root:

Archivo `/etc/polkit-1/rules.d/50-libvirt.rules`:
```javascript
/* Permitir a usuarios en el grupo libvirt gestionar la virtualización sin pedir contraseña */
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
```

---

## 8. Permisos de Usuario y Deduplicación de Memoria KSM

```bash
# Añadir usuario a los grupos libvirt, kvm y render (aceleración 3D en /dev/dri/renderD128)
sudo usermod -aG libvirt,kvm,render $USER

# Asignar permisos ACL en la carpeta de imágenes
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

### Deduplicación de Memoria RAM (KSM):
Archivo `/etc/tmpfiles.d/ksm.conf`:
```ini
w /sys/kernel/mm/ksm/run - - - - 1
w /sys/kernel/mm/ksm/sleep_millisecs - - - - 100
```

### Perfil Tuned para Host de Virtualización:
```bash
sudo systemctl enable --now tuned.service
sudo tuned-adm profile virtual-host
```

---

## 9. Configuración del URI de Conexión por Defecto

Para que `virsh` y las herramientas de usuario conecten directamente al socket de sistema:

- En `~/.config/environment.d/10-libvirt.conf`:
  ```ini
  LIBVIRT_DEFAULT_URI=qemu:///system
  ```
- En `~/.bashrc.d/virtualization.sh` y `~/.zshrc.d/virtualization.zsh`:
  ```bash
  export LIBVIRT_DEFAULT_URI="qemu:///system"
  ```

---

## 10. Uso del Script Automatizado `virtualization.sh`

```bash
# Diagnóstico completo sin modificar el sistema:
./virtualization.sh --status

# Ejecución completa con privilegios administrativos:
sudo ./virtualization.sh

# Instalación incluyendo descarga de controladores VirtIO para Windows:
sudo ./virtualization.sh --with-windows

# Ver ayuda y opciones:
./virtualization.sh --help
```

> [!IMPORTANT]
> Tras ejecutar el script por primera vez con `sudo`, es necesario cerrar sesión en KDE Plasma y volver a iniciarla (o reiniciar) para que los nuevos grupos (`libvirt`, `kvm`, `render`) se apliquen a tu sesión de usuario.
