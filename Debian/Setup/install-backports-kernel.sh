#!/bin/bash
# install-backports-kernel.sh - Instalación automatizada del último Kernel Linux y Firmware desde Debian Backports

set -euo pipefail

# 1. Auditoría de Sistema y Codename
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "bookworm")
fi

IS_TESTING=false
if [[ "$CODENAME" =~ ^(testing|sid|unstable|forky)$ ]] || grep -q -i -E "testing|unstable|sid|forky" /etc/os-release 2>/dev/null; then
    IS_TESTING=true
fi

echo "================================================================="
echo "🐧 INSTALADOR DE KERNEL LINUX Y FIRMWARE"
echo "================================================================="
echo "💻 Distribución: Debian ($CODENAME)"
echo "📌 Kernel activo: $(uname -r)"
echo "================================================================="

APT_TARGET_FLAG=()
if [ "$IS_TESTING" = false ]; then
    BACKPORTS_FILE="/etc/apt/sources.list.d/backports.list"
    if ! grep -q "${CODENAME}-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "ℹ️ Configurando repositorio ${CODENAME}-backports..."
        echo "deb http://deb.debian.org/debian ${CODENAME}-backports main contrib non-free non-free-firmware" | sudo tee "$BACKPORTS_FILE" > /dev/null
        echo "✅ Repositorio ${CODENAME}-backports añadido en $BACKPORTS_FILE"
    fi
    APT_TARGET_FLAG=("-t" "${CODENAME}-backports")
else
    echo "ℹ️ Sistema Debian Testing/Unstable ($CODENAME) detectado. Se utilizarán los repositorios principales (no requiere backports)."
fi

# 3. Actualizar Índices de Paquetes
echo "ℹ️ Actualizando listas de paquetes de APT..."
sudo apt update

# 5. Instalación del Kernel y Firmware
echo "ℹ️ Instalando Kernel Linux y Firmware más reciente..."
sudo apt install -y ${APT_TARGET_FLAG+"${APT_TARGET_FLAG[@]}"} \
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
