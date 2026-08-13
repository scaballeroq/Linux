#!/bin/bash
# post-install.sh - Script maestro de post-instalación para Debian (Modernizado con Backports, ZRAM, Kernel, Mesa y PipeWire)

set -euo pipefail

# Detectar versión/codename de Debian y si es Testing/Unstable/Forky
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "bookworm")
fi

IS_TESTING=false
if [[ "$CODENAME" =~ ^(testing|sid|unstable|forky)$ ]] || grep -q -i -E "testing|unstable|sid|forky" /etc/os-release 2>/dev/null; then
    IS_TESTING=true
fi

echo "🚀 Iniciando configuración base y modernización de Debian ($CODENAME)..."

# 1. Habilitar Repositorios Extra (Contrib, Non-Free, Non-Free-Firmware y Backports)
echo "ℹ️ Configurando repositorios contrib, non-free y non-free-firmware para $CODENAME..."

sudo apt update
sudo apt install -y curl ca-certificates gnupg lsb-release

# Habilitar contrib, non-free y non-free-firmware en repositorios existentes (soporte para formato clásico sources.list y DEB822 debian.sources)
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sudo sed -i '/^Components:/ s/\bmain\b\(?!.*contrib\)/main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
fi
if [ -f /etc/apt/sources.list ]; then
    sudo sed -i '/^deb / s/\bmain\b\(?!.*contrib\)/main contrib non-free non-free-firmware/' /etc/apt/sources.list 2>/dev/null || true
fi

# Configurar repositorio de Backports (solo en Debian Stable)
APT_TARGET_FLAG=()
if [ "$IS_TESTING" = false ]; then
    BACKPORTS_FILE="/etc/apt/sources.list.d/backports.list"
    if ! grep -q "${CODENAME}-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "deb http://deb.debian.org/debian ${CODENAME}-backports main contrib non-free non-free-firmware" | sudo tee "$BACKPORTS_FILE" > /dev/null
        echo "✅ Repositorio ${CODENAME}-backports añadido en $BACKPORTS_FILE"
    fi
    APT_TARGET_FLAG=("-t" "${CODENAME}-backports")
else
    echo "ℹ️ Sistema Debian Testing/Unstable ($CODENAME) detectado. Los paquetes se instalarán desde los repositorios principales (sin backports)."
fi

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

# 4. Actualizar Kernel Linux y Firmware desde Backports / Repositorio Principal
echo "ℹ️ Instalando el Kernel Linux más reciente y Firmware..."
sudo apt install -y ${APT_TARGET_FLAG+"${APT_TARGET_FLAG[@]}"} \
    linux-image-amd64 \
    linux-headers-amd64 \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    firmware-amd-graphics 2>/dev/null || sudo apt install -y linux-image-amd64 linux-headers-amd64 firmware-linux-nonfree 2>/dev/null || true

sudo apt install -y intel-microcode amd64-microcode 2>/dev/null || true

# 5. Stack Gráfico y Aceleración HW (Mesa / VA-API)
echo "ℹ️ Instalando controladores gráficos Mesa y aceleración de hardware (VA-API / VDPAU)..."
sudo apt install -y ${APT_TARGET_FLAG+"${APT_TARGET_FLAG[@]}"} \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    mesa-utils \
    va-driver-all \
    vainfo 2>/dev/null || sudo apt install -y mesa-va-drivers mesa-vdpau-drivers mesa-utils vainfo || true

# 6. Codecs Multimedia y FFmpeg
echo "ℹ️ Instalando FFmpeg y codecs multimedia de alto rendimiento..."
sudo apt install -y ${APT_TARGET_FLAG+"${APT_TARGET_FLAG[@]}"} \
    ffmpeg \
    libavcodec-extra \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav 2>/dev/null || sudo apt install -y ffmpeg libavcodec-extra gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav || true

# 7. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "ℹ️ Habilitando servidor de audio moderno PipeWire y WirePlumber..."
sudo apt install -y \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 8. Integración de Flatpak & Flathub en GNOME Software
echo "ℹ️ Configurando Flatpak y Flathub para GNOME..."
sudo apt install -y flatpak gnome-software-plugin-flatpak 2>/dev/null || true
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
echo "✅ Debian ($CODENAME) ha sido actualizado y modernizado con éxito."
echo "💡 Se recomienda reiniciar el equipo para arrancar con el nuevo Kernel Linux, Mesa y ZRAM."
echo "================================================================="
