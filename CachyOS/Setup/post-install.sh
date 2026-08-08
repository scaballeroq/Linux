#!/bin/bash
# post-install.sh - Script maestro de post-instalación para CachyOS (Arch Linux + GNOME)

set -euo pipefail

echo "🚀 Iniciando configuración base de CachyOS..."

# 1. Actualización Base
echo "ℹ️ Actualizando lista de paquetes y sistema..."
sudo pacman -Syu --noconfirm

# Detectar AUR helper (paru o yay)
AUR_HELPER=""
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
fi

# 2. Software Esencial
echo "ℹ️ Instalando utilidades esenciales para CachyOS..."
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
    p7zip \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz \
    flatpak \
    gnome-software \
    ca-certificates \
    gnupg

# Instalación de kernel headers correspondientes al kernel en ejecución
KERNEL_RELEASE=$(uname -r)
if [[ "$KERNEL_RELEASE" == *"cachyos"* ]]; then
    sudo pacman -S --needed --noconfirm linux-cachyos-headers || true
else
    sudo pacman -S --needed --noconfirm linux-headers || true
fi

# 3. Multimedia Codecs
echo "ℹ️ Instalando codecs multimedia para Arch/CachyOS..."
sudo pacman -S --needed --noconfirm \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav \
    ffmpeg

# 4. Aceleración HW
echo "ℹ️ Instalando drivers de aceleración de hardware (Mesa/VA-API)..."
sudo pacman -S --needed --noconfirm \
    mesa \
    libva-mesa-driver \
    mesa-vdpau

# 5. Limpieza Inicial
echo "ℹ️ Limpiando caché de paquetes innecesarios..."
sudo pacman -Sc --noconfirm

echo "✅ Sistema base configurado correctamente (Se recomienda reiniciar)"
