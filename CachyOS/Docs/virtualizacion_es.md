# Instalación y Configuración de Virtualización (KVM/QEMU) en CachyOS

Este manual está optimizado para **CachyOS** (basado en Arch Linux). Utiliza el esquema estándar de `libvirt` integrado con el sistema.

## 1. Instalación de Paquetes
Instalamos KVM, libvirt, virt-manager y utilidades asociadas vía `pacman`.

```bash
sudo pacman -S --needed --noconfirm qemu-desktop libvirt virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat iptables-nft edk2-ovmf swtpm tuned virglrenderer virtiofsd
```

## 2. Controladores de Windows (VirtIO)
Descarga la ISO oficial de controladores VirtIO desde el proyecto Fedora:

- [Descargar virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)

## 3. Configuración de Servicios
En Libvirt moderno (12+) se recomiendan los sockets modulares bajo demanda:

```bash
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket virtnodedevd.socket virtproxyd.socket
```

## 4. Permisos de Grupo
Añadimos tu usuario a los grupos clave (`libvirt`, `kvm`).

```bash
sudo usermod -aG libvirt,kvm $USER
```

## 5. Accesibilidad de Directorio (ACL)
```bash
sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images
sudo setfacl -d -m u:$USER:rwX /var/lib/libvirt/images
```

## 6. Configuración de Red y Firewall (NAT)
Para que las máquinas virtuales tengan salida a Internet mediante la red NAT por defecto (`virbr0`):

1. **Firewalld**: Habilitar el reenvío de tráfico y masquerading:
   ```bash
   sudo firewall-cmd --permanent --zone=libvirt --add-forward
   sudo firewall-cmd --permanent --zone=public --add-masquerade
   sudo firewall-cmd --reload
   ```

2. **Evitar conflictos con UFW**:
   Si `ufw` está activo en paralelo a Firewalld, bloqueará por defecto el tráfico de `virbr0` y las interfaces virtuales (`vnet*`). Se recomienda desactivarlo:
   ```bash
   sudo systemctl disable --now ufw
   ```

3. **Backend de Libvirt**:
   Con Firewalld activo, se recomienda `firewall_backend = "iptables"` (utiliza la capa de traducción `iptables-nft`):
   ```bash
   sudo sed -i 's/^#*firewall_backend = .*/firewall_backend = "iptables"/' /etc/libvirt/network.conf
   sudo systemctl restart virtnetworkd.service
   ```

4. **Solución en la consola del instalador de Arch Linux (Guest)**:
   Si al iniciar la ISO de Arch Linux no tienes IP asignada:
   ```bash
   # Comprueba el nombre de la interfaz (ej. ens3 o enp1s0)
   ip a
   # Reinicia el servicio de red para solicitar IP por DHCP
   systemctl restart systemd-networkd
   # Verifica la conectividad
   ping -c 3 archlinux.org
   ```

## 7. Verificación Final
```bash
sudo virt-host-validate qemu
sudo virsh net-list --all
virsh uri
```
