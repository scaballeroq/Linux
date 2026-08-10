#!/bin/bash
# post-install.sh - Script maestro de post-instalación para Debian (GNOME Desktop)

set -euo pipefail

# Detectar versión/codename de Debian
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "bookworm")
fi

echo "🚀 Iniciando configuración base de Debian ($CODENAME)..."

# 1. Habilitar Repositorios Extra (Contrib, Non-Free, Non-Free-Firmware y Backports)
echo "ℹ️ Configurando repositorios contrib, non-free, non-free-firmware y backports para $CODENAME..."

# Asegurar que software-properties-common está instalado para apt-add-repository
sudo apt update
sudo apt install -y software-properties-common curl ca-certificates gnupg

# Habilitar contrib, non-free y non-free-firmware en repositorios existentes
sudo apt-add-repository -y contrib non-free non-free-firmware 2>/dev/null || true

# Configurar repositorio de Backports
BACKPORTS_FILE="/etc/apt/sources.list.d/backports.list"
if ! grep -q "${CODENAME}-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    echo "deb http://deb.debian.org/debian ${CODENAME}-backports main contrib non-free non-free-firmware" | sudo tee "$BACKPORTS_FILE" > /dev/null
    echo "✅ Repositorio ${CODENAME}-backports añadido en $BACKPORTS_FILE"
fi

echo "ℹ️ Actualizando listas de paquetes de todos los repositorios..."
sudo apt update
sudo apt upgrade -y

# 2. Software Esencial
echo "ℹ️ Instalando utilidades esenciales para Debian..."
sudo apt install -y \
    build-essential \
    linux-headers-$(uname -r) \
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
    ca-certificates \
    gnupg

# 3. Codecs Multimedia
echo "ℹ️ Instalando codecs multimedia para Debian..."
sudo apt install -y \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    libavcodec-extra \
    ffmpeg

# 4. Aceleración HW (Mesa / VA-API)
echo "ℹ️ Instalando controladores de aceleración de hardware (VA-API / Mesa)..."
sudo apt install -y \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    va-driver-all \
    vainfo \
    mesa-utils 2>/dev/null || true

# 5. Limpieza Inicial
echo "ℹ️ Limpiando paquetes innecesarios..."
sudo apt autoremove -y
sudo apt clean

echo "✅ Sistema base de Debian ($CODENAME) configurado correctamente (Se recomienda reiniciar)."
