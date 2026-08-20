#!/bin/bash
# post-install-amd.sh - Script de post-instalación para OpenSUSE Tumbleweed con AMD Ryzen y AMD Graphics
# (Configurado con ZRAM, Zypper optimizado, Repositorio Packman, Microcódigo AMD, Mesa Vulkan/RADV/VA-API, PipeWire, OPI y Suite GNOME)

set -euo pipefail

echo "================================================================="
echo "🚀 INICIANDO POST-INSTALACIÓN: OPENSUSE TUMBLEWEED - AMD RYZEN"
echo "================================================================="

# 1. Optimización de Zypper
echo "ℹ️ Configurando optimizaciones en Zypper (/etc/zypp/zypp.conf)..."
if [ -f /etc/zypp/zypp.conf ]; then
    sudo sed -i 's/^#* *solver.allowVendorChange *=.*/solver.allowVendorChange = true/' /etc/zypp/zypp.conf 2>/dev/null || true
    sudo sed -i 's/^#* *download.max_concurrent_connections *=.*/download.max_concurrent_connections = 10/' /etc/zypp/zypp.conf 2>/dev/null || true
fi

# 2. Habilitar Repositorio Packman (Esencial para codecs multimedia en openSUSE)
echo "ℹ️ Habilitando repositorio Packman Tumbleweed con prioridad 90..."
if ! zypper lr | grep -qi "packman"; then
    sudo zypper --non-interactive ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman || true
fi

echo "ℹ️ Actualizando repositorios y cambiando codecs a Packman..."
sudo zypper --gpg-auto-import-keys refresh
sudo zypper --non-interactive dup --from packman --allow-vendor-change || true

# 3. Instalación de OPI (OBS Package Installer - equivalente a AUR helper)
echo "ℹ️ Instalando OPI (Open Build Service Package Installer)..."
sudo zypper --non-interactive install -y opi || true

# 4. Compresión de Memoria ZRAM
echo "ℹ️ Configurando ZRAM con algoritmo ZSTD al 50% de RAM..."
sudo zypper --non-interactive install -y systemd-zram-service zram-generator 2>/dev/null || true
sudo mkdir -p /etc/systemd
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF
sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

# 5. Kernel Linux, Firmware y Microcódigo específico para AMD Ryzen
echo "ℹ️ Instalando Kernel Linux, Firmware oficial y Microcódigo para AMD Ryzen..."
sudo zypper --non-interactive install -y \
    kernel-default \
    kernel-default-devel \
    kernel-devel \
    kernel-firmware-amdgpu \
    kernel-firmware-radeon \
    ucode-amd 2>/dev/null || true

# 6. Stack Gráfico y Aceleración HW para AMD (Mesa / RADV / VA-API / Vulkan)
echo "ℹ️ Instalando controladores gráficos AMD Mesa (RADV/RadeonSI) y aceleración de hardware..."
sudo zypper --non-interactive install -y \
    Mesa \
    Mesa-dri \
    Mesa-vulkan-device-select \
    libvulkan_radeon \
    libvulkan_radeon-32bit \
    libva-vdpau-driver \
    libva-utils \
    vulkan-tools \
    radeontop 2>/dev/null || true

# 7. Codecs Multimedia y FFmpeg completo (Packman)
echo "ℹ️ Instalando FFmpeg completo y codecs multimedia de alto rendimiento..."
sudo zypper --non-interactive install -y \
    ffmpeg \
    gstreamer-plugins-base \
    gstreamer-plugins-good \
    gstreamer-plugins-bad \
    gstreamer-plugins-ugly \
    gstreamer-plugins-libav \
    gstreamer-plugins-vaapi \
    libdvdread8 \
    libdvdnav4 2>/dev/null || true

# 8. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "ℹ️ Verificando y habilitando PipeWire y WirePlumber..."
sudo zypper --non-interactive install -y \
    pipewire \
    pipewire-pulseaudio \
    pipewire-alsa \
    pipewire-jack \
    wireplumber 2>/dev/null || true

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 9. Entorno de Escritorio GNOME y Aplicaciones Base
echo "ℹ️ Instalando componentes y utilidades base de GNOME..."
sudo zypper --non-interactive install -y -t pattern gnome_basis gnome 2>/dev/null || true
sudo zypper --non-interactive install -y \
    gnome-tweaks \
    ptyxis \
    nautilus \
    gnome-text-editor \
    gnome-calculator \
    gnome-disk-utility \
    gnome-system-monitor \
    power-profiles-daemon \
    switcheroo-control \
    ffmpegthumbnailer \
    evince \
    seahorse 2>/dev/null || true

# 10. Integración de Flatpak & Flathub en GNOME Software
echo "ℹ️ Configurando Flatpak y Flathub para GNOME Software..."
sudo zypper --non-interactive install -y flatpak gnome-software 2>/dev/null || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 11. Software Esencial de Sistema
echo "ℹ️ Instalando utilidades esenciales para OpenSUSE Tumbleweed..."
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
    vlc \
    gimp \
    gparted \
    p7zip \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz \
    fastfetch 2>/dev/null || true

# 12. Limpieza de Paquetes Antiguos
echo "ℹ️ Limpiando paquetes huérfanos y caché de Zypper..."
sudo zypper --non-interactive clean -a

echo "================================================================="
echo "✅ OpenSUSE Tumbleweed + GNOME (AMD Ryzen) configurado con éxito."
echo "💡 Se recomienda reiniciar el equipo para arrancar con el nuevo Kernel Linux, drivers AMD y ZRAM."
echo "================================================================="
