#!/bin/bash
# virtualization.sh - Instalación y Optimización Avanzada de Virtualización (KVM/QEMU) para CachyOS
# (Modular Daemons, VirtIO nativo, PipeWire Audio, Nested KVM, Tuned y Bridge de red)

set -euo pipefail

echo "🚀 Configurando entorno de virtualización de alto rendimiento (KVM/QEMU) en CachyOS..."

TARGET_USER="${SUDO_USER:-$USER}"

# 1. Instalación de paquetes necesarios vía Pacman
echo "ℹ️ Instalando QEMU, libvirt, virt-manager y herramientas auxiliares con Pacman..."
sudo pacman -S --needed --noconfirm \
    qemu-desktop \
    libvirt \
    virt-manager \
    virt-viewer \
    virt-top \
    dnsmasq \
    dmidecode \
    bridge-utils \
    openbsd-netcat \
    iptables-nft \
    nftables \
    ovmf \
    swtpm \
    swtpm-tools \
    tuned \
    acl \
    libosinfo 2>/dev/null || true

# Intentar instalar herramientas de monitoreo/utilidades adicionales si están disponibles
sudo pacman -S --needed --noconfirm guestfs-tools libguestfs 2>/dev/null || true

# 2. Controladores VirtIO para Windows (Descarga automática del ISO estable más reciente)
echo "ℹ️ Descargando controladores VirtIO para Windows (virtio-win.iso)..."
VIRTIO_DIR="$HOME/Descargas/virtio-drivers"
mkdir -p "$VIRTIO_DIR"
if [ ! -f "$VIRTIO_DIR/virtio-win.iso" ]; then
    echo "⬇️ Descargando la versión estable más reciente de virtio-win.iso..."
    curl -fsSL -o "$VIRTIO_DIR/virtio-win.iso" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso" 2>/dev/null || true
else
    echo "✅ ISO de VirtIO ya presente en $VIRTIO_DIR/virtio-win.iso"
fi

# 3. Módulos del Kernel, Virtualización Anidada (Nested KVM) y vhost_net/vhost_vsock
echo "ℹ️ Habilitando virtualización anidada (Nested KVM) y aceleración de red..."
sudo mkdir -p /etc/modprobe.d /etc/modules-load.d

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || true)
if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
    echo "options kvm_intel nested=1" | sudo tee /etc/modprobe.d/kvm_intel.conf > /dev/null
    sudo modprobe -r kvm_intel 2>/dev/null || true
    sudo modprobe kvm_intel 2>/dev/null || true
elif [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
    echo "options kvm_amd nested=1" | sudo tee /etc/modprobe.d/kvm_amd.conf > /dev/null
    sudo modprobe -r kvm_amd 2>/dev/null || true
    sudo modprobe kvm_amd 2>/dev/null || true
fi

# Aceleración de red y sockets del Kernel
cat <<EOF | sudo tee /etc/modules-load.d/kvm-vhost.conf > /dev/null
vhost_net
vhost_vsock
EOF
sudo modprobe vhost_net 2>/dev/null || true
sudo modprobe vhost_vsock 2>/dev/null || true

# 4. Ajustes de /etc/libvirt/qemu.conf (Audio PipeWire nativo e integración de usuario)
echo "ℹ️ Configurando usuario y grupo en /etc/libvirt/qemu.conf para soporte de sonido PipeWire..."
if [ -f /etc/libvirt/qemu.conf ]; then
    sudo sed -i "s/^#*user = .*/user = \"$TARGET_USER\"/" /etc/libvirt/qemu.conf 2>/dev/null || true
    sudo sed -i "s/^#*group = .*/group = \"kvm\"/" /etc/libvirt/qemu.conf 2>/dev/null || true
fi

# 5. Ajustes de Firewall Nftables en Libvirt (/etc/libvirt/network.conf)
echo "ℹ️ Configurando backend de firewall nftables en libvirt..."
if [ -f /etc/libvirt/network.conf ]; then
    sudo sed -i 's/^#*firewall_backend = .*/firewall_backend = "nftables"/' /etc/libvirt/network.conf 2>/dev/null || true
fi

# 6. Verificación de capacidades KVM del Host
echo "ℹ️ Verificando soporte de hardware KVM..."
virt-host-validate qemu || echo "⚠️ Advertencia: Revisa que la virtualización VT-x / AMD-V esté habilitada en tu BIOS/UEFI."

# 7. Configuración de Servicios y Sockets Modulares
echo "ℹ️ Habilitando sockets modulares de libvirt (Systemd Socket Activation)..."
if systemctl list-unit-files | grep -q "virtqemud.socket"; then
    sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket 2>/dev/null || true
fi
sudo systemctl enable --now libvirtd.service 2>/dev/null || true

# 8. Configuración de Red Virtual y Storage Pool por Defecto
echo "ℹ️ Configurando red virtual NAT por defecto..."
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ Configurando pool de almacenamiento por defecto..."
sudo virsh pool-start default 2>/dev/null || true
sudo virsh pool-autostart default 2>/dev/null || true

# 9. Configuración de Bridge Linux (br0) opcional para acceso LAN directo
echo "ℹ️ Configurando Bridge de red (br0) para acceso LAN directo..."
PHYS_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1 || true)

if [ -n "$PHYS_IFACE" ] && [ "$PHYS_IFACE" != "br0" ]; then
    if ! nmcli con show br0 >/dev/null 2>&1; then
        echo "Creando bridge br0 sobre la interfaz $PHYS_IFACE..."
        sudo nmcli con add type bridge ifname br0 con-name br0 2>/dev/null || true
        sudo nmcli con add type bridge-slave ifname "$PHYS_IFACE" con-name br0-port master br0 2>/dev/null || true
        sudo nmcli con modify br0 ipv4.method auto 2>/dev/null || true

        cat <<EOF > /tmp/host-bridge.xml
<network>
  <name>host-bridge</name>
  <forward mode='bridge'/>
  <bridge name='br0'/>
</network>
EOF
        sudo virsh net-define /tmp/host-bridge.xml 2>/dev/null || true
        sudo virsh net-start host-bridge 2>/dev/null || true
        sudo virsh net-autostart host-bridge 2>/dev/null || true
        echo "✅ Bridge br0 creado y registrado en libvirt como 'host-bridge'."
    else
        echo "✅ El bridge br0 ya existe, omitiendo creación."
    fi
fi

# 10. Perfil de Rendimiento Tuned (virtual-host) y Deduplicacion de Memoria (UKSMD)
echo "ℹ️ Aplicando optimizaciones de rendimiento con tuned (virtual-host) y UKSMD (ahorro de RAM)..."
sudo pacman -S --needed --noconfirm uksmd 2>/dev/null || true
sudo systemctl enable --now uksmd.service 2>/dev/null || true
sudo systemctl enable --now tuned.service 2>/dev/null || true
sudo tuned-adm profile virtual-host 2>/dev/null || true

# 11. Permisos de Usuario y Listas de Control de Acceso (ACL)
echo "ℹ️ Configurando grupos de usuario (libvirt, kvm)..."
sudo usermod -aG libvirt,kvm "$TARGET_USER" 2>/dev/null || sudo usermod -aG libvirt "$TARGET_USER"

echo "ℹ️ Configurando permisos ACL en el directorio de imágenes (/var/lib/libvirt/images)..."
sudo mkdir -p /var/lib/libvirt/images
sudo setfacl -R -b /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true

# 12. Variable de Entorno LIBVIRT_DEFAULT_URI
echo "ℹ️ Configurando LIBVIRT_DEFAULT_URI en el entorno del usuario..."
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<EOF > ~/.bashrc.d/virtualization.sh
# Configuración KVM/QEMU conectando al modo de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF
    echo "✅ Configuración modular de Virtualización creada en ~/.bashrc.d/virtualization.sh"
else
    if ! grep -q "LIBVIRT_DEFAULT_URI" ~/.bashrc 2>/dev/null; then
        echo '' >> ~/.bashrc
        echo '# Configuración KVM/QEMU conectando al modo de sistema por defecto' >> ~/.bashrc
        echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> ~/.bashrc
    fi
fi

echo "================================================================="
echo "✅ Entorno de Virtualización KVM/QEMU para CachyOS configurado con éxito."
echo "💡 Recuerda reiniciar o cerrar sesión para aplicar los cambios de grupo (libvirt, kvm)."
echo "================================================================="
