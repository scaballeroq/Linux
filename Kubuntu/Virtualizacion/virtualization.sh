#!/bin/bash
# virtualization.sh - Instalación de Virtualización (KVM/QEMU) para Kubuntu (Optimizado)

set -euo pipefail

echo "🚀 Iniciando instalación de virtualización KVM/QEMU en Kubuntu..."

echo "ℹ️ [1/7] Instalando entornos de virtualización (KVM/QEMU) con APT..."
sudo apt update
# Incluye soporte para UEFI (ovmf) y TPM (swtpm) necesarios para Windows 11
sudo apt install -y qemu-system-x86 qemu-kvm libvirt-daemon-system libvirt-clients \
    bridge-utils virtinst virt-manager virt-viewer virt-top libguestfs-tools \
    qemu-utils ovmf swtpm guestfs-tools libosinfo-bin tuned

echo "ℹ️ [2/7] Descargando controladores VirtIO para Windows..."
VIRTIO_DIR="$HOME/Descargas/virtio-drivers"
mkdir -p "$VIRTIO_DIR"
if [ ! -f "$VIRTIO_DIR/virtio-win-0.1.271.iso" ]; then
    wget -P "$VIRTIO_DIR" https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.271-1/virtio-win-0.1.271.iso || true
fi

echo "ℹ️ [3/7] Verificando capacidades de virtualización del host..."
# Validar si el hardware soporta virtualización correctamente
virt-host-validate qemu || echo "⚠️ Advertencia: Algunas validaciones fallaron. Revisa tu BIOS/UEFI (Intel VT-x / AMD-V)."

echo "ℹ️ [4/7] Configurando servicios systemd de libvirt..."
sudo systemctl enable --now libvirtd

echo "ℹ️ [5/7] Configurando red virtual por defecto..."
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ [6/7] Configurando bridge de red Linux (br0) para acceso directo a la LAN..."
# Identificar la interfaz física principal (la que tiene la ruta por defecto)
PHYS_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1 || true)

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
        sudo virsh net-define /tmp/host-bridge.xml 2>/dev/null || true
        sudo virsh net-start host-bridge 2>/dev/null || true
        sudo virsh net-autostart host-bridge 2>/dev/null || true
        echo "✅ Bridge br0 creado y registrado en libvirt como 'host-bridge'."
    else
        echo "✅ El bridge br0 ya existe, omitiendo creación."
    fi
fi

# Aplicar optimizaciones de rendimiento con tuned
if command -v tuned-adm &> /dev/null; then
    echo "ℹ️ Aplicando perfil de rendimiento tuned (virtual-host)..."
    sudo systemctl enable --now tuned || true
    sudo tuned-adm profile virtual-host || true
fi

echo "ℹ️ [7/7] Configurando permisos, grupos y ACLs..."
TARGET_USER="${SUDO_USER:-$USER}"

# Añadir a grupos libvirt y kvm para gestión sin sudo
sudo usermod -aG libvirt,kvm "$TARGET_USER"

# Ajustar ACLs en /var/lib/libvirt/images
sudo apt install -y acl
sudo mkdir -p /var/lib/libvirt/images
sudo setfacl -R -b /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true

# Configuración modular de LIBVIRT_DEFAULT_URI
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<'EOF' > ~/.bashrc.d/virtualization.sh
# Configuración KVM/QEMU conectando al modo de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF
    echo "✅ Configuración modular de Virtualización creada en ~/.bashrc.d/virtualization.sh"
else
    if ! grep -q "LIBVIRT_DEFAULT_URI" ~/.bashrc; then
        echo -e '\n# Configuración KVM/QEMU conectando al modo de sistema por defecto\nexport LIBVIRT_DEFAULT_URI="qemu:///system"' >> ~/.bashrc
    fi
fi

echo "✅ Virtualización KVM/QEMU en Kubuntu configurada correctamente. Cierra sesión y vuelve a iniciar para aplicar los cambios de grupo."
