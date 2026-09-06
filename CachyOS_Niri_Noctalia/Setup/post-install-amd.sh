#!/bin/bash
# post-install-amd.sh - Script de post-instalacion para CachyOS con AMD Ryzen y AMD Graphics
# (Configurado con Pacman optimizado, Microcodigo AMD, Mesa Vulkan/RADV/VA-API, PipeWire, Niri + Noctalia)

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACION: CACHYOS (ARCH LINUX) - AMD RYZEN"
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no esta disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecucion con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# Detectar AUR helper
AUR_HELPER=""
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
fi

# 1. Optimizacion de Pacman (Paralelismo de descargas y colores)
echo "Configurando optimizaciones en Pacman..."
PACMAN_CONF="/etc/pacman.conf"
if [ -f "$PACMAN_CONF" ]; then
    if ! grep -q "ParallelDownloads" "$PACMAN_CONF"; then
        $SUDO sed -i '/^\[options\]/a ParallelDownloads = 10' "$PACMAN_CONF"
    fi
    if ! grep -q "Color" "$PACMAN_CONF"; then
        $SUDO sed -i '/^\[options\]/a Color' "$PACMAN_CONF"
    fi
fi

# Actualizar base del sistema
echo "Actualizando base del sistema..."
$SUDO pacman -Syu --noconfirm

# 2. Kernel Linux, Firmware y Microcodigo para AMD Ryzen
echo "Instalando Kernel Linux, Firmware oficial y Microcodigo para AMD Ryzen..."
$SUDO pacman -S --needed --noconfirm \
    linux-cachyos \
    linux-cachyos-headers \
    amd-ucode \
    linux-firmware 2>/dev/null || $SUDO pacman -S --needed --noconfirm \
    linux \
    linux-headers \
    amd-ucode \
    linux-firmware 2>/dev/null || true

# 3. Stack Grafico y Aceleracion HW para AMD (Mesa / RADV / VA-API / Vulkan 64-bit)
echo "Instalando controladores graficos AMD Mesa (RADV/RadeonSI) y aceleracion de hardware..."
$SUDO pacman -S --needed --noconfirm \
    mesa \
    libva-mesa-driver \
    vulkan-radeon \
    vulkan-tools \
    libva-utils \
    radeontop \
    mesa-utils 2>/dev/null || true

# 4. Codecs Multimedia y FFmpeg completo
echo "Instalando FFmpeg completo y codecs multimedia..."
$SUDO pacman -S --needed --noconfirm \
    ffmpeg \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav 2>/dev/null || true

# 5. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "Verificando y habilitando PipeWire y WirePlumber..."
$SUDO pacman -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber 2>/dev/null || true

run_as_user systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 6. Software Esencial de Sistema e Integracion Niri + Noctalia Shell (Wayland)
echo "Instalando utilidades esenciales y stack Wayland (Niri, Portales, Herramientas)..."
$SUDO pacman -S --needed --noconfirm \
    base-devel \
    cmake \
    curl \
    btop \
    htop \
    inxi \
    fuse2 \
    fuse3 \
    exfatprogs \
    vlc \
    mpv \
    gimp \
    gparted \
    7zip \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz \
    fastfetch \
    ca-certificates \
    gnupg \
    niri \
    xwayland-satellite \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    wl-clipboard \
    grim \
    slurp \
    satty \
    brightnessctl \
    playerctl \
    pavucontrol \
    blueman \
    network-manager-applet \
    polkit-gnome \
    papirus-icon-theme \
    adwaita-icon-theme \
    qt5-wayland \
    qt6-wayland \
    qt6ct \
    kvantum 2>/dev/null || true

# Instalar Noctalia Shell si está disponible en repositorios
if ! command -v noctalia &>/dev/null; then
    $SUDO pacman -S --needed --noconfirm noctalia-shell 2>/dev/null || \
    $SUDO pacman -S --needed --noconfirm noctalia 2>/dev/null || true
fi

# 7. Limpieza de Paquetes Antiguos
echo "Limpiando cache y paquetes obsoletos..."
$SUDO pacman -Sc --noconfirm || true

echo "================================================================="
echo "CachyOS (AMD Ryzen) configurado con exito."
echo "Se recomienda reiniciar el equipo para arrancar con el nuevo Kernel y drivers AMD."
echo "================================================================="
