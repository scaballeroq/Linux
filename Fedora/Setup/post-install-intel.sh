#!/bin/bash
# post-install-intel.sh - Script de post-instalacion para Fedora 44 con Intel Core (Haswell/i7-4790) + Multimedia (Kodi/Streaming)
# (Configurado con ZRAM, DNF5 paralelo, RPM Fusion, Microcodigo Intel, VA-API Intel HD, Codecs, Kodi, PipeWire)

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACION: FEDORA 44 - INTEL CORE / MEDIA CENTER"
echo "Optimizado para sobremesa Intel Haswell (i7-4790 / HD Graphics 4600)"
echo "Configuracion multimedia para Kodi, Netflix, Prime Video y streaming"
echo "================================================================="

# 1. Optimizacion DNF5
echo "Configurando optimizaciones en DNF5..."
DNF5_CONF="/etc/dnf5/dnf5.conf"
if [ -f "$DNF5_CONF" ]; then
    if ! grep -q "max_parallel_downloads" "$DNF5_CONF"; then
        echo "max_parallel_downloads=10" | sudo tee -a "$DNF5_CONF" > /dev/null
    fi
    if ! grep -q "defaultyes" "$DNF5_CONF"; then
        echo "defaultyes=True" | sudo tee -a "$DNF5_CONF" > /dev/null
    fi
fi

# 2. Habilitar Repositorios RPM Fusion (Free y Non-Free)
echo "Habilitando repositorios oficiales RPM Fusion Free y Non-Free..."
sudo dnf5 install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>/dev/null || true

sudo dnf5 install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data 2>/dev/null || true

# Actualizar metadatos y sistema
echo "Actualizando base del sistema..."
sudo dnf5 upgrade --refresh -y

# 3. Compresion de Memoria ZRAM (Nativa en Fedora con zram-generator)
echo "Configurando ZRAM con algoritmo ZSTD..."
sudo dnf5 install -y zram-generator zram-generator-defaults 2>/dev/null || true
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF
sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

# 4. Kernel Linux, Firmware y Microcodigo Intel
echo "Instalando Kernel Linux, Firmware oficial y Microcodigo Intel..."
sudo dnf5 install -y \
    kernel \
    kernel-core \
    kernel-modules \
    kernel-devel \
    kernel-headers \
    linux-firmware \
    microcode_ctl 2>/dev/null || true

# 5. Stack Grafico Intel y Aceleracion HW por Video (VA-API Haswell / i965 / Intel HD 4600)
echo "Instalando controladores graficos Intel y aceleracion de video por hardware..."
sudo dnf5 install -y \
    libva-intel-driver \
    intel-media-driver \
    libva \
    libva-utils \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    mesa-va-drivers-freeworld \
    mesa-vdpau-drivers-freeworld \
    vulkan-tools \
    intel-gpu-tools 2>/dev/null || true

# Configurar driver VA-API por defecto para Intel Haswell (Gen 7.5)
if [ ! -f /etc/environment.d/90-intel-vaapi.conf ]; then
    sudo mkdir -p /etc/environment.d
    echo "LIBVA_DRIVER_NAME=i965" | sudo tee /etc/environment.d/90-intel-vaapi.conf > /dev/null
fi

# Vulkan 32-bit (solo para Wine/Proton gaming)
if command -v wine &>/dev/null || command -v proton &>/dev/null; then
    echo "Wine/Proton detectado. Instalando drivers Vulkan 32-bit..."
    sudo dnf5 install -y mesa-vulkan-drivers.i686 2>/dev/null || true
fi

# 6. Codecs Multimedia de Alto Rendimiento y Reproduccion (Streaming / DRM)
echo "Instalando FFmpeg completo y codecs multimedia para streaming y video..."
sudo dnf5 config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
sudo dnf5 swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null || sudo dnf5 install -y ffmpeg 2>/dev/null || true
sudo dnf5 update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y 2>/dev/null || true
sudo dnf5 install -y \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly \
    gstreamer1-plugin-openh264 \
    gstreamer1-vaapi \
    libbluray \
    libdvdread \
    libdvdnav \
    lsdvd 2>/dev/null || true

# 7. Centro Multimedia (Kodi y complementos de streaming)
echo "Instalando centro multimedia Kodi y complementos para streaming adaptativo..."
sudo dnf5 install -y \
    kodi \
    kodi-inputstream-adaptive \
    kodi-inputstream-rtmp \
    kodi-pvr-iptvsimple 2>/dev/null || true

# 8. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "Habilitando servidor de audio moderno PipeWire y WirePlumber..."
sudo dnf5 install -y \
    pipewire \
    pipewire-pulseaudio \
    pipewire-alsa \
    pipewire-jack-audio-connection-kit \
    wireplumber 2>/dev/null || true

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 9. Software Esencial de Sistema (Sin herramientas de virtualizacion KVM)
echo "Instalando utilidades esenciales para Fedora 44..."
sudo dnf5 install -y \
    @development-tools \
    cmake \
    curl \
    btop \
    htop \
    inxi \
    fuse-libs \
    exfatprogs \
    vlc \
    gimp \
    gparted \
    p7zip \
    p7zip-plugins \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz \
    fastfetch 2>/dev/null || true

# 10. Integracion de Flatpak & Flathub
echo "Configurando Flatpak y Flathub..."
sudo dnf5 install -y flatpak 2>/dev/null || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 11. Limpieza de Paquetes Antiguos
echo "Limpiando paquetes obsoletos..."
sudo dnf5 autoremove -y
sudo dnf5 clean all

echo "================================================================="
echo "Fedora 44 Workstation (Intel Haswell / Media Center) configurado con exito."
echo "Aceleracion grafica por hardware i965 activada y Kodi instalado."
echo "Para Netflix y Prime Video en Firefox: Ve a Ajustes de Firefox -> General -> 'Reproducir contenido con control DRM'."
echo "Se recomienda reiniciar el equipo para arrancar con el nuevo Kernel, drivers Intel y ZRAM."
echo "================================================================="
