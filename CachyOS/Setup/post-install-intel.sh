#!/bin/bash
# post-install-intel.sh - Script de post-instalacion para CachyOS con Intel Core y Intel Graphics
# (Configurado con ZRAM, Pacman optimizado, Microcodigo Intel, VA-API Intel, PipeWire)

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACION: CACHYOS (ARCH LINUX) - INTEL CORE"
echo "================================================================="

# Detectar AUR helper
AUR_HELPER=""
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
fi

# 1. Optimizacion de Pacman (Paralelismo de descargas)
echo "Configurando optimizaciones en Pacman..."
PACMAN_CONF="/etc/pacman.conf"
if [ -f "$PACMAN_CONF" ]; then
    if ! grep -q "ParallelDownloads" "$PACMAN_CONF"; then
        sudo sed -i '/^\[options\]/a ParallelDownloads = 10' "$PACMAN_CONF"
    fi
    if ! grep -q "Color" "$PACMAN_CONF"; then
        sudo sed -i '/^\[options\]/a Color' "$PACMAN_CONF"
    fi
fi

# Optimizar espejos si esta disponible
if command -v cachyos-rate-mirrors &> /dev/null; then
    echo "Optimizando espejos con cachyos-rate-mirrors..."
    sudo cachyos-rate-mirrors || true
fi

# Actualizar sistema
echo "Actualizando base del sistema..."
sudo pacman -Syu --noconfirm

# 2. Habilitar repositorios multilib
echo "Habilitando repositorio multilib..."
if ! grep -q "^\[multilib\]" "$PACMAN_CONF"; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a "$PACMAN_CONF" > /dev/null
    sudo pacman -Syu --noconfirm
fi

# 3. Compresion de Memoria ZRAM
echo "Configurando ZRAM con algoritmo ZSTD al 50% de RAM..."
sudo pacman -S --needed --noconfirm zram-generator 2>/dev/null || true
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF
sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

# 4. Kernel Linux, Firmware y Microcodigo para Intel
echo "Instalando Kernel Linux, Firmware oficial y Microcodigo para Intel..."
sudo pacman -S --needed --noconfirm \
    linux-cachyos \
    linux-cachyos-headers \
    intel-ucode \
    linux-firmware 2>/dev/null || sudo pacman -S --needed --noconfirm \
    linux \
    linux-headers \
    intel-ucode \
    linux-firmware 2>/dev/null || true

# 5. Stack Grafico y Aceleracion HW para Intel (Mesa / VA-API Intel)
echo "Instalando controladores graficos Intel y aceleracion de hardware..."
sudo pacman -S --needed --noconfirm \
    mesa \
    libva-intel-driver \
    intel-media-driver \
    vulkan-intel \
    vulkan-tools \
    libva-utils \
    mesa-utils 2>/dev/null || true

# Vulkan 32-bit (solo para Wine/Proton gaming)
if command -v wine &>/dev/null || command -v proton &>/dev/null; then
    echo "Wine/Proton detectado. Instalando drivers Vulkan 32-bit..."
    sudo pacman -S --needed --noconfirm lib32-vulkan-intel lib32-mesa lib32-intel-media-driver 2>/dev/null || true
fi

# 6. Codecs Multimedia y FFmpeg completo
echo "Instalando FFmpeg completo y codecs multimedia..."
sudo pacman -S --needed --noconfirm \
    ffmpeg \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav 2>/dev/null || true

# 7. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "Verificando y habilitando PipeWire y WirePlumber..."
sudo pacman -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber 2>/dev/null || true

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 8. Software Esencial de Sistema e Integracion KDE Plasma 6
echo "Instalando utilidades esenciales y plugins de KDE Plasma 6 (Dolphin Thumbnails, KIO)..."
sudo pacman -S --needed --noconfirm \
    base-devel \
    cmake \
    curl \
    btop \
    htop \
    inxi \
    fuse2 \
    fuse3 \
    exfatprogs \
    vlc \
    gimp \
    gparted \
    7zip \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz \
    fastfetch \
    ca-certificates \
    gnupg \
    ffmpegthumbs \
    kdegraphics-thumbnailers \
    kimageformats \
    qt6-imageformats \
    taglib \
    poppler \
    kde-gtk-config \
    breeze-gtk \
    xdg-desktop-portal-kde 2>/dev/null || true

# 9. Integracion de Flatpak & Flathub
echo "Configurando Flatpak y Flathub..."
sudo pacman -S --needed --noconfirm flatpak 2>/dev/null || true
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 10. Limpieza de Paquetes Antiguos
echo "Limpiando cache y paquetes obsoletos..."
sudo pacman -Sc --noconfirm || true

echo "================================================================="
echo "CachyOS (Intel Core) configurado con exito."
echo "Se recomienda reiniciar el equipo para arrancar con el nuevo Kernel, drivers Intel y ZRAM."
echo "================================================================="
