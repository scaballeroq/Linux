#!/bin/bash
# post-install.sh - Script maestro de post-instalación para CachyOS (Arch Linux + GNOME)

set -euo pipefail

echo "🚀 Iniciando configuración base de CachyOS..."

# 1. Actualización Base de Repositorios y Sistema
echo "ℹ️ Actualizando lista de paquetes y sistema..."
if command -v cachyos-rate-mirrors &> /dev/null; then
    echo "ℹ️ Optimizando espejos con cachyos-rate-mirrors..."
    sudo cachyos-rate-mirrors || true
fi

sudo pacman -Syu --noconfirm

# Detectar AUR helper (paru o yay)
AUR_HELPER=""
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
fi

# 2. Software Esencial (7zip reemplaza a p7zip para evitar prompts interactivos)
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
    7zip \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz \
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

# 4. Aceleración HW (Mesa / VA-API)
echo "ℹ️ Verificando aceleración de hardware (VA-API / Mesa)..."
# Se instala libva-mesa-driver y libva-utils (se omiten mesa-vdpau y mesa explícito para no entrar en conflicto con mesa-git/mesa)
sudo pacman -S --needed --noconfirm libva-mesa-driver libva-utils mesa-utils || true

# 5. Limpieza Inicial
echo "ℹ️ Limpiando caché de paquetes innecesarios..."
sudo rm -f /var/cache/pacman/pkg/download-* 2>/dev/null || true
sudo pacman -Sc --noconfirm || true

echo "✅ Sistema base configurado correctamente (Se recomienda reiniciar)"
