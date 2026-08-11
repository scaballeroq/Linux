#!/bin/bash
# install-backports-kernel.sh - Instalación automatizada del último Kernel Linux y Firmware desde Debian Backports

set -euo pipefail

# 1. Auditoría de Sistema y Codename
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "bookworm")
fi

echo "================================================================="
echo "🐧 INSTALADOR DE KERNEL LINUX Y FIRMWARE DESDE DEBIAN BACKPORTS"
echo "================================================================="
echo "💻 Distribución: Debian ($CODENAME)"
echo "📌 Kernel activo: $(uname -r)"
echo "================================================================="

# 2. Configurar Repositorio de Backports si no está presente
BACKPORTS_FILE="/etc/apt/sources.list.d/backports.list"
if ! grep -q "${CODENAME}-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    echo "ℹ️ Configurando repositorio ${CODENAME}-backports..."
    echo "deb http://deb.debian.org/debian ${CODENAME}-backports main contrib non-free non-free-firmware" | sudo tee "$BACKPORTS_FILE" > /dev/null
    echo "✅ Repositorio ${CODENAME}-backports añadido en $BACKPORTS_FILE"
fi

# 3. Actualizar Índices de Paquetes
echo "ℹ️ Actualizando listas de paquetes de APT..."
sudo apt update

# 4. Consultar versión disponible en Backports
BACKPORT_KERNEL_VER=$(apt-cache policy linux-image-amd64 | grep -A 1 "${CODENAME}-backports" | tail -n 1 | awk '{print $1}' || echo "")
echo "ℹ️ Instalando Kernel Linux y Firmware desde ${CODENAME}-backports..."

# 5. Instalación del Kernel y Firmware desde Backports
sudo apt install -y -t "${CODENAME}-backports" \
    linux-image-amd64 \
    linux-headers-amd64 \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    firmware-amd-graphics || true

# 6. Instalación de Microcódigo de CPU (Intel/AMD)
echo "ℹ️ Instalando paquetes de microcódigo de CPU (intel-microcode / amd64-microcode)..."
sudo apt install -y \
    intel-microcode \
    amd64-microcode

# 6. Actualizar el gestor de arranque GRUB
echo "ℹ️ Actualizando GRUB..."
sudo update-grub

echo "================================================================="
echo "✅ Instalación del Kernel Linux de Backports completada con éxito."
echo "📌 Nuevo kernel disponible: $(dpkg -l | grep -E "linux-image-[0-9]" | tail -n 1 | awk '{print $2, $3}')"
echo "================================================================="

read -rp "¿Deseas reiniciar el sistema ahora para arrancar con el nuevo kernel? (s/N): " REBOOT_NOW || true
if [[ "${REBOOT_NOW:-n}" =~ ^[Ss]$ ]]; then
    echo "🔄 Reiniciando sistema..."
    sudo reboot
fi
