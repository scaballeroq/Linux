#!/bin/bash
# virtualization.sh - Instalación y Optimización de Virtualización (KVM/QEMU) para Manjaro Linux

set -euo pipefail

echo "🚀 Configurando entorno de virtualización de alto rendimiento (KVM/QEMU) en Manjaro Linux..."

# 1. Instalación de paquetes necesarios
echo "ℹ️ Instalando QEMU, libvirt, virt-manager y herramientas auxiliares vía Pacman..."
sudo pacman -S --needed --noconfirm \
    qemu-desktop \
    libvirt \
    virt-manager \
    virt-viewer \
    dnsmasq \
    dmidecode \
    vde2 \
    bridge-utils \
    openbsd-netcat \
    iptables-nft \
    nftables \
    ovmf \
    swtpm \
    tuned 2>/dev/null || sudo pacman -S --needed --noconfirm qemu-desktop libvirt virt-manager virt-viewer dnsmasq ovmf swtpm || true

# 2. Controladores VirtIO para Windows
echo "ℹ️ Descargando controladores VirtIO para Windows (virtio-win.iso)..."
VIRTIO_DIR="$HOME/Descargas/virtio-drivers"
mkdir -p "$VIRTIO_DIR"
if [ ! -f "$VIRTIO_DIR/virtio-win.iso" ]; then
    echo "⬇️ Descargando la versión estable más reciente de virtio-win.iso..."
    curl -fsSL -o "$VIRTIO_DIR/virtio-win.iso" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso" || true
else
    echo "✅ ISO de VirtIO ya presente en $VIRTIO_DIR/virtio-win.iso"
fi

# 3. Módulos del Kernel y Virtualización Anidada (Nested Virtualization)
echo "ℹ️ Habilitando virtualización anidada (Nested KVM) y aceleración de red (vhost_net)..."
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

echo "vhost_net" | sudo tee /etc/modules-load.d/kvm-vhost.conf > /dev/null
sudo modprobe vhost_net 2>/dev/null || true

# 4. Verificación de capacidades KVM del Host
echo "ℹ️ Verificando soporte de virtualización por hardware..."
if grep -E -c '(vmx|svm)' /proc/cpuinfo > /dev/null; then
    echo "✅ Soporte VT-x/AMD-V detectado en el procesador."
else
    echo "⚠️ Advertencia: No se detectó VT-x/AMD-V en /proc/cpuinfo. Verifica la BIOS/UEFI."
fi

# 5. Configurar permisos y grupos de usuario
TARGET_USER="${SUDO_USER:-$USER}"
echo "ℹ️ Añadiendo al usuario '$TARGET_USER' a los grupos libvirt y kvm..."
sudo usermod -aG libvirt,kvm "$TARGET_USER"

# 6. Habilitar e iniciar demonios de Libvirt y Sockets modulares
echo "ℹ️ Habilitando servicios modulares de libvirt en systemd..."
sudo systemctl enable --now libvirtd.service 2>/dev/null || true
sudo systemctl enable --now virtqemud.socket 2>/dev/null || true
sudo systemctl enable --now virtnetworkd.socket 2>/dev/null || true
sudo systemctl enable --now virtstoraged.socket 2>/dev/null || true

# 7. Iniciar y autoiniciar la red virtual por defecto (NAT: virbr0)
echo "ℹ️ Configurando red NAT virtual (default)..."
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
echo "🎉 ¡Entorno de virtualización KVM/QEMU configurado en Manjaro!"
echo "💡 Recuerda reiniciar sesión para que los permisos del grupo 'libvirt' surtan efecto."
echo "================================================================="
