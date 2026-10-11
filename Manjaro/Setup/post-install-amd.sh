#!/bin/bash
# post-install-amd.sh - Post-instalación para Manjaro Linux (GNOME) con AMD Ryzen y AMD Radeon Graphics
# Optimizado para Manjaro 26.1 GNOME - elimina paquetes ya instalados por defecto

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

# 2. Herramientas de desarrollo y utilidades adicionales (NO incluidas por defecto)
echo "ℹ️ Instalando herramientas de desarrollo y utilidades adicionales..."
sudo pacman -S --needed --noconfirm \
    base-devel \
    cmake \
    curl \
    wget \
    ca-certificates \
    gnupg \
    btop \
    fuse2 \
    fuse3 \
    exfatprogs \
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
    pamac-flatpak-plugin

# 3. Kernel Headers correspondientes al kernel en ejecución
echo "ℹ️ Instalando cabeceras del Kernel actual..."
CURRENT_KERNEL=$(uname -r | cut -d. -f1,2 | tr -d '.')
if sudo pacman -S --needed --noconfirm "linux${CURRENT_KERNEL}-headers" 2>/dev/null; then
    echo "✅ Cabeceras linux${CURRENT_KERNEL}-headers instaladas."
else
    sudo pacman -S --needed --noconfirm linux-headers 2>/dev/null || true
fi

# 4. Herramientas de diagnóstico GPU (no incluidas por defecto)
echo "ℹ️ Instalando herramientas de diagnóstico GPU..."
sudo pacman -S --needed --noconfirm \
    vulkan-tools \
    libva-utils \
    radeontop

# 5. Codecs Multimedia adicionales (ffmpeg y gst-libav no vienen por defecto)
echo "ℹ️ Instalando codecs multimedia adicionales..."
sudo pacman -S --needed --noconfirm \
    ffmpeg \
    gst-libav

# 6. Extension Manager (no incluido por defecto)
echo "ℹ️ Instalando Extension Manager para GNOME..."
sudo pacman -S --needed --noconfirm extension-manager 2>/dev/null || true

# 7. Configuración de SWAP comprimida en RAM (ZRAM con ZSTD)
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

# 8. Habilitar repositorio Flathub
echo "ℹ️ Habilitando repositorio Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 9. Limpieza de caché
echo "ℹ️ Limpiando paquetes temporales..."
sudo pacman -Sc --noconfirm || true

echo "================================================================="
echo "🎉 ¡Post-instalación de Manjaro Linux (AMD Ryzen) completada con éxito!"
echo "💡 Se recomienda reiniciar el sistema para aplicar todos los módulos del Kernel."
echo "================================================================="
