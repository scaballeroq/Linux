#!/bin/bash
# virtualization.sh - Instalación de Virtualización (KVM/QEMU) para CachyOS (Optimizado)

set -euo pipefail

echo "ℹ️ Instalando entornos de virtualización (KVM/QEMU) con Pacman..."
sudo pacman -S --needed --noconfirm \
    qemu-desktop \
    libvirt \
    virt-manager \
    virt-viewer \
    virt-top \
    dnsmasq \
    vde2 \
    bridge-utils \
    openbsd-netcat \
    ebtables \
    iptables-nft \
    ovmf \
    swtpm \
    tuned

echo "ℹ️ Descargando controladores VirtIO para Windows..."
VIRTIO_DIR="$HOME/Descargas/virtio-drivers"
mkdir -p "$VIRTIO_DIR"
if [ ! -f "$VIRTIO_DIR/virtio-win-0.1.271.iso" ]; then
    wget -P "$VIRTIO_DIR" https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.271-1/virtio-win-0.1.271.iso || true
fi

echo "ℹ️ Verificando capacidades de virtualización del host..."
virt-host-validate qemu || echo "⚠️ Advertencia: Algunas validaciones fallaron. Revisa tu BIOS/UEFI (Intel VT-x / AMD-V)."

echo "ℹ️ Configurando servicios de virtualización..."
sudo systemctl enable --now libvirtd.service

echo "ℹ️ Configurando red virtual por defecto..."
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ Configurando bridge de red Linux (br0) para acceso directo a la LAN..."
PHYS_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

if [ -n "$PHYS_IFACE" ] && [ "$PHYS_IFACE" != "br0" ]; then
    if ! nmcli con show br0 >/dev/null 2>&1; then
        echo "Creando bridge br0 sobre la interfaz $PHYS_IFACE..."
        sudo nmcli con add type bridge ifname br0 con-name br0
        sudo nmcli con add type bridge-slave ifname "$PHYS_IFACE" con-name br0-port master br0
        sudo nmcli con modify br0 ipv4.method auto
        
        cat <<EOF > /tmp/host-bridge.xml
<network>
  <name>host-bridge</name>
  <forward mode='bridge'/>
  <bridge name='br0'/>
</network>
EOF
        sudo virsh net-define /tmp/host-bridge.xml
        sudo virsh net-start host-bridge
        sudo virsh net-autostart host-bridge
        echo "✅ Bridge br0 creado y registrado en libvirt como 'host-bridge'."
    else
        echo "✅ El bridge br0 ya existe, omitiendo creación."
    fi
fi

echo "ℹ️ Aplicando optimizaciones de rendimiento (tuned)..."
sudo systemctl enable --now tuned
sudo tuned-adm profile virtual-host

echo "ℹ️ Configurando permisos y grupos..."
TARGET_USER="${SUDO_USER:-$USER}"

sudo usermod -aG libvirt,kvm "$TARGET_USER"

echo "ℹ️ Ajustando permisos ACL en el directorio de imágenes (Optimizado)..."
sudo pacman -S --needed --noconfirm acl
sudo mkdir -p /var/lib/libvirt/images
sudo setfacl -R -b /var/lib/libvirt/images || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images || true

echo "ℹ️ Configurando LIBVIRT_DEFAULT_URI..."
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<EOF > ~/.bashrc.d/virtualization.sh
# Configuración KVM/QEMU conectando al modo de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF
    echo "✅ Configuración modular de Virtualización creada en ~/.bashrc.d/virtualization.sh"
else
    if ! grep -q "LIBVIRT_DEFAULT_URI" ~/.bashrc; then
        echo '' >> ~/.bashrc
        echo '# Configuración KVM/QEMU conectando al modo de sistema por defecto' >> ~/.bashrc
        echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> ~/.bashrc
    fi
fi

echo "✅ Virtualización configurada correctamente. Cierra sesión para aplicar los cambios de grupo."
