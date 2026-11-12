#!/bin/bash
# ==============================================================================
# POST-INSTALL (post-install.sh) - Omarchy (Arch Linux + Hyprland)
# Optimizado para HP ProBook 455 G10
# Hardware: AMD Ryzen 7 7730U (Zen 3 / Barcelo-R), Radeon Graphics (Vega 8),
#           32 GB RAM DDR4, SSD NVMe 512 GB Kioxia, Pantalla eDP-1 + DP-3 + DP-4
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🚀 Configuración Post-Instalación de Omarchy para HP ProBook 455 G10"
echo "================================================================="

# 1. Optimización de pacman.conf
echo "ℹ️ [1/8] Optimizando /etc/pacman.conf (Color, ParallelDownloads, ILoveCandy)..."
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf || true
sudo sed -i 's/^#ParallelDownloads = .*/ParallelDownloads = 10/' /etc/pacman.conf || true
if ! grep -q "^Color" /etc/pacman.conf; then
    sudo sed -i '/\[options\]/a Color' /etc/pacman.conf
fi
if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
    sudo sed -i '/\[options\]/a ParallelDownloads = 10' /etc/pacman.conf
fi
if ! grep -q "ILoveCandy" /etc/pacman.conf; then
    sudo sed -i '/ParallelDownloads/a ILoveCandy' /etc/pacman.conf
fi

# 2. Configuración del repositorio Chaotic-AUR (opcional e idempotente)
echo "ℹ️ [2/8] Verificando repositorio Chaotic-AUR..."
if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
    echo "  🔑 Añadiendo llaves y repositorios de Chaotic-AUR..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
    sudo pacman-key --lsign-key 3056513887B78AEB || true

    sudo pacman -U --needed --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || true

    sudo tee -a /etc/pacman.conf > /dev/null << 'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
    sudo pacman -Sy
else
    echo "  ✔️ El repositorio Chaotic-AUR ya está configurado."
fi

# 3. CPU Microcode y Drivers Gráficos AMD (Ryzen 7 7730U + Radeon Graphics)
echo "ℹ️ [3/8] Instalando Microcode AMD, Mesa RADV Vulkan y aceleración VA-API por Hardware..."
sudo pacman -S --needed --noconfirm \
    amd-ucode \
    mesa \
    lib32-mesa \
    vulkan-radeon \
    lib32-vulkan-radeon \
    vulkan-icd-loader \
    lib32-vulkan-icd-loader \
    libva-mesa-driver \
    lib32-libva-mesa-driver \
    mesa-vdpau \
    lib32-mesa-vdpau \
    libva-utils

# 4. Optimización de Hardware Portátil (HP ProBook: brillo, energía, bluetooth)
echo "ℹ️ [4/8] Instalando utilidades de hardware para portátil (brillo, perfiles de energía)..."
sudo pacman -S --needed --noconfirm \
    brightnessctl \
    power-profiles-daemon \
    bluez \
    bluez-utils \
    upower

# Habilitar servicios de gestión de energía y Bluetooth
sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
sudo systemctl enable --now bluetooth.service 2>/dev/null || true

# 5. Audio PipeWire & WirePlumber
echo "ℹ️ [5/8] Verificando servidor de sonido PipeWire y WirePlumber..."
sudo pacman -S --needed --noconfirm \
    pipewire \
    wireplumber \
    pipewire-audio \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack

# 6. Optimización de Memoria (ZRAM para 32 GB RAM) y Mantenimiento de SSD NVMe
echo "ℹ️ [6/8] Configurando ZRAM swap (zstd) y temporizador TRIM para SSD NVMe..."
sudo pacman -S --needed --noconfirm zram-generator

sudo mkdir -p /etc/systemd
cat <<EOF | sudo tee /etc/systemd/zram-generator.conf > /dev/null
[zram0]
zram-size = min(ram / 2, 16384)
compression-algorithm = zstd
EOF
sudo systemctl daemon-reload
sudo systemctl start /dev/zram0 2>/dev/null || true

# Habilitar fstrim semanal para SSD NVMe Kioxia
sudo systemctl enable --now fstrim.timer

# 7. Herramientas nativas Wayland y utilidades esenciales de terminal
echo "ℹ️ [7/8] Instalando herramientas de escritorio Wayland y utilidades modernas..."
sudo pacman -S --needed --noconfirm \
    wl-clipboard \
    grim \
    slurp \
    satty \
    inxi \
    btop \
    htop \
    ripgrep \
    fd \
    bat \
    eza \
    just \
    fastfetch \
    exfatprogs \
    p7zip \
    unrar \
    gparted

# 8. Codecs Multimedia extendidos (GStreamer)
echo "ℹ️ [8/8] Configurando codecs multimedia extendidos..."
sudo pacman -S --needed --noconfirm \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav

echo ""
echo "================================================================="
echo "✅ Optimización Post-Instalación de Omarchy completada con éxito."
echo "💡 Hardware preparado: AMD Ryzen 7 7730U, Radeon Graphics VA-API,"
echo "   ZRAM (16GB zstd), fstrim.timer, brightnessctl y PipeWire."
echo "================================================================="
