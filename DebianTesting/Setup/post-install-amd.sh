#!/bin/bash
# post-install-amd.sh - Script de post-instalación para Debian Testing (Trixie) con AMD Ryzen y AMD Graphics
# (Configurado con ZRAM, Kernel rolling, Microcódigo AMD, Mesa Vulkan/VA-API, PipeWire y Suite GNOME)

set -euo pipefail

# Detectar versión/codename de Debian
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "trixie")
fi

echo "================================================================="
echo "🚀 INICIANDO POST-INSTALACIÓN: DEBIAN TESTING ($CODENAME) - AMD RYZEN"
echo "================================================================="

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

echo "ℹ️ Debian Testing ($CODENAME) detectado: Obteniendo paquetes más recientes."
sudo apt update
sudo apt upgrade -y

# 2. Compresión de Memoria ZRAM (Evita bloqueos del sistema al compilar/multitarea)
echo "ℹ️ Instalando y configurando SWAP comprimida en RAM (ZRAM con ZSTD)..."
sudo apt install -y zram-tools 2>/dev/null || true
if [ -f /etc/default/zramswap ]; then
    sudo sed -i 's/^#*ALGORITHM=.*/ALGORITHM=zstd/' /etc/default/zramswap
    sudo sed -i 's/^#*PERCENT=.*/PERCENT=50/' /etc/default/zramswap
    sudo systemctl restart zramswap.service 2>/dev/null || true
fi

# 3. Kernel Linux, Firmware y Microcódigo específico para AMD
echo "ℹ️ Instalando Kernel Linux, Firmware oficial y Microcódigo para AMD Ryzen..."
sudo apt install -y \
    linux-image-amd64 \
    linux-headers-amd64 \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    firmware-amd-graphics \
    amd64-microcode 2>/dev/null || sudo apt install -y linux-image-amd64 linux-headers-amd64 firmware-linux-nonfree amd64-microcode 2>/dev/null || true

# 4. Stack Gráfico y Aceleración HW para AMD (Mesa / RADV / VA-API / VDPAU / Vulkan)
echo "ℹ️ Instalando controladores gráficos AMD Mesa (RADV/RadeonSI) y aceleración de hardware..."
sudo apt install -y \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    mesa-vulkan-drivers \
    mesa-utils \
    libgl1-mesa-dri \
    va-driver-all \
    vulkan-tools \
    vainfo \
    radeontop 2>/dev/null || sudo apt install -y mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers mesa-utils vainfo || true

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
echo "ℹ️ Habilitando servidor de audio moderno PipeWire y WirePlumber..."
sudo apt install -y \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber 2>/dev/null || true

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 7. Entorno de Escritorio GNOME y Aplicaciones Base
echo "ℹ️ Instalando componentes y utilidades base de GNOME..."
sudo apt install -y \
    gnome-core \
    gnome-shell \
    gnome-control-center \
    gnome-tweaks \
    gnome-terminal \
    ptyxis \
    nautilus \
    file-roller \
    gnome-text-editor \
    gnome-calculator \
    gnome-disk-utility \
    gnome-system-monitor \
    power-profiles-daemon \
    switcheroo-control \
    ffmpegthumbnailer \
    evince \
    seahorse 2>/dev/null || true

# 8. Integración de Flatpak & Flathub en GNOME Software
echo "ℹ️ Configurando Flatpak y Flathub para GNOME Software..."
sudo apt install -y flatpak gnome-software gnome-software-plugin-flatpak 2>/dev/null || true
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
echo "✅ Debian Testing ($CODENAME) + GNOME (AMD Ryzen) configurado con éxito."
echo "💡 Se recomienda reiniciar el equipo para arrancar con el nuevo Kernel Linux, drivers AMD y ZRAM."
echo "================================================================="
