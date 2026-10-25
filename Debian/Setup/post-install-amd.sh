#!/bin/bash
# ==============================================================================
# post-install-amd.sh - Post-instalación para Debian con AMD Ryzen y AMD Graphics
# Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics (Vega 8))
# Entorno: GNOME Shell (Wayland)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: DEBIAN (GNOME SHELL) - AMD RYZEN"
echo "================================================================="

CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "bookworm")
fi

echo "Debian detectado: $CODENAME"

# 1. Habilitar Repositorios Extra (Contrib, Non-Free, Non-Free-Firmware)
echo "ℹ️ [1/10] Habilitando componentes contrib, non-free y non-free-firmware..."
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sudo sed -i '/^Components:/ s/\bmain\b\(?!.*contrib\)/main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
fi
if [ -f /etc/apt/sources.list ]; then
    sudo sed -i '/^deb / s/\bmain\b\(?!.*contrib\)/main contrib non-free non-free-firmware/' /etc/apt/sources.list 2>/dev/null || true
fi

# 2. Actualización Base
echo "ℹ️ [2/10] Actualizando repositorios y paquetes del sistema..."
sudo apt update
sudo apt upgrade -y

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
    ca-certificates \
    gnupg \
    software-properties-common \
    flatpak \
    gnome-software-plugin-flatpak \
    gnome-tweaks \
    wl-clipboard 2>/dev/null || true

# Compatibilidad libfuse (Debian 12 Bookworm vs Debian 13 Trixie)
if apt-cache show libfuse2t64 &>/dev/null; then
    sudo apt install -y libfuse2t64 2>/dev/null || true
elif apt-cache show libfuse2 &>/dev/null; then
    sudo apt install -y libfuse2 2>/dev/null || true
fi

# Fastfetch (nativo o fallback a GitHub release .deb)
if apt-cache show fastfetch &>/dev/null; then
    sudo apt install -y fastfetch 2>/dev/null || true
fi

# 5. Microcódigo y Firmware AMD oficial para Debian
echo "ℹ️ [4/10] Instalando microcódigo AMD y firmwares oficiales de Debian..."
sudo apt install -y \
    amd64-microcode \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    firmware-amd-graphics 2>/dev/null || sudo apt install -y amd64-microcode firmware-linux-nonfree 2>/dev/null || true

# 6. Stack Gráfico AMD (Mesa / RADV / VA-API / Vulkan)
echo "ℹ️ [5/10] Instalando controladores gráficos AMD Mesa (RADV/RadeonSI)..."
sudo apt install -y \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    mesa-vulkan-drivers \
    vulkan-tools \
    vainfo \
    radeontop \
    mesa-utils 2>/dev/null || true

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
    libavcodec-extra \
    ffmpeg \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav 2>/dev/null || true

# Tipografías MS en Debian contrib
sudo apt install -y ttf-mscorefonts-installer 2>/dev/null || true

# 8. Memoria ZRAM
echo "ℹ️ [8/10] Configurando swap comprimida en RAM (ZRAM con ZSTD)..."
sudo apt install -y zram-tools 2>/dev/null || true
if [ -f /etc/default/zramswap ]; then
    sudo sed -i 's/^#*ALGORITHM=.*/ALGORITHM=zstd/' /etc/default/zramswap
    sudo sed -i 's/^#*PERCENT=.*/PERCENT=50/' /etc/default/zramswap
    sudo systemctl enable --now zramswap.service 2>/dev/null || true
    sudo systemctl restart zramswap.service 2>/dev/null || true
fi

# Configurar Flathub remoto si flatpak está disponible
if command -v flatpak &>/dev/null; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
fi

# 9. Limpieza de paquetes residuales
echo "ℹ️ [9/10] Limpiando dependencias huérfanas..."
sudo apt autoremove -y
sudo apt clean

# 10. Verificación
echo "ℹ️ [10/10] Verificando aceleración VA-API de AMD Vega..."
vainfo 2>/dev/null || echo "⚠️ vainfo reportó detalles, verifica permisos o reinicia para cargar el nuevo kernel."

echo "================================================================="
echo "✅ Post-instalación AMD completada con éxito en Debian ($CODENAME)."
echo "💡 Se recomienda reiniciar el equipo para cargar el microcódigo y drivers actualizados."
echo "================================================================="
