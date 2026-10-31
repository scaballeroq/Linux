#!/bin/bash
# ==============================================================================
# post-install-amd.sh - Post-instalación para Debian con AMD Ryzen y AMD Graphics
# Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics (Vega 8))
# Sistema: Debian GNU/Linux 13 (Trixie) | Entorno: GNOME Shell (Wayland)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: DEBIAN (GNOME SHELL) - AMD RYZEN"
echo "================================================================="

CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "trixie")
fi

echo "Debian detectado: $CODENAME"

# 1. Actualización Base y Herramientas de Gestión de Repositorios
echo "ℹ️ [1/10] Actualizando repositorios y herramientas base..."
sudo apt update
sudo apt install -y curl wget ca-certificates gnupg lsb-release

# 2. Habilitar Repositorios Extra (Contrib, Non-Free, Non-Free-Firmware)
echo "ℹ️ [2/10] Habilitando contrib, non-free y non-free-firmware para $CODENAME..."
# Soporte para formato moderno deb822 (/etc/apt/sources.list.d/debian.sources)
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sudo sed -i '/^Components:/ {/contrib/! s/$/ contrib/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
    sudo sed -i '/^Components:/ {/non-free/! s/$/ non-free/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
    sudo sed -i '/^Components:/ {/non-free-firmware/! s/$/ non-free-firmware/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
fi
# Soporte para sources.list tradicional
if [ -f /etc/apt/sources.list ]; then
    sudo sed -i '/^deb / {/contrib/! s/\(main\)/\1 contrib non-free non-free-firmware/}' /etc/apt/sources.list 2>/dev/null || true
fi

sudo apt update
sudo apt upgrade -y

# 3. Pre-aceptar licencias de tipografías si aplica (ttf-mscorefonts-installer)
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections 2>/dev/null || true

# 4. Software Esencial y Utilidades de Sistema (GNOME)
echo "ℹ️ [3/10] Instalando utilidades esenciales del sistema..."
sudo apt install -y \
    build-essential \
    linux-headers-amd64 \
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
    p7zip-full \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz-utils \
    fastfetch \
    ca-certificates \
    gnupg \
    flatpak \
    gnome-software-plugin-flatpak \
    gnome-tweaks \
    power-profiles-daemon \
    switcheroo-control \
    wl-clipboard 2>/dev/null || true

# Compatibilidad FUSE para AppImages en Debian (transición time64 libfuse2t64 vs libfuse2)
sudo apt install -y libfuse2t64 2>/dev/null || sudo apt install -y libfuse2 2>/dev/null || true

# 5. Microcódigo y Firmware AMD oficial
echo "ℹ️ [4/10] Instalando microcódigo AMD y firmware oficial..."
sudo apt install -y \
    amd64-microcode \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-amd-graphics \
    firmware-misc-nonfree 2>/dev/null || sudo apt install -y amd64-microcode firmware-linux-nonfree 2>/dev/null || true

# 6. Stack Gráfico AMD (Mesa / RADV / VA-API / Vulkan)
echo "ℹ️ [5/10] Instalando controladores gráficos AMD Mesa (RADV/RadeonSI)..."
sudo apt install -y \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    mesa-vulkan-drivers \
    vulkan-tools \
    vainfo \
    radeontop \
    mesa-utils \
    libgl1-mesa-dri 2>/dev/null || sudo apt install -y mesa-va-drivers mesa-vulkan-drivers vainfo || true

# Vulkan 32-bit (solo si Wine/Proton o multiarch están activos)
if dpkg --print-foreign-architectures 2>/dev/null | grep -q "i386"; then
    echo "ℹ️ [6/10] Arquitectura i386 detectada: Instalando Mesa Vulkan 32-bit..."
    sudo apt install -y mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 || true
else
    echo "ℹ️ [6/10] Arquitectura i386 no habilitada (se omite driver 32-bit)."
fi

# 7. Codecs Multimedia y FFmpeg para Debian
echo "ℹ️ [7/10] Instalando códecs multimedia y plugins GStreamer..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    ffmpeg \
    libavcodec-extra \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-gl \
    gstreamer1.0-pipewire 2>/dev/null || true

# Servidor de audio PipeWire & WirePlumber nativo
sudo apt install -y pipewire pipewire-alsa pipewire-pulse wireplumber 2>/dev/null || true
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 8. Memoria ZRAM
echo "ℹ️ [8/10] Configurando swap comprimida en RAM (ZRAM con ZSTD)..."
if [ -f "$(dirname "$0")/zram-setup.sh" ]; then
    bash "$(dirname "$0")/zram-setup.sh"
else
    sudo apt install -y zram-tools 2>/dev/null || true
    if [ -f /etc/default/zramswap ]; then
        sudo sed -i 's/^#*ALGORITHM=.*/ALGORITHM=zstd/' /etc/default/zramswap
        sudo sed -i 's/^#*PERCENT=.*/PERCENT=50/' /etc/default/zramswap
        sudo systemctl restart zramswap.service 2>/dev/null || true
    fi
fi

# 9. Integración de Flathub para Flatpak
echo "ℹ️ [9/10] Registrando repositorio Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# Limpieza de paquetes residuales
echo "ℹ️ Limpiando dependencias huérfanas..."
sudo apt autoremove -y
sudo apt clean

# 10. Verificación
echo "ℹ️ [10/10] Verificando aceleración VA-API de AMD Vega..."
vainfo 2>/dev/null || echo "⚠️ vainfo reportó detalles, verifica permisos o reinicia para cargar el nuevo kernel y firmware."

echo "================================================================="
echo "✅ Post-instalación AMD completada con éxito en Debian ($CODENAME)."
echo "💡 Se recomienda reiniciar el equipo para arrancar con el microcódigo y drivers actualizados."
echo "================================================================="
