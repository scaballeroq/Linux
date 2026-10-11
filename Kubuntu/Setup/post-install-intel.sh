#!/bin/bash
# post-install-intel.sh - Post-instalación para Kubuntu con Intel Core y Intel Graphics
# (Configurado con repositorios, microcódigo Intel, VA-API Intel, Mesa, ZRAM, codecs)

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: KUBUNTU (KDE PLASMA) - INTEL CORE"
echo "================================================================="

CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "noble")
fi

echo "Kubuntu detectado: $CODENAME"

# 1. Actualización Base
echo "ℹ️ [1/10] Actualizando sistema..."
sudo apt update
sudo apt upgrade -y

# 2. Habilitar Repositorios Extra
echo "ℹ️ [2/10] Habilitando repositorios universe, multiverse y restricted..."
sudo add-apt-repository -y universe 2>/dev/null || true
sudo add-apt-repository -y multiverse 2>/dev/null || true
sudo add-apt-repository -y restricted 2>/dev/null || true
sudo apt update

# 3. Pre-aceptar licencias
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections

# 4. Software Esencial
echo "ℹ️ [3/10] Instalando utilidades esenciales..."
sudo apt install -y \
    build-essential \
    linux-headers-$(uname -r) \
    cmake \
    curl \
    wget \
    btop \
    htop \
    inxi \
    fuse3 \
    libfuse2t64 \
    exfatprogs \
    vlc \
    gimp \
    gparted \
    p7zip-full \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz-utils \
    fastfetch \
    ca-certificates \
    gnupg \
    software-properties-common \
    flatpak \
    plasma-discover-backend-flatpak

# 5. Microcódigo y Firmware Intel
echo "ℹ️ [4/10] Instalando microcódigo Intel y firmware oficial..."
sudo apt install -y \
    intel-microcode \
    linux-firmware

# 6. Stack Gráfico Intel (Mesa / VA-API Intel / Vulkan)
echo "ℹ️ [5/10] Instalando controladores gráficos Intel y aceleración de hardware..."
sudo apt install -y \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    vulkan-tools \
    vainfo \
    libva-intel-driver \
    intel-media-driver \
    mesa-utils

# Vulkan 32-bit (solo si Wine/Proton está presente)
if command -v wine &>/dev/null || command -v proton &>/dev/null; then
    echo "Wine/Proton detectado. Instalando drivers Vulkan 32-bit..."
    sudo apt install -y lib32vulkan1 lib32mesa0 lib32intel-media-driver 2>/dev/null || true
fi

# 7. Codecs Multimedia
echo "ℹ️ [6/10] Instalando codecs multimedia y FFmpeg..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    kubuntu-restricted-extras \
    libavcodec-extra \
    ffmpeg \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav

# 8. KDE Extras
echo "ℹ️ [7/10] Instalando complementos de KDE Plasma..."
sudo apt install -y \
    dolphin-plugins \
    kio-extras \
    ffmpegthumbs \
    kdegraphics-thumbnailers \
    kdeconnect \
    qt6-image-formats-plugins \
    plasma-browser-integration \
    plasma-widgets-addons

# 9. Flathub
echo "ℹ️ [8/10] Configurando Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 10. Limpieza
echo "ℹ️ [9/10] Limpiando paquetes innecesarios..."
sudo apt autoremove -y
sudo apt clean

echo "================================================================="
echo "✅ Kubuntu (Intel Core) configurado con éxito."
echo "💡 Se recomienda reiniciar el equipo para aplicar microcódigo y drivers."
echo "================================================================="
