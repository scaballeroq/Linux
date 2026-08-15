#!/bin/bash
# install-backports-kernel.sh - Instalación y actualización automatizada del Kernel Linux y Firmware oficial en Debian Testing

set -euo pipefail

# 1. Auditoría de Sistema y Codename
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "trixie")
fi

echo "================================================================="
echo "🐧 ACTUALIZADOR DE KERNEL LINUX Y FIRMWARE (DEBIAN TESTING)"
echo "================================================================="
echo "💻 Distribución: Debian Testing ($CODENAME)"
echo "📌 Kernel activo: $(uname -r)"
echo "================================================================="

# 2. Actualizar Índices de Paquetes
echo "ℹ️ Actualizando listas de paquetes de APT..."
sudo apt update

# 3. Instalación del Kernel y Firmware
echo "ℹ️ Instalando el Kernel Linux y Firmware oficial más reciente de Debian Testing..."
sudo apt install -y \
    linux-image-amd64 \
    linux-headers-amd64 \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    firmware-amd-graphics || true

# 4. Instalación de Microcódigo de CPU (Intel/AMD)
echo "ℹ️ Instalando paquetes de microcódigo de CPU (intel-microcode / amd64-microcode)..."
sudo apt install -y \
    intel-microcode \
    amd64-microcode

# 5. Actualizar el gestor de arranque GRUB
echo "ℹ️ Actualizando GRUB..."
sudo update-grub

echo "================================================================="
echo "✅ Instalación y actualización del Kernel Linux completada con éxito."
echo "📌 Nuevo kernel disponible: $(dpkg -l | grep -E "linux-image-[0-9]" | tail -n 1 | awk '{print $2, $3}')"
echo "================================================================="

read -rp "¿Deseas reiniciar el sistema ahora para arrancar con el nuevo kernel? (s/N): " REBOOT_NOW || true
if [[ "${REBOOT_NOW:-n}" =~ ^[Ss]$ ]]; then
    echo "🔄 Reiniciando sistema..."
    sudo reboot
fi
