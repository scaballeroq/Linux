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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Configuración de Repositorio Chaotic-AUR y Optimización de Pacman
echo "ℹ️ [1/8] Configurando repositorio Chaotic-AUR y optimizaciones de Pacman..."
if [ -f "$SCRIPT_DIR/chaotic-aur.sh" ]; then
    bash "$SCRIPT_DIR/chaotic-aur.sh"
else
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf || true
    sudo sed -i 's/^#ParallelDownloads = .*/ParallelDownloads = 8/' /etc/pacman.conf || true
fi

# 2. CPU Microcode y Drivers Gráficos AMD (Ryzen 7 7730U + Radeon Graphics)
echo "ℹ️ [2/8] Instalando Microcode AMD, Mesa RADV Vulkan y aceleración VA-API por Hardware..."
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

# 3. Optimización de Hardware Portátil (HP ProBook: brillo, energía, bluetooth)
echo "ℹ️ [3/8] Instalando utilidades de hardware para portátil (brillo, perfiles de energía)..."
sudo pacman -S --needed --noconfirm \
    brightnessctl \
    power-profiles-daemon \
    bluez \
    bluez-utils \
    upower

# Habilitar servicios de gestión de energía y Bluetooth
sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
sudo systemctl enable --now bluetooth.service 2>/dev/null || true

# 4. Audio PipeWire & WirePlumber
echo "ℹ️ [4/8] Verificando servidor de sonido PipeWire y WirePlumber..."
sudo pacman -S --needed --noconfirm \
    pipewire \
    wireplumber \
    pipewire-audio \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack

# 5. Optimización de Memoria (ZRAM para 32 GB RAM) y Mantenimiento de SSD NVMe
echo "ℹ️ [5/8] Configurando ZRAM swap (zstd) y temporizador TRIM para SSD NVMe..."
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

# 6. Herramientas nativas Wayland y utilidades esenciales de terminal
echo "ℹ️ [6/8] Instalando herramientas de escritorio Wayland y utilidades modernas..."
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

# 7. Codecs Multimedia extendidos (GStreamer)
echo "ℹ️ [7/8] Configurando codecs multimedia extendidos..."
sudo pacman -S --needed --noconfirm \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav

# 8. Verificación y diagnóstico de repositorios y paquetes
echo "ℹ️ [8/8] Verificando estado final de repositorios y Chaotic-AUR..."
if [ -f "$SCRIPT_DIR/chaotic-aur.sh" ]; then
    bash "$SCRIPT_DIR/chaotic-aur.sh" --status
fi

echo ""
echo "================================================================="
echo "✅ Optimización Post-Instalación de Omarchy completada con éxito."
echo "💡 Hardware preparado: AMD Ryzen 7 7730U, Radeon Graphics VA-API,"
echo "   ZRAM (16GB zstd), fstrim.timer, brightnessctl y PipeWire."
echo "================================================================="
