#!/bin/bash
# ==============================================================================
# post-install-intel.sh - Post-instalación para Soplos Linux Boro con Intel Core y Media Center
# Entorno: GNOME Shell (Wayland)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: SOPLOS LINUX BORO (GNOME) - INTEL MEDIA DESKTOP"
echo "================================================================="

CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "trixie")
fi

echo "Soplos Linux Boro detectado: $CODENAME"

# 1. Actualización Base
echo "ℹ️ [1/8] Actualizando repositorios y herramientas..."
sudo apt update
sudo apt install -y curl wget ca-certificates gnupg lsb-release

# 2. Habilitar Repositorios Extra (Contrib, Non-Free, Non-Free-Firmware)
echo "ℹ️ [2/8] Habilitando contrib, non-free y non-free-firmware..."
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sudo sed -i '/^Components:/ {/contrib/! s/$/ contrib/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
    sudo sed -i '/^Components:/ {/non-free/! s/$/ non-free/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
    sudo sed -i '/^Components:/ {/non-free-firmware/! s/$/ non-free-firmware/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
fi
if [ -f /etc/apt/sources.list ]; then
    sudo sed -i '/^deb / {/contrib/! s/\(main\)/\1 contrib non-free non-free-firmware/}' /etc/apt/sources.list 2>/dev/null || true
fi

sudo apt update
sudo apt upgrade -y

# 3. Microcódigo Intel y Firmware
echo "ℹ️ [3/8] Instalando microcódigo Intel oficial y firmware..."
sudo apt install -y \
    intel-microcode \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree 2>/dev/null || sudo apt install -y intel-microcode firmware-linux-nonfree 2>/dev/null || true

# 4. Drivers de Aceleración Intel (i965 y media-driver)
echo "ℹ️ [4/8] Instalando controladores VA-API para Intel..."
sudo apt install -y \
    intel-media-va-driver \
    i965-va-driver \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    vainfo \
    vulkan-tools \
    mesa-utils 2>/dev/null || true

# Driver propietario opcional de Intel para codificación no-libre si está disponible
sudo apt install -y intel-media-va-driver-non-free 2>/dev/null || true

# 5. Paquetes Esenciales y GNOME
echo "ℹ️ [5/8] Instalando paquetes esenciales de escritorio..."
sudo apt install -y \
    build-essential \
    curl \
    wget \
    btop \
    htop \
    inxi \
    flatpak \
    gnome-software-plugin-flatpak \
    gnome-tweaks \
    wl-clipboard \
    7zip \
    p7zip-full \
    unrar \
    zip \
    unzip \
    libavcodec-extra \
    ffmpeg \
    vlc 2>/dev/null || true

# 6. Centro Multimedia Kodi y Codecs
echo "ℹ️ [6/8] Instalando Kodi y plugins de streaming multimedia..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    kodi \
    kodi-inputstream-adaptive \
    kodi-inputstream-rtmp 2>/dev/null || true

# 7. Memoria ZRAM
echo "ℹ️ [7/8] Configurando ZRAM..."
if [ -f "$(dirname "$0")/zram-setup.sh" ]; then
    bash "$(dirname "$0")/zram-setup.sh"
else
    sudo apt install -y zram-tools 2>/dev/null || true
    if [ -f /etc/default/zramswap ]; then
        sudo sed -i 's/^#*ALGORITHM=.*/ALGORITHM=zstd/' /etc/default/zramswap
        sudo sed -i 's/^#*PERCENT=.*/PERCENT=50/' /etc/default/zramswap
        sudo systemctl restart zramswap.service 2>/dev/null || true
    fi
fi

# 8. Limpieza
echo "ℹ️ [8/8] Limpiando dependencias huérfanas..."
sudo apt autoremove -y
sudo apt clean

echo "================================================================="
echo "✅ Post-instalación Intel Media completada con éxito en Soplos Linux Boro."
echo "================================================================="
