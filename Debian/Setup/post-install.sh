#!/bin/bash
# post-install.sh - Script maestro de post-instalación para Debian (Modernizado con Backports, Kernel, Mesa y PipeWire)

set -euo pipefail

# Detectar versión/codename de Debian
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "bookworm")
fi

echo "🚀 Iniciando configuración base y modernización de Debian ($CODENAME)..."

# 1. Habilitar Repositorios Extra (Contrib, Non-Free, Non-Free-Firmware y Backports)
echo "ℹ️ Configurando repositorios contrib, non-free, non-free-firmware y backports para $CODENAME..."

sudo apt update
sudo apt install -y software-properties-common curl ca-certificates gnupg lsb-release

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

# 2. Actualizar Kernel Linux y Firmware desde Backports (Para hardware y rendimiento moderno)
echo "ℹ️ Instalando el Kernel Linux más reciente y Firmware desde ${CODENAME}-backports..."
sudo apt install -y -t ${CODENAME}-backports \
    linux-image-amd64 \
    linux-headers-amd64 \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    firmware-amd-graphics \
    firmware-intel-microcode \
    firmware-amd-ucode 2>/dev/null || sudo apt install -y linux-image-amd64 linux-headers-amd64 firmware-linux-nonfree 2>/dev/null || true

# 3. Stack Gráfico y Aceleración HW (Mesa / VA-API) desde Backports
echo "ℹ️ Instalando controladores gráficos Mesa y aceleración de hardware (VA-API / VDPAU) desde Backports..."
sudo apt install -y -t ${CODENAME}-backports \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    mesa-utils \
    va-driver-all \
    vainfo 2>/dev/null || sudo apt install -y mesa-va-drivers mesa-vdpau-drivers mesa-utils vainfo || true

# 4. Codecs Multimedia y FFmpeg desde Backports
echo "ℹ️ Instalando FFmpeg y codecs multimedia de alto rendimiento desde Backports..."
sudo apt install -y -t ${CODENAME}-backports \
    ffmpeg \
    libavcodec-extra \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav 2>/dev/null || sudo apt install -y ffmpeg libavcodec-extra gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav || true

# 5. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "ℹ️ Habilitando servidor de audio moderno PipeWire y WirePlumber..."
sudo apt install -y \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 6. Software Esencial de Sistema
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

# 7. Limpieza de Paquetes Antiguos
echo "ℹ️ Limpiando paquetes obsoletos..."
sudo apt autoremove -y
sudo apt clean

echo "================================================================="
echo "✅ Debian ($CODENAME) ha sido actualizado y modernizado con éxito."
echo "💡 Se recomienda reiniciar el equipo para arrancar con el nuevo Kernel Linux y Mesa."
echo "================================================================="
