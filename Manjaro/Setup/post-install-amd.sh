#!/bin/bash
# post-install-amd.sh - Post-instalación para Manjaro Linux (GNOME) con AMD Ryzen y AMD Radeon Graphics
# (Configurado con ZRAM, Microcódigo AMD, Mesa RADV/VA-API, PipeWire, GNOME Suite y Pamac/Flatpak)

set -euo pipefail

echo "================================================================="
echo "🚀 INICIANDO POST-INSTALACIÓN: MANJARO LINUX (GNOME) - AMD RYZEN"
echo "================================================================="

# 1. Optimización de Espejos y Actualización del Sistema
echo "ℹ️ Optimizando espejos más rápidos con pacman-mirrors..."
if command -v pacman-mirrors &> /dev/null; then
    sudo pacman-mirrors --fasttrack 5 || true
fi

echo "ℹ️ Actualizando base de datos de paquetes y sistema completo..."
sudo pacman -Syu --noconfirm

# 2. Utilidades Base y Herramientas de Compilación
echo "ℹ️ Instalando herramientas base de desarrollo y utilidades..."
sudo pacman -S --needed --noconfirm \
    base-devel \
    cmake \
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

# Intentar instalar plugin Flatpak para Pamac si está disponible
sudo pacman -S --needed --noconfirm libpamac-flatpak-plugin 2>/dev/null || true

# 3. Kernel Headers correspondientes al kernel en ejecución
echo "ℹ️ Instalando cabeceras del Kernel actual..."
CURRENT_KERNEL=$(uname -r | cut -d. -f1,2 | tr -d '.')
if sudo pacman -S --needed --noconfirm "linux${CURRENT_KERNEL}-headers" 2>/dev/null; then
    echo "✅ Cabeceras linux${CURRENT_KERNEL}-headers instaladas."
else
    sudo pacman -S --needed --noconfirm linux-headers 2>/dev/null || true
fi

# 4. Microcódigo y Firmware para AMD Ryzen
echo "ℹ️ Instalando microcódigo AMD y firmware..."
sudo pacman -S --needed --noconfirm \
    amd-ucode \
    linux-firmware

# 5. Pila Gráfica, Vulkan (RADV) y Aceleración de Hardware VA-API
echo "ℹ️ Instalando controladores gráficos AMD Mesa (RADV / VA-API / Vulkan)..."
sudo pacman -S --needed --noconfirm \
    mesa \
    lib32-mesa \
    vulkan-radeon \
    lib32-vulkan-radeon \
    libva-mesa-driver \
    lib32-libva-mesa-driver \
    mesa-utils \
    vulkan-tools \
    libva-utils \
    radeontop 2>/dev/null || sudo pacman -S --needed --noconfirm mesa vulkan-radeon libva-mesa-driver mesa-utils libva-utils || true

# 6. Codecs Multimedia
echo "ℹ️ Instalando codecs multimedia de alto rendimiento..."
sudo pacman -S --needed --noconfirm \
    ffmpeg \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav

# 7. Servidor de Audio PipeWire + WirePlumber
echo "ℹ️ Habilitando servidor de audio PipeWire..."
sudo pacman -S --needed --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 8. Entorno de Escritorio GNOME y Extensiones Base
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
    power-profiles-daemon \
    gnome-browser-connector \
    extension-manager 2>/dev/null || sudo pacman -S --needed --noconfirm gnome-shell gnome-control-center gnome-tweaks nautilus file-roller || true

# 9. Configuración de SWAP comprimida en RAM (ZRAM con ZSTD)
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

# 10. Habilitar repositorio Flathub
echo "ℹ️ Habilitando repositorio Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 11. Limpieza de caché
echo "ℹ️ Limpiando paquetes temporales..."
sudo pacman -Sc --noconfirm || true

echo "================================================================="
echo "🎉 ¡Post-instalación de Manjaro Linux (AMD Ryzen) completada con éxito!"
echo "💡 Se recomienda reiniciar el sistema para aplicar todos los módulos del Kernel."
echo "================================================================="
