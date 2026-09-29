#!/bin/bash
# post-install-intel.sh - Script de post-instalación para Debian Testing (Trixie) con Intel Core (Haswell/i7-4790) + Multimedia (Kodi/Streaming)
# (Configurado con ZRAM, Microcódigo Intel, VA-API i965/Intel HD Graphics, Codecs, Kodi, PipeWire y Suite KDE Plasma 6)

set -euo pipefail

# Detectar versión/codename de Debian
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "trixie")
fi

echo "================================================================="
echo "🚀 INICIANDO POST-INSTALACIÓN: DEBIAN TESTING ($CODENAME) - INTEL CORE / MEDIA CENTER"
echo "🖥️ Optimizado para sobremesa Intel Haswell (i7-4790 / HD Graphics 4600)"
echo "🎬 Configuración multimedia para Kodi, streaming y KDE Plasma 6"
echo "================================================================="

# 1. Habilitar Repositorios Extra (Contrib, Non-Free, Non-Free-Firmware)
echo "ℹ️ Configurando repositorios contrib, non-free y non-free-firmware para $CODENAME..."

sudo apt update
sudo apt install -y curl ca-certificates gnupg lsb-release

# Habilitar contrib, non-free y non-free-firmware en repositorios existentes (soporte para debian.sources DEB822 y sources.list clásico)
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sudo sed -i -E '/^Components:/ { /main/!b; s/[[:space:]]+(contrib|non-free-firmware|non-free)//g; s/\bmain\b/main contrib non-free non-free-firmware/; }' /etc/apt/sources.list.d/debian.sources
fi
if [ -f /etc/apt/sources.list ]; then
    sudo sed -i -E '/^deb(-src)?[[:space:]]+/ { /main/!b; s/[[:space:]]+(contrib|non-free-firmware|non-free)//g; s/\bmain\b/main contrib non-free non-free-firmware/; }' /etc/apt/sources.list
fi

echo "ℹ️ Debian Testing ($CODENAME) detectado: Obteniendo paquetes más recientes."
sudo apt update
sudo apt upgrade -y

# 2. Compresión de Memoria ZRAM (Optimizado para 8 GB RAM)
echo "ℹ️ Instalando y configurando SWAP comprimida en RAM (ZRAM con ZSTD)..."
sudo apt install -y zram-tools 2>/dev/null || true
if [ -f /etc/default/zramswap ]; then
    sudo sed -i 's/^#*ALGORITHM=.*/ALGORITHM=zstd/' /etc/default/zramswap
    sudo sed -i 's/^#*PERCENT=.*/PERCENT=50/' /etc/default/zramswap
    sudo systemctl restart zramswap.service 2>/dev/null || true
fi

# 3. Kernel Linux, Firmware y Microcódigo Intel
echo "ℹ️ Instalando Kernel Linux, Firmware oficial y Microcódigo Intel..."
sudo apt install -y \
    linux-image-amd64 \
    linux-headers-amd64 \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    intel-microcode 2>/dev/null || sudo apt install -y linux-image-amd64 linux-headers-amd64 firmware-linux-nonfree intel-microcode 2>/dev/null || true

# 4. Stack Gráfico Intel y Aceleración HW por Video (VA-API Haswell / i965 / Intel HD 4600)
echo "ℹ️ Instalando controladores gráficos Intel y aceleración de vídeo por hardware (i965 / VA-API / Mesa)..."
sudo apt install -y \
    i965-va-driver \
    i965-va-driver-shaders \
    intel-media-va-driver \
    va-driver-all \
    libgl1-mesa-dri \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    mesa-vulkan-drivers \
    mesa-utils \
    vulkan-tools \
    vainfo \
    intel-gpu-tools 2>/dev/null || sudo apt install -y i965-va-driver intel-media-va-driver libgl1-mesa-dri mesa-utils vainfo || true

# Configurar driver VA-API por defecto para Intel Haswell (Gen 7.5)
if [ ! -f /etc/environment.d/90-intel-vaapi.conf ]; then
    sudo mkdir -p /etc/environment.d
    echo "LIBVA_DRIVER_NAME=i965" | sudo tee /etc/environment.d/90-intel-vaapi.conf > /dev/null
fi

# 5. Codecs Multimedia de Alto Rendimiento y Reproducción (Streaming / DRM)
echo "ℹ️ Instalando FFmpeg y codecs multimedia para streaming y vídeo..."
sudo apt install -y \
    ffmpeg \
    libavcodec-extra \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-vaapi \
    gstreamer1.0-tools \
    libbluray2 2>/dev/null || true

# 6. Centro Multimedia (Kodi y complementos de streaming)
echo "ℹ️ Instalando centro multimedia Kodi y complementos para streaming adaptativo..."
sudo apt install -y \
    kodi \
    kodi-inputstream-adaptive \
    kodi-inputstream-rtmp \
    kodi-pvr-iptvsimple 2>/dev/null || true

# 7. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "ℹ️ Habilitando servidor de audio moderno PipeWire y WirePlumber..."
sudo apt install -y \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber 2>/dev/null || true

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 8. Entorno de Escritorio KDE Plasma 6 y Aplicaciones Base
echo "ℹ️ Instalando componentes y utilidades base de KDE Plasma 6..."
sudo apt install -y \
    kde-plasma-desktop \
    plasma-workspace-wayland \
    dolphin \
    dolphin-plugins \
    kio-extras \
    kio-admin \
    kate \
    spectacle \
    kcalc \
    ark \
    gwenview \
    okular \
    plasma-systemmonitor \
    partitionmanager \
    kinfocenter \
    kitty \
    power-profiles-daemon \
    ffmpegthumbnailer \
    ffmpegthumbs \
    wl-clipboard \
    papirus-icon-theme 2>/dev/null || true

# 9. Integración de Flatpak & Flathub en KDE Discover
echo "ℹ️ Configurando Flatpak y Flathub para KDE Discover..."
sudo apt install -y flatpak plasma-discover-backend-flatpak 2>/dev/null || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 10. Software Esencial de Sistema
echo "ℹ️ Instalando utilidades esenciales para Debian..."
sudo apt install -y \
    build-essential \
    cmake \
    curl \
    wget \
    btop \
    htop \
    inxi \
    fuse3 \
    exfatprogs \
    7zip \
    p7zip-full \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz-utils \
    fastfetch 2>/dev/null || true

# 11. Limpieza de Paquetes Antiguos
echo "🧹 Limpiando caché y paquetes obsoletos..."
sudo apt autoremove -y
sudo apt autoclean

echo "================================================================="
echo "✅ Post-instalación Intel Core / Media Center completada con éxito."
echo "💡 Se recomienda reiniciar el sistema para aplicar los cambios de microcódigo,"
echo "   módulos de vídeo VA-API y servidor de audio PipeWire."
echo "================================================================="
