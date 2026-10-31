#!/bin/bash
# ==============================================================================
# post-install-amd.sh - Post-instalación para Ubuntu con AMD Ryzen y AMD Graphics
# Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics (Vega 8))
# Entorno: GNOME Shell (Wayland)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: UBUNTU (GNOME SHELL) - AMD RYZEN"
echo "================================================================="

CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "noble")
fi

echo "Ubuntu detectado: $CODENAME"

# 1. Actualización Base
echo "ℹ️ [1/10] Actualizando repositorios y sistema..."
sudo apt update
sudo apt upgrade -y

# 2. Habilitar Repositorios Extra
echo "ℹ️ [2/10] Habilitando repositorios universe, multiverse y restricted..."
sudo add-apt-repository -y universe 2>/dev/null || true
sudo add-apt-repository -y multiverse 2>/dev/null || true
sudo add-apt-repository -y restricted 2>/dev/null || true
sudo apt update

# 3. Pre-aceptar licencias de tipografías
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections

# 4. Software Esencial y Utilidades de Sistema (GNOME)
echo "ℹ️ [3/10] Instalando utilidades esenciales del sistema..."
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
    7zip \
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
    gnome-software-plugin-flatpak \
    gnome-tweaks \
    wl-clipboard

# 5. Microcódigo y Firmware AMD
echo "ℹ️ [4/10] Instalando microcódigo AMD y firmware oficial..."
sudo apt install -y \
    amd64-microcode \
    linux-firmware

# 6. Stack Gráfico AMD (Mesa / RADV / VA-API / Vulkan)
echo "ℹ️ [5/10] Instalando controladores gráficos AMD Mesa (RADV/RadeonSI)..."
sudo apt install -y \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    vulkan-tools \
    vainfo \
    radeontop \
    mesa-utils

# Vulkan 32-bit (solo si Wine/Proton o multiarch están activos)
if dpkg --print-foreign-architectures | grep -q "i386"; then
    echo "ℹ️ [6/10] Arquitectura i386 detectada: Instalando Mesa Vulkan 32-bit..."
    sudo apt install -y mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 || true
else
    echo "ℹ️ [6/10] Arquitectura i386 no habilitada (se omite driver 32-bit)."
fi

# 7. Codecs Multimedia
echo "ℹ️ [7/10] Instalando códecs multimedia y plugins GStreamer..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    ubuntu-restricted-extras \
    libavcodec-extra \
    ffmpeg \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav

# gstreamer1.0-vaapi (solo en versiones que mantengan el paquete separado; en GStreamer moderno viene integrado en plugins-bad)
if apt-cache show gstreamer1.0-vaapi &>/dev/null; then
    sudo apt install -y gstreamer1.0-vaapi 2>/dev/null || true
fi

# 8. Memoria ZRAM
echo "ℹ️ [8/10] Configurando swap comprimida en RAM (ZRAM)..."
if [ -f "$(dirname "$0")/zram-setup.sh" ]; then
    bash "$(dirname "$0")/zram-setup.sh"
else
    sudo apt install -y zram-tools
    echo -e "ALGORITHM=zstd\nPERCENT=50" | sudo tee /etc/default/zramswap > /dev/null
    sudo systemctl enable --now zramswap.service 2>/dev/null || true
fi

# 9. Limpieza de paquetes residuales
echo "ℹ️ [9/10] Limpiando dependencias huérfanas..."
sudo apt autoremove -y
sudo apt clean

# 10. Verificación
echo "ℹ️ [10/10] Verificando aceleración VA-API de AMD Vega..."
vainfo 2>/dev/null || echo "⚠️ vainfo reportó detalles, verifica permisos o reinicia para cargar el nuevo kernel."

echo "================================================================="
echo "✅ Post-instalación AMD completada con éxito en Ubuntu."
echo "💡 Se recomienda reiniciar el equipo para cargar el microcódigo y drivers actualizados."
echo "================================================================="
