#!/bin/bash
# virtualization.sh - Virtualization (KVM/QEMU) Installation for Fedora 44

set -e

echo "ℹ️ Instalando entornos de virtualización (KVM/QEMU/Libvirt) con DNF5..."
sudo dnf5 group install -y --with-optional "Virtualization"
sudo dnf5 install -y virt-manager virt-top virt-install libguestfs-tools guestfs-tools

echo "ℹ️ Instalando controladores VirtIO para Windows (desde repos oficiales de Fedora)..."
sudo dnf5 install -y virtio-win

echo "ℹ️ Configurando servicios modulares (Systemd Socket Activation)..."
# Fedora 44 prioriza demonios modulares para mayor seguridad y menor consumo
# Habilitamos solo los sockets; se activarán cuando se necesiten.
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket

echo "ℹ️ Verificando capacidades de virtualización del host..."
# Validar si el hardware soporta virtualización correctamente
virt-host-validate qemu || echo "⚠️ Advertencia: Algunas validaciones fallaron. Revisa tu BIOS/UEFI (Intel VT-x / AMD-V)."

echo "ℹ️ Configurando permisos y grupos..."
TARGET_USER="${SUDO_USER:-$USER}"

# Añadir a grupos libvirt y kvm
sudo usermod -aG libvirt,kvm "$TARGET_USER"

echo "ℹ️ Ajustando permisos ACL en el directorio de imágenes (Optimizado)..."
# Limpiar y reasignar ACLs para que el usuario pueda manejar discos sin sudo
sudo mkdir -p /var/lib/libvirt/images
sudo setfacl -R -b /var/lib/libvirt/images || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images || true

# Configuración de rendimiento (Opcional pero recomendada para desarrollo)
echo "ℹ️ Configurando LIBVIRT_DEFAULT_URI en ~/.bashrc..."
if ! grep -q "LIBVIRT_DEFAULT_URI" ~/.bashrc 2>/dev/null; then
    cat <<EOF >> ~/.bashrc

# Configuración KVM/QEMU conectando al modo de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF
fi

echo "✅ Virtualización configurada correctamente. Cierra sesión para aplicar los cambios de grupo."
