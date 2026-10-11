#!/bin/bash
# post-install-intel.sh - Post-instalación para Manjaro Linux (GNOME) con Intel Core / Media Center (Kodi + Streaming)
# (Configurado con ZRAM, Microcódigo Intel, Intel VA-API / QuickSync, Mesa Vulkan, Kodi, PipeWire y GNOME)

set -euo pipefail

echo "================================================================="
echo "🚀 INICIANDO POST-INSTALACIÓN: MANJARO LINUX (GNOME) - INTEL MEDIA CENTER"
echo "================================================================="

# 1. Optimización de Espejos y Actualización del Sistema
echo "ℹ️ Optimizando espejos más rápidos con pacman-mirrors..."
if command -v pacman-mirrors &> /dev/null; then
    sudo pacman-mirrors --fasttrack 5 || true
fi

echo "ℹ️ Actualizando base de datos de paquetes y sistema completo..."
sudo pacman -Syu --noconfirm

# 2. Utilidades Base y Herramientas
echo "ℹ️ Instalando herramientas base de sistema y multimedia..."
sudo pacman -S --needed --noconfirm \
    base-devel \
    curl \
    wget \
    ca-certificates \
    gnupg \
    btop \
    htop \
    inxi \
    fuse2 \
    fuse3 \
    exfatprogs \
    7zip \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz \
    vlc \
    gimp \
    gparted \
    seahorse \
    evince \
    eza \
    bat \
    ripgrep \
    fd \
    zoxide \
    duf \
    pamac-cli \
    flatpak

# 3. Kernel Headers correspondientes al kernel en ejecución
echo "ℹ️ Instalando cabeceras del Kernel actual..."
CURRENT_KERNEL=$(uname -r | cut -d. -f1,2 | tr -d '.')
if sudo pacman -S --needed --noconfirm "linux${CURRENT_KERNEL}-headers" 2>/dev/null; then
    echo "✅ Cabeceras linux${CURRENT_KERNEL}-headers instaladas."
else
    sudo pacman -S --needed --noconfirm linux-headers 2>/dev/null || true
fi

# 4. Microcódigo y Firmware para Intel Core
echo "ℹ️ Instalando microcódigo Intel y firmware..."
sudo pacman -S --needed --noconfirm \
    intel-ucode \
    linux-firmware

# 5. Pila Gráfica Intel, Aceleración VA-API (QuickSync) y Vulkan
echo "ℹ️ Instalando controladores gráficos Intel Mesa (VA-API / QuickSync / Vulkan)..."
sudo pacman -S --needed --noconfirm \
    mesa \
    lib32-mesa \
    vulkan-intel \
    lib32-vulkan-intel \
    intel-media-driver \
    libva-intel-driver \
    libva-utils \
    mesa-utils \
    vulkan-tools \
    intel-gpu-tools 2>/dev/null || sudo pacman -S --needed --noconfirm mesa vulkan-intel intel-media-driver libva-intel-driver libva-utils || true

# 6. Centro Multimedia y Streaming (Kodi + Addons nativos)
echo "ℹ️ Instalando Kodi y suite de addons para streaming multimedia..."
sudo pacman -S --needed --noconfirm \
    kodi \
    kodi-addon-inputstream-adaptive \
    kodi-addon-inputstream-rtmp \
    kodi-addon-pvr-iptvsimple

# 7. Codecs Multimedia de Alto Rendimiento
echo "ℹ️ Instalando codecs multimedia FFmpeg y GStreamer..."
sudo pacman -S --needed --noconfirm \
    ffmpeg \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav

# 8. Servidor de Audio PipeWire + WirePlumber
echo "ℹ️ Habilitando servidor de audio PipeWire..."
sudo pacman -S --needed --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 9. Entorno de Escritorio GNOME
echo "ℹ️ Instalando componentes base de GNOME..."
sudo pacman -S --needed --noconfirm \
    gnome-shell \
    gnome-control-center \
    gnome-tweaks \
    ptyxis \
    nautilus \
    file-roller \
    gnome-text-editor \
    gnome-calculator \
    gnome-disk-utility \
    gnome-browser-connector \
    extension-manager 2>/dev/null || sudo pacman -S --needed --noconfirm gnome-shell gnome-control-center gnome-tweaks nautilus file-roller || true

# 10. Configuración de ZRAM con ZSTD
echo "ℹ️ Configurando ZRAM con algoritmo ZSTD..."
sudo pacman -S --needed --noconfirm zram-generator 2>/dev/null || true
if [ -d "/etc/systemd" ]; then
    sudo tee /etc/systemd/zram-generator.conf > /dev/null <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
fi

# 11. Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 12. Limpieza
sudo pacman -Sc --noconfirm || true

echo "================================================================="
echo "🎉 ¡Post-instalación de Manjaro Linux (Intel Media Center) completada con éxito!"
echo "💡 Se recomienda reiniciar el sistema para aplicar todos los módulos del Kernel."
echo "================================================================="
