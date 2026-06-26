#!/bin/bash
# virtualization.sh - Virtualization (KVM/QEMU) Installation for Arch Linux

set -e

echo "ℹ️ Instalando entornos de virtualización (KVM/QEMU/Libvirt)..."
sudo pacman -S --noconfirm libvirt qemu-base qemu-desktop bridge-utils virt-top python-virtinst libguestfs ebtables dnsmasq

echo "ℹ️ Instalando controladores VirtIO para Windows..."
VIRTIO_DIR="/usr/share/virtio-win"
if [ ! -d "$VIRTIO_DIR" ]; then
    sudo mkdir -p "$VIRTIO_DIR"
    echo "ℹ️ Descargando VirtIO drivers para Windows..."
    VIRTIO_ISO=$(curl -sL https://api.github.com/repos/virtio-win/virtio-win-pkg-scripts/releases/latest | grep -oP '"browser_download_url": "\K[^"]*\.iso')
    sudo curl -L -o /usr/share/virtio-win/virtio-win.iso "$VIRTIO_ISO"
fi

echo "ℹ️ Habilitando servicio Libvirt..."
sudo systemctl enable --now libvirtd.service

echo "ℹ️ Verificando capacidades de virtualización del host..."
virt-host-validate qemu || echo "⚠️ Advertencia: Algunas validaciones fallaron. Revisa tu BIOS/UEFI (Intel VT-x / AMD-V)."

echo "ℹ️ Configurando permisos y grupos..."
TARGET_USER="${SUDO_USER:-$USER}"

sudo usermod -aG libvirt,kvm "$TARGET_USER"

echo "ℹ️ Ajustando permisos ACL en el directorio de imágenes..."
sudo mkdir -p /var/lib/libvirt/images
sudo setfacl -R -b /var/lib/libvirt/images || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images || true

echo "ℹ️ Configurando LIBVIRT_DEFAULT_URI de forma modular..."
mkdir -p ~/.bashrc.d
cat <<EOF > ~/.bashrc.d/virtualization.sh
# Configuración KVM/QEMU conectando al modo de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF

echo "✅ Virtualización configurada correctamente. Cierra sesión para aplicar los cambios de grupo."
