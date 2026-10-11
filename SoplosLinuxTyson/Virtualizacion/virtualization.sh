#!/usr/bin/env bash
# =============================================================================
# virtualization.sh - Instalación y Optimización de Virtualización KVM/QEMU
# Soplos Linux Tyson (Debian Testing / Trixie - Portátil & Estación de Trabajo)
# =============================================================================
# Configura KVM, QEMU, libvirt, virt-manager, audio PipeWire nativo,
# virtualización anidada, firewall nftables y controladores VirtIO.
# =============================================================================

set -euo pipefail

echo "🚀 Configurando entorno de virtualización KVM/QEMU en Soplos Linux Tyson..."

# Detectar usuario real y directorio home (incluso si se ejecuta con sudo)
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
TARGET_HOME="${TARGET_HOME:-$HOME}"

# 1. Instalación de paquetes necesarios
echo "ℹ️ Instalando QEMU, libvirt, virt-manager, UEFI (OVMF), TPM 2.0 y herramientas..."
sudo apt update
sudo apt install -y \
    qemu-system-x86 \
    qemu-utils \
    libvirt-daemon-system \
    libvirt-clients \
    virt-manager \
    virt-viewer \
    virtinst \
    dnsmasq \
    dmidecode \
    netcat-openbsd \
    iptables \
    nftables \
    ovmf \
    swtpm \
    libosinfo-bin \
    guestfs-tools \
    spice-vdagent \
    acl

# 2. Controladores VirtIO para Windows (ISO estable oficial de Fedora)
echo "ℹ️ Descargando controladores VirtIO para Windows (virtio-win.iso)..."
VIRTIO_DIR="$TARGET_HOME/Descargas/virtio-drivers"
mkdir -p "$VIRTIO_DIR"
if [ ! -f "$VIRTIO_DIR/virtio-win.iso" ]; then
    echo "⬇️ Descargando la versión estable más reciente de virtio-win.iso..."
    curl -fsSL -o "$VIRTIO_DIR/virtio-win.iso" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso" || true
else
    echo "✅ ISO de VirtIO ya presente en $VIRTIO_DIR/virtio-win.iso"
fi
chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/Descargas/virtio-drivers" 2>/dev/null || true

# 3. Módulos del Kernel, Virtualización Anidada (Nested KVM) y vhost_net/vhost_vsock
echo "ℹ️ Habilitando virtualización anidada (Nested KVM) y aceleración de red/sockets..."
sudo mkdir -p /etc/modprobe.d /etc/modules-load.d

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' 2>/dev/null || echo "")
if [ "$CPU_VENDOR" = "GenuineIntel" ]; then
    echo "options kvm_intel nested=1" | sudo tee /etc/modprobe.d/kvm_intel.conf > /dev/null
    sudo modprobe -r kvm_intel 2>/dev/null || true
    sudo modprobe kvm_intel 2>/dev/null || true
elif [ "$CPU_VENDOR" = "AuthenticAMD" ]; then
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
echo "ℹ️ Configurando usuario y grupo en /etc/libvirt/qemu.conf para soporte de audio PipeWire..."
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
virt-host-validate qemu 2>/dev/null || echo "⚠️ Advertencia: Revisa que la virtualización VT-x / AMD-V esté habilitada en tu BIOS/UEFI."

# 7. Configuración de Servicios y Sockets Modulares de Libvirt
echo "ℹ️ Habilitando servicios y sockets modulares de libvirt en systemd..."
if systemctl list-unit-files | grep -q "virtqemud.socket"; then
    sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket virtnodedevd.socket 2>/dev/null || true
else
    sudo systemctl enable --now libvirtd.service 2>/dev/null || true
fi

# 8. Configuración de Red Virtual NAT (default) y Storage Pool por Defecto
echo "ℹ️ Configurando red virtual NAT por defecto (virbr0)..."
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ Configurando pool de almacenamiento por defecto..."
sudo virsh pool-start default 2>/dev/null || true
sudo virsh pool-autostart default 2>/dev/null || true

# 9. Permisos de Usuario y Listas de Control de Acceso (ACL)
echo "ℹ️ Configurando grupos de usuario ($TARGET_USER en libvirt, kvm)..."
sudo usermod -aG libvirt,kvm "$TARGET_USER" 2>/dev/null || sudo usermod -aG libvirt "$TARGET_USER"

echo "ℹ️ Configurando permisos ACL en el directorio de imágenes (/var/lib/libvirt/images)..."
sudo mkdir -p /var/lib/libvirt/images
sudo setfacl -R -b /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true

# 10. Variable de Entorno LIBVIRT_DEFAULT_URI (Modular para Bash y Zsh)
echo "ℹ️ Configurando LIBVIRT_DEFAULT_URI para el usuario $TARGET_USER..."

# Configuración en ~/.bashrc.d
mkdir -p "$TARGET_HOME/.bashrc.d"
cat <<'EOF' > "$TARGET_HOME/.bashrc.d/virtualization.sh"
# Configuración KVM/QEMU: Conectar automáticamente al hipervisor del sistema
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF

# Configuración en ~/.zshrc.d si existe o se usa
if [ -d "$TARGET_HOME/.zshrc.d" ]; then
    ln -sf "$TARGET_HOME/.bashrc.d/virtualization.sh" "$TARGET_HOME/.zshrc.d/virtualization.sh"
fi

chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.bashrc.d" "$TARGET_HOME/.zshrc.d" 2>/dev/null || true

echo "================================================================="
echo "✅ Entorno de Virtualización KVM/QEMU configurado con éxito."
echo "💡 Recuerda cerrar sesión o reiniciar el portátil para aplicar los grupos (libvirt, kvm)."
echo "================================================================="
