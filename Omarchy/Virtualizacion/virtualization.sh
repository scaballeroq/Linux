#!/bin/bash
# virtualization.sh - Instalación y Optimización Avanzada de Virtualización (KVM/QEMU) para Arch Linux

set -euo pipefail

echo "🚀 Configurando entorno de virtualización de alto rendimiento (KVM/QEMU) en Arch Linux..."

TARGET_USER="${SUDO_USER:-$USER}"

# 1. Instalación de paquetes necesarios
echo "ℹ️ Instalando QEMU, libvirt, virt-manager y herramientas auxiliares..."
sudo pacman -S --noconfirm \
    qemu-full \
    libvirt \
    virt-manager \
    virt-viewer \
    dnsmasq \
    dmidecode \
    bridge-utils \
    openbsd-netcat \
    iptables \
    nftables \
    edk2-ovmf \
    swtpm \
    libguestfs \
    tuned \
    ebtables \
    polkit \
    libvirt-dbus \
    virt-install

# 2. Controladores VirtIO para Windows (ISO estable oficial de Fedora)
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

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
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

# 4. Habilitar y configurar libvirt
echo "ℹ️ Habilitando servicio libvirt..."
sudo systemctl enable --now libvirtd.service

# 5. Verificación de capacidades KVM del Host
echo "ℹ️ Verificando soporte de hardware KVM..."
virt-host-validate qemu || echo "⚠️ Advertencia: Revisa que la virtualización VT-x / AMD-V esté habilitada en tu BIOS/UEFI."

# 6. Reglas de Polkit para virt-manager sin contraseña
echo "ℹ️ Configurando reglas de Polkit para el grupo libvirt..."
sudo mkdir -p /etc/polkit-1/rules.d
cat <<'EOF' | sudo tee /etc/polkit-1/rules.d/80-libvirt.rules > /dev/null
/* Permitir gestión completa de libvirt/KVM a los miembros del grupo libvirt */
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
EOF
sudo chmod 644 /etc/polkit-1/rules.d/80-libvirt.rules

# 7. Configuración de Red Virtual y Storage Pool por Defecto
echo "ℹ️ Configurando red virtual NAT por defecto (virbr0)..."
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ Configurando pool de almacenamiento por defecto..."
sudo virsh pool-start default 2>/dev/null || true
sudo virsh pool-autostart default 2>/dev/null || true

# 8. Configuración de Bridge Linux (br0) solo para interfaces Ethernet cableadas
echo "ℹ️ Comprobando compatibilidad de Bridge de red (br0)..."
PHYS_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1 || true)

if [ -n "$PHYS_IFACE" ] && [[ "$PHYS_IFACE" =~ ^(en|eth) ]]; then
    if ! nmcli con show br0 >/dev/null 2>&1; then
        echo "Creando bridge br0 sobre la interfaz Ethernet $PHYS_IFACE..."
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
        sudo virsh net-define /tmp/host-bridge.xml 2>/dev/null || true
        sudo virsh net-start host-bridge 2>/dev/null || true
        sudo virsh net-autostart host-bridge 2>/dev/null || true
        echo "✅ Bridge br0 creado y registrado en libvirt como 'host-bridge'."
    else
        echo "✅ El bridge br0 ya existe, omitiendo creación."
    fi
else
    echo "ℹ️ La conexión principal ($PHYS_IFACE) es inalámbrica (Wi-Fi) o no compatible con bridging directo."
    echo "ℹ️ Las máquinas virtuales utilizarán la red virtual NAT por defecto (virbr0), compatible con Wi-Fi."
fi

# 9. Perfil de Rendimiento Tuned (virtual-host)
echo "ℹ️ Aplicando optimizaciones de rendimiento con tuned (virtual-host)..."
sudo systemctl enable --now tuned.service || true
sudo tuned-adm profile virtual-host || true

# 10. Permisos de Usuario y Listas de Control de Acceso (ACL)
echo "ℹ️ Configurando grupos de usuario (libvirt, kvm)..."
sudo usermod -aG libvirt,kvm "$TARGET_USER" 2>/dev/null || sudo usermod -aG libvirt "$TARGET_USER"

echo "ℹ️ Configurando permisos ACL en el directorio de imágenes (/var/lib/libvirt/images)..."
sudo mkdir -p /var/lib/libvirt/images
sudo setfacl -R -b /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true

# 11. Variable de Entorno LIBVIRT_DEFAULT_URI
echo "ℹ️ Configurando LIBVIRT_DEFAULT_URI en el entorno del usuario..."
mkdir -p ~/.bashrc.d
cat <<EOF > ~/.bashrc.d/virtualization.sh
# Configuración KVM/QEMU conectando al modo de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF

echo "================================================================="
echo "✅ Entorno de Virtualización KVM/QEMU para Arch Linux configurado con éxito."
echo "💡 Recuerda reiniciar o cerrar sesión para aplicar los cambios de grupo (libvirt, kvm)."
echo "================================================================="
