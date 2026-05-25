#!/bin/bash
# virtualization.sh - Instalación de Virtualización (KVM/QEMU) para Kubuntu (Optimizado)

set -e

echo "ℹ️ Instalando entornos de virtualización (KVM/QEMU) con APT..."
sudo apt update
# Incluye soporte para UEFI (ovmf) y TPM (swtpm) necesarios para Windows 11
sudo apt install -y qemu-system-x86 qemu-kvm libvirt-daemon-system libvirt-clients \
    bridge-utils virtinst virt-manager virt-viewer virt-top libguestfs-tools \
    qemu-utils ovmf swtpm guestfs-tools libosinfo-bin tuned

echo "ℹ️ Descargando controladores VirtIO para Windows..."
VIRTIO_DIR="$HOME/Descargas/virtio-drivers"
mkdir -p "$VIRTIO_DIR"
if [ ! -f "$VIRTIO_DIR/virtio-win-0.1.271.iso" ]; then
    wget -P "$VIRTIO_DIR" https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.271-1/virtio-win-0.1.271.iso
fi

echo "ℹ️ Verificando capacidades de virtualización del host..."
# Validar si el hardware soporta virtualización correctamente
virt-host-validate qemu || echo "⚠️ Advertencia: Algunas validaciones fallaron. Revisa tu BIOS/UEFI (Intel VT-x / AMD-V)."

echo "ℹ️ Configurando servicios..."
# En Kubuntu libvirtd sigue siendo el estándar, se habilita y arranca:
sudo systemctl enable --now libvirtd

echo "ℹ️ Configurando red virtual por defecto..."
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default

echo "ℹ️ Configurando bridge de red Linux (br0) para acceso directo a la LAN..."
# 1. Identificar la interfaz física principal (la que tiene la ruta por defecto)
PHYS_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

if [ -n "$PHYS_IFACE" ] && [ "$PHYS_IFACE" != "br0" ]; then
    if ! nmcli con show br0 >/dev/null 2>&1; then
        echo "Creando bridge br0 sobre la interfaz $PHYS_IFACE..."
        # Crear el bridge y su puerto esclavo
        sudo nmcli con add type bridge ifname br0 con-name br0
        sudo nmcli con add type bridge-slave ifname "$PHYS_IFACE" con-name br0-port master br0
        # Configurar br0 para obtener IP por DHCP (copia el comportamiento normal)
        sudo nmcli con modify br0 ipv4.method auto
        
        # Crear definición XML para que libvirt reconozca el bridge
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

# Añadir a grupo libvirt para gestión sin sudo
sudo usermod -aG libvirt "$TARGET_USER"

echo "ℹ️ Ajustando permisos ACL en el directorio de imágenes (Optimizado)..."
# Limpiar y reasignar ACLs para que el usuario pueda manejar discos sin sudo
sudo apt install -y acl
sudo mkdir -p /var/lib/libvirt/images
sudo setfacl -R -b /var/lib/libvirt/images || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images || true

# Configuración de rendimiento (Opcional pero recomendada para desarrollo)
echo "ℹ️ Configurando LIBVIRT_DEFAULT_URI..."
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<EOF > ~/.bashrc.d/virtualization.sh
# Configuración KVM/QEMU conectando al modo de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF
    echo "✅ Configuración modular de Virtualización creada en ~/.bashrc.d/virtualization.sh"
else
    # Si no hay soporte para .bashrc.d, lo añadimos a .bashrc
    if ! grep -q "LIBVIRT_DEFAULT_URI" ~/.bashrc; then
        echo '' >> ~/.bashrc
        echo '# Configuración KVM/QEMU conectando al modo de sistema por defecto' >> ~/.bashrc
        echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> ~/.bashrc
    fi
fi

echo "✅ Virtualización configurada correctamente. Cierra sesión para aplicar los cambios de grupo."
