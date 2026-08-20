#!/bin/bash
# virtualization.sh - Instalación y Optimización Avanzada de Virtualización (KVM/QEMU) para OpenSUSE Tumbleweed con GNOME

set -euo pipefail

echo "🚀 Configurando entorno de virtualización de alto rendimiento (KVM/QEMU) en OpenSUSE Tumbleweed..."

TARGET_USER="${SUDO_USER:-$USER}"

# 1. Instalación de paquetes necesarios
echo "ℹ️ Instalando QEMU, libvirt, virt-manager y herramientas auxiliares vía Zypper..."
sudo zypper --non-interactive install -y -t pattern kvm_server kvm_tools 2>/dev/null || true
sudo zypper --non-interactive install -y \
    qemu-kvm \
    qemu-tools \
    libvirt \
    libvirt-daemon-driver-qemu \
    libvirt-daemon-driver-network \
    libvirt-daemon-driver-storage \
    virt-manager \
    virt-viewer \
    virt-install \
    dnsmasq \
    dmidecode \
    bridge-utils \
    ovmf \
    swtpm \
    libosinfo \
    guestfs-tools \
    tuned \
    acl 2>/dev/null || true

# 2. Controladores VirtIO para Windows (ISO estable oficial)
echo "ℹ️ Descargando controladores VirtIO para Windows (virtio-win.iso)..."
VIRTIO_DIR="$HOME/Descargas/virtio-drivers"
mkdir -p "$VIRTIO_DIR"
if [ ! -f "$VIRTIO_DIR/virtio-win.iso" ]; then
    echo "⬇️ Descargando la versión estable más reciente de virtio-win.iso..."
    curl -fsSL -o "$VIRTIO_DIR/virtio-win.iso" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso" || true
else
    echo "✅ ISO de VirtIO ya presente en $VIRTIO_DIR/virtio-win.iso"
fi

# 3. Módulos del Kernel, Virtualización Anidada (Nested KVM) y vhost_net/vhost_vsock
echo "ℹ️ Habilitando virtualización anidada (Nested KVM) y aceleración de red (vhost_net, vhost_vsock)..."
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

# 5. Verificación de capacidades KVM del Host
echo "ℹ️ Verificando soporte de hardware KVM..."
virt-host-validate qemu 2>/dev/null || echo "ℹ️ Verifica que la virtualización esté habilitada en tu BIOS/UEFI."

# 6. Configuración de Servicios y Sockets Modulares
echo "ℹ️ Habilitando servicios de libvirt..."
if systemctl list-unit-files | grep -q "virtqemud.socket"; then
    sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket 2>/dev/null || true
fi
sudo systemctl enable --now libvirtd.service 2>/dev/null || true

# 7. Configuración de Red Virtual y Storage Pool por Defecto
echo "ℹ️ Configurando red virtual NAT por defecto..."
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ Configurando pool de almacenamiento por defecto..."
sudo virsh pool-start default 2>/dev/null || true
sudo virsh pool-autostart default 2>/dev/null || true

# 8. Perfil de Rendimiento Tuned (virtual-host)
echo "ℹ️ Aplicando optimizaciones de rendimiento con tuned (virtual-host)..."
sudo systemctl enable --now tuned.service 2>/dev/null || true
sudo tuned-adm profile virtual-host 2>/dev/null || true

# 9. Permisos de Usuario y Listas de Control de Acceso (ACL)
echo "ℹ️ Configurando grupos de usuario (libvirt, kvm)..."
sudo usermod -aG libvirt,kvm "$TARGET_USER" 2>/dev/null || sudo usermod -aG libvirt "$TARGET_USER" 2>/dev/null || true

echo "ℹ️ Configurando permisos ACL en el directorio de imágenes (/var/lib/libvirt/images)..."
sudo mkdir -p /var/lib/libvirt/images
sudo setfacl -R -b /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true

# 10. Variable de Entorno LIBVIRT_DEFAULT_URI
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
echo "✅ Entorno de Virtualización KVM/QEMU para OpenSUSE Tumbleweed configurado con éxito."
echo "💡 Recuerda reiniciar o cerrar sesión para aplicar los grupos (libvirt, kvm)."
echo "================================================================="
