#!/bin/bash
# post-install-intel.sh - Script de post-instalación para OpenSUSE Tumbleweed en Intel Core (Haswell i7-4790 / HD Graphics 4600)
# (Configurado para Centro Multimedia / Media Center: Microcódigo Intel, VA-API i965, Repositorio Oficial OpenH264, Kodi, Flatpak, KDE Plasma 6)

set -euo pipefail

echo "================================================================="
echo "🚀 INICIANDO POST-INSTALACIÓN: OPENSUSE TUMBLEWEED - INTEL CORE / MEDIA CENTER"
echo "================================================================="

# 1. Optimización de Zypper
echo "ℹ️ Configurando optimizaciones en Zypper (/etc/zypp/zypp.conf)..."
if [ -f /etc/zypp/zypp.conf ]; then
    sudo sed -i 's/^#* *download.max_concurrent_connections *=.*/download.max_concurrent_connections = 10/' /etc/zypp/zypp.conf 2>/dev/null || true
fi

# 2. Habilitar Repositorio oficial OpenH264 (Cisco / openSUSE)
echo "ℹ️ Habilitando repositorio oficial OpenH264 e instalando códecs..."
if ! zypper lr 2>/dev/null | grep -qi "openh264"; then
    sudo zypper --non-interactive install -y openSUSE-repos-Tumbleweed 2>/dev/null || true
fi
sudo zypper mr -e repo-openh264 2>/dev/null || sudo zypper mr -e openSUSE:repo-openh264 2>/dev/null || true
sudo zypper --gpg-auto-import-keys refresh 2>/dev/null || true
sudo zypper --non-interactive install -y libopenh264-8 mozilla-openh264 2>/dev/null || true

# 3. Compresión de Memoria ZRAM
echo "ℹ️ Configurando ZRAM al 50% de RAM..."
sudo zypper --non-interactive install -y systemd-zram-service zram-generator 2>/dev/null || true
sudo mkdir -p /etc/systemd
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF
sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

# 4. Kernel Linux, Firmware y Microcódigo específico para Intel Core
echo "ℹ️ Instalando Kernel Linux, Firmware oficial y Microcódigo para Intel Core..."
sudo zypper --non-interactive install -y \
    kernel-default \
    kernel-default-devel \
    kernel-devel \
    kernel-firmware-intel \
    ucode-intel 2>/dev/null || true

# 5. Stack Gráfico y Aceleración HW para Intel (i965 VA-API / Mesa / Vulkan)
echo "ℹ️ Instalando controladores gráficos Intel (VA-API i965 / Mesa DRI / Vulkan)..."
sudo zypper --non-interactive install -y \
    Mesa \
    Mesa-dri \
    Mesa-vulkan-device-select \
    libvulkan_intel \
    libvulkan_intel-32bit \
    intel-vaapi-driver \
    libva-utils \
    vulkan-tools 2>/dev/null || true

# 6. Codecs Multimedia y FFmpeg (Repositorios Oficiales openSUSE)
echo "ℹ️ Instalando FFmpeg y plugins GStreamer oficiales de openSUSE..."
sudo zypper --non-interactive install -y \
    ffmpeg \
    gstreamer-plugins-base \
    gstreamer-plugins-good \
    gstreamer-plugins-bad \
    gstreamer-plugins-libav \
    gstreamer-plugins-vaapi \
    libdvdread8 \
    libdvdnav4 2>/dev/null || true

# 7. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "ℹ️ Verificando y habilitando PipeWire y WirePlumber..."
sudo zypper --non-interactive install -y \
    pipewire \
    pipewire-pulseaudio \
    pipewire-alsa \
    pipewire-jack \
    wireplumber 2>/dev/null || true

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 8. Entorno de Escritorio KDE Plasma 6 y Aplicaciones Base
echo "ℹ️ Instalando componentes base de KDE Plasma 6..."
sudo zypper --non-interactive install -y -t pattern kde_plasma kde 2>/dev/null || true
sudo zypper --non-interactive install -y \
    dolphin \
    kate \
    spectacle \
    kcalc \
    ark \
    gwenview \
    okular \
    plasma-systemmonitor \
    partitionmanager \
    kinfocenter \
    konsole \
    ffmpegthumbnailer \
    kio-extras \
    papirus-icon-theme \
    wl-clipboard 2>/dev/null || true

# 9. Centro Multimedia: Kodi y Complementos de Streaming
echo "ℹ️ Instalando Kodi y plugins oficiales de streaming..."
sudo zypper --non-interactive install -y \
    kodi \
    kodi-inputstream-adaptive \
    kodi-inputstream-rtmp \
    kodi-pvr-iptvsimple 2>/dev/null || true

# 10. Integración de Flatpak & Flathub
echo "ℹ️ Configurando Flatpak y Flathub para KDE Discover..."
sudo zypper --non-interactive install -y flatpak discover plasma-discover-backend-flatpak 2>/dev/null || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 11. Software Esencial de Sistema y Multimedia Flatpak
echo "ℹ️ Instalando utilidades esenciales..."
sudo zypper --non-interactive install -y -t pattern devel_basis 2>/dev/null || true
sudo zypper --non-interactive install -y \
    cmake \
    curl \
    wget \
    btop \
    htop \
    inxi \
    fuse \
    exfatprogs \
    gimp \
    gparted \
    p7zip \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz \
    fastfetch 2>/dev/null || true

echo "ℹ️ Instalando reproductor multimedia desacoplado (VLC) vía Flatpak..."
flatpak install -y --noninteractive flathub org.videolan.VLC 2>/dev/null || true

# 12. Limpieza
echo "ℹ️ Limpiando paquetes y caché de Zypper..."
sudo zypper --non-interactive clean -a

echo "================================================================="
echo "✅ OpenSUSE Tumbleweed (Intel Media Center + Kodi) configurado con éxito."
echo "💡 Se recomienda reiniciar el equipo para aplicar microcódigo, drivers VA-API y ZRAM."
echo "================================================================="
