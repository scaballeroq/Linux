#!/bin/bash
# ==============================================================================
# post-install-intel.sh - Post-instalación para Ubuntu con Intel Core y Media Center
# Entorno: GNOME Shell 51 (Wayland)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: UBUNTU (GNOME) - INTEL MEDIA DESKTOP"
echo "================================================================="

CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "noble")
fi

# 1. Actualización Base
echo "ℹ️ [1/8] Actualizando repositorios y sistema..."
sudo apt update
sudo apt upgrade -y

# 2. Habilitar Repositorios Extra
echo "ℹ️ [2/8] Habilitando repositorios universe, multiverse y restricted..."
sudo add-apt-repository -y universe 2>/dev/null || true
sudo add-apt-repository -y multiverse 2>/dev/null || true
sudo add-apt-repository -y restricted 2>/dev/null || true
sudo apt update

# 3. Microcódigo Intel y Firmware
echo "ℹ️ [3/8] Instalando microcódigo Intel oficial..."
sudo apt install -y intel-microcode linux-firmware

# 4. Drivers de Aceleración Intel (i965 y media-driver)
echo "ℹ️ [4/8] Instalando controladores VA-API para Intel..."
sudo apt install -y \
    intel-media-va-driver \
    i965-va-driver \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    vainfo \
    vulkan-tools \
    mesa-utils

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
    unrar \
    zip \
    unzip

# 6. Centro Multimedia Kodi y Codecs
echo "ℹ️ [6/8] Instalando Kodi y plugins de streaming multimedia..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    kodi \
    kodi-inputstream-adaptive \
    kodi-inputstream-rtmp \
    ubuntu-restricted-extras \
    ffmpeg \
    vlc 2>/dev/null || true

# 7. Memoria ZRAM
echo "ℹ️ [7/8] Configurando ZRAM..."
if [ -f "$(dirname "$0")/zram-setup.sh" ]; then
    bash "$(dirname "$0")/zram-setup.sh"
else
    sudo apt install -y zram-tools
    echo -e "ALGORITHM=zstd\nPERCENT=50" | sudo tee /etc/default/zramswap > /dev/null
    sudo systemctl enable --now zramswap.service 2>/dev/null || true
fi

# 8. Limpieza
echo "ℹ️ [8/8] Limpiando dependencias huérfanas..."
sudo apt autoremove -y
sudo apt clean

echo "================================================================="
echo "✅ Post-instalación Intel Media completada con éxito en Ubuntu."
echo "================================================================="
