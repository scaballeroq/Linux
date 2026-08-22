#!/bin/bash
# virtualization.sh - Instalación y Optimización de Virtualización (KVM/QEMU) para Manjaro Linux
set -euo pipefail

echo "🚀 Configurando entorno de virtualización de alto rendimiento (KVM/QEMU) en Manjaro Linux..."

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
[[ -z "$TARGET_HOME" ]] && TARGET_HOME="$HOME"

# 1. Verificación de capacidades KVM del Host
echo "ℹ️ Verificando soporte de virtualización por hardware en el procesador..."
if grep -q -E '(vmx|svm)' /proc/cpuinfo; then
    echo "✅ Soporte VT-x/AMD-V detectado correctamente."
else
    echo "⚠️ Advertencia: No se detectó VT-x/AMD-V en /proc/cpuinfo. Verifica que esté habilitado en la BIOS/UEFI."
fi

# 2. Instalación de paquetes necesarios en Manjaro
echo "ℹ️ Instalando paquetes de virtualización vía Pacman..."
PACKAGES=(
    qemu-desktop
    libvirt
    virt-manager
    virt-viewer
    dnsmasq
    dmidecode
    iptables-nft
    nftables
    ovmf
    swtpm
    openbsd-netcat
    bridge-utils
    vde2
)

# Tuned opcional si está disponible en repositorios
if pacman -Si tuned &>/dev/null; then
    PACKAGES+=(tuned)
fi

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# 3. Controladores VirtIO para Windows
echo "ℹ️ Comprobando controladores VirtIO para Windows (virtio-win.iso)..."
VIRTIO_DIR="${TARGET_HOME}/Descargas/virtio-drivers"
mkdir -p "$VIRTIO_DIR"

if [ ! -f "$VIRTIO_DIR/virtio-win.iso" ]; then
    echo "⬇️ Descargando la versión estable más reciente de virtio-win.iso en $VIRTIO_DIR..."
    curl -fsSL -o "$VIRTIO_DIR/virtio-win.iso" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso" || true
    chown -R "$TARGET_USER:" "$VIRTIO_DIR" 2>/dev/null || true
else
    echo "✅ ISO de VirtIO ya presente en $VIRTIO_DIR/virtio-win.iso"
fi

# 4. Módulos del Kernel y Virtualización Anidada (Nested KVM)
echo "ℹ️ Habilitando virtualización anidada (Nested KVM) y aceleración de red (vhost_net)..."
sudo mkdir -p /etc/modprobe.d /etc/modules-load.d

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || true)
if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
    echo "options kvm_intel nested=1" | sudo tee /etc/modprobe.d/kvm_intel.conf > /dev/null
    sudo modprobe -r kvm_intel 2>/dev/null || true
    sudo modprobe kvm_intel 2>/dev/null || true
elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
    echo "options kvm_amd nested=1" | sudo tee /etc/modprobe.d/kvm_amd.conf > /dev/null
    sudo modprobe -r kvm_amd 2>/dev/null || true
    sudo modprobe kvm_amd 2>/dev/null || true
fi

echo "vhost_net" | sudo tee /etc/modules-load.d/kvm-vhost.conf > /dev/null
sudo modprobe vhost_net 2>/dev/null || true

# 5. Configurar permisos, grupos y URI por defecto
echo "ℹ️ Añadiendo al usuario '$TARGET_USER' a los grupos libvirt y kvm..."
sudo usermod -aG libvirt,kvm "$TARGET_USER"

sudo mkdir -p /etc/libvirt
if [ -f /etc/libvirt/libvirt.conf ]; then
    if ! grep -q 'uri_default' /etc/libvirt/libvirt.conf; then
        echo 'uri_default = "qemu:///system"' | sudo tee -a /etc/libvirt/libvirt.conf > /dev/null
    fi
else
    echo 'uri_default = "qemu:///system"' | sudo tee /etc/libvirt/libvirt.conf > /dev/null
fi

# 6. Sockets modulares de Libvirt en Manjaro (Arquitectura recomendada)
echo "ℹ️ Configurando y habilitando sockets modulares de libvirt en systemd..."
# Desactivar servicio monolítico para prevenir conflictos de sockets
sudo systemctl stop libvirtd.service libvirtd.socket 2>/dev/null || true
sudo systemctl disable libvirtd.service libvirtd.socket 2>/dev/null || true

MODULAR_SOCKETS=(
    virtqemud.socket
    virtnetworkd.socket
    virtstoraged.socket
    virtnodedevd.socket
    virtsecretd.socket
    virtnwfilterd.socket
    virtlogd.socket
    virtlockd.socket
)

for sock in "${MODULAR_SOCKETS[@]}"; do
    sudo systemctl enable --now "$sock" 2>/dev/null || true
done

# 7. Red NAT Virtual por defecto (default / virbr0)
echo "ℹ️ Configurando red NAT virtual (default)..."
if ! sudo virsh net-info default &>/dev/null; then
    if [ -f /etc/libvirt/qemu/networks/default.xml ]; then
        sudo virsh net-define /etc/libvirt/qemu/networks/default.xml 2>/dev/null || true
    fi
fi
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

# 8. Backend de Firewall nftables para Libvirt
if [ -f /etc/libvirt/network.conf ]; then
    if ! grep -q "firewall_backend" /etc/libvirt/network.conf; then
        echo 'firewall_backend = "nftables"' | sudo tee -a /etc/libvirt/network.conf > /dev/null
    fi
fi

# 9. Configuración de perfil Tuned para Host de Máquinas Virtuales
if command -v tuned-adm &> /dev/null; then
    echo "ℹ️ Aplicando perfil de optimización 'virtual-host' en Tuned..."
    sudo systemctl enable --now tuned.service || true
    sudo tuned-adm profile virtual-host || true
fi

echo "================================================================="
echo "🎉 ¡Entorno de virtualización KVM/QEMU 100% optimizado para Manjaro!"
echo "💡 Recuerda reiniciar sesión para que los permisos del grupo 'libvirt' surtan efecto."
echo "================================================================="
