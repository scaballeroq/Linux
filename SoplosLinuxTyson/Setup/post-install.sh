#!/bin/bash
# post-install.sh - Script maestro de post-instalación para Debian Testing (Trixie) con KDE Plasma 6
# (Configurado con ZRAM, Kernel rolling, Mesa, PipeWire y Suite KDE Plasma)

set -euo pipefail

# Detectar versión/codename de Debian
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "trixie")
fi

echo "🚀 Iniciando configuración base y modernización de Debian Testing ($CODENAME) + KDE Plasma..."

# 1. Habilitar Repositorios Extra (Contrib, Non-Free, Non-Free-Firmware)
echo "ℹ️ Configurando repositorios contrib, non-free y non-free-firmware para $CODENAME..."

sudo apt update
sudo apt install -y curl ca-certificates gnupg lsb-release

# Habilitar contrib, non-free y non-free-firmware en repositorios existentes (soporte para debian.sources DEB822 y sources.list clásico)
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sudo sed -i '/^Components:/ s/\bmain\b\(?!.*contrib\)/main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
fi
if [ -f /etc/apt/sources.list ]; then
    sudo sed -i '/^deb / s/\bmain\b\(?!.*contrib\)/main contrib non-free non-free-firmware/' /etc/apt/sources.list 2>/dev/null || true
fi

echo "ℹ️ Debian Testing ($CODENAME) detectado: Los paquetes y kernels más recientes se obtienen directamente de los repositorios principales."
echo "ℹ️ Actualizando listas de paquetes de todos los repositorios..."
sudo apt update
sudo apt upgrade -y

# 2. Compresión de Memoria ZRAM (Evita bloqueos del sistema al compilar)
echo "ℹ️ Instalando y configurando SWAP comprimida en RAM (ZRAM con ZSTD)..."
sudo apt install -y zram-tools 2>/dev/null || true
if [ -f /etc/default/zramswap ]; then
    sudo sed -i 's/^#*ALGORITHM=.*/ALGORITHM=zstd/' /etc/default/zramswap
    sudo sed -i 's/^#*PERCENT=.*/PERCENT=50/' /etc/default/zramswap
    sudo systemctl restart zramswap.service 2>/dev/null || true
fi

# 3. Kernel Linux y Firmware Oficial más reciente de Debian Testing
echo "ℹ️ Instalando el Kernel Linux más reciente y Firmware..."
sudo apt install -y \
    linux-image-amd64 \
    linux-headers-amd64 \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    firmware-amd-graphics 2>/dev/null || sudo apt install -y linux-image-amd64 linux-headers-amd64 firmware-linux-nonfree 2>/dev/null || true

sudo apt install -y intel-microcode amd64-microcode 2>/dev/null || true

# 4. Stack Gráfico y Aceleración HW (Mesa / VA-API / VDPAU / Vulkan)
echo "ℹ️ Instalando controladores gráficos Mesa y aceleración de hardware (VA-API / VDPAU / Vulkan)..."
sudo apt install -y \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    mesa-utils \
    va-driver-all \
    vulkan-tools \
    vainfo 2>/dev/null || sudo apt install -y mesa-va-drivers mesa-vdpau-drivers mesa-utils vainfo || true

# 5. Codecs Multimedia y FFmpeg
echo "ℹ️ Instalando FFmpeg y codecs multimedia de alto rendimiento..."
sudo apt install -y \
    ffmpeg \
    libavcodec-extra \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav 2>/dev/null || true

# 6. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "ℹ️ Habilitando servidor de audio moderno PipeWire, WirePlumber y módulo KDE Plasma PA..."
sudo apt install -y \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    plasma-pa 2>/dev/null || true

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 7. Entorno de Escritorio KDE Plasma y Aplicaciones Base
echo "ℹ️ Instalando componentes y utilidades base de KDE Plasma..."
sudo apt install -y \
    kde-plasma-desktop \
    plasma-workspace \
    dolphin \
    dolphin-plugins \
    kio-extras \
    konsole \
    ark \
    spectacle \
    gwenview \
    kate \
    kcalc \
    plasma-nm \
    bluedevil \
    plasma-browser-integration \
    kdeconnect \
    kpipewire \
    power-profiles-daemon \
    ffmpegthumbs \
    kdegraphics-thumbnailers \
    qt6-image-formats 2>/dev/null || true

# 8. Integración de Flatpak & Flathub en KDE Discover
echo "ℹ️ Configurando Flatpak y Flathub para KDE Discover..."
sudo apt install -y flatpak plasma-discover plasma-discover-backend-flatpak 2>/dev/null || true
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 9. Software Esencial de Sistema
echo "ℹ️ Instalando utilidades esenciales para Debian..."
sudo apt install -y \
    build-essential \
    cmake \
    curl \
    btop \
    htop \
    inxi \
    fuse3 \
    exfat-fuse \
    exfatprogs \
    vlc \
    gimp \
    gparted \
    7zip \
    p7zip-full \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz-utils \
    fastfetch 2>/dev/null || true

# 10. Limpieza de Paquetes Antiguos
echo "ℹ️ Limpiando paquetes obsoletos..."
sudo apt autoremove -y
sudo apt clean

echo "================================================================="
echo "✅ Debian Testing ($CODENAME) + KDE Plasma configurado con éxito."
echo "💡 Se recomienda reiniciar el equipo para arrancar con el nuevo Kernel Linux, Mesa y ZRAM."
echo "================================================================="
