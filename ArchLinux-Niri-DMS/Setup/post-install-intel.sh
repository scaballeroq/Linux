#!/bin/bash
# post-install-intel.sh - Script de post-instalación para Arch Linux con Intel Core y Intel Graphics
# (Configurado con Pacman optimizado, Microcódigo Intel, VA-API Intel, PipeWire, Niri + Dank Material Shell)

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: ARCH LINUX - INTEL CORE (NIRI + DMS)"
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
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
if run_as_user command -v yay &> /dev/null; then
    AUR_HELPER="yay"
elif run_as_user command -v paru &> /dev/null; then
    AUR_HELPER="paru"
fi

# 1. Optimización de Pacman (Paralelismo de descargas, colores y Candy)
echo "⚙️ [1/8] Configurando optimizaciones en Pacman..."
PACMAN_CONF="/etc/pacman.conf"
if [ -f "$PACMAN_CONF" ]; then
    if ! grep -q "^ParallelDownloads" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^#ParallelDownloads = .*/ParallelDownloads = 10/' "$PACMAN_CONF" 2>/dev/null || \
        $SUDO sed -i '/^\[options\]/a ParallelDownloads = 10' "$PACMAN_CONF"
    fi
    if ! grep -q "^Color" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^#Color/Color/' "$PACMAN_CONF" 2>/dev/null || \
        $SUDO sed -i '/^\[options\]/a Color' "$PACMAN_CONF"
    fi
    if ! grep -q "ILoveCandy" "$PACMAN_CONF"; then
        $SUDO sed -i '/^Color/a ILoveCandy' "$PACMAN_CONF" 2>/dev/null || true
    fi
fi

# Actualizar base del sistema
echo "🔄 [2/8] Actualizando base del sistema Arch Linux..."
$SUDO pacman -Syu --noconfirm

# 2. Kernel Linux, Firmware y Microcódigo para Intel
echo "🐧 [3/8] Instalando Kernel Linux oficial, Firmware y Microcódigo Intel..."
$SUDO pacman -S --needed --noconfirm \
    linux \
    linux-headers \
    intel-ucode \
    linux-firmware

# 3. Stack Gráfico y Aceleración HW para Intel (Mesa / VA-API Intel / Vulkan 64-bit)
echo "🎮 [4/8] Instalando controladores gráficos Intel y aceleración HW..."
$SUDO pacman -S --needed --noconfirm \
    mesa \
    intel-media-driver \
    libva-intel-driver \
    vulkan-intel \
    vulkan-tools \
    libva-utils \
    mesa-utils 2>/dev/null || true

# 4. Códecs Multimedia y FFmpeg completo
echo "🎬 [5/8] Instalando FFmpeg y códecs multimedia globales..."
$SUDO pacman -S --needed --noconfirm \
    ffmpeg \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav \
    alsa-plugins \
    flac \
    lame \
    libvorbis \
    opus \
    x264 \
    x265 2>/dev/null || true

# 5. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "🔊 [6/8] Verificando y habilitando PipeWire y WirePlumber..."
$SUDO pacman -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber 2>/dev/null || true

run_as_user systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 6. Software Esencial de Sistema, Herramientas y Stack Wayland
echo "📦 [7/8] Instalando utilidades de sistema, Niri Compositor y entorno Wayland..."
$SUDO pacman -S --needed --noconfirm \
    base-devel \
    cmake \
    curl \
    wget \
    git \
    btop \
    htop \
    inxi \
    fuse2 \
    fuse3 \
    sshfs \
    dosfstools \
    mtools \
    exfatprogs \
    ntfs-3g \
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
    inter-font \
    papirus-icon-theme \
    adwaita-icon-theme \
    qt5-wayland \
    qt6-wayland \
    qt6ct \
    kvantum 2>/dev/null || true

# 7. Dank Material Shell (DMS) y utilidades complementarias
echo "🌌 [8/8] Verificando componentes de Dank Material Shell (DMS)..."

# Instalar matugen y dependencias DMS si están disponibles
if ! command -v matugen &>/dev/null; then
    $SUDO pacman -S --needed --noconfirm matugen 2>/dev/null || true
fi

# Si se dispone de AUR helper y falta dms-shell, dankcalendar o danksearch
if [ -n "$AUR_HELPER" ]; then
    if ! command -v dms &>/dev/null; then
        echo "ℹ️ Instalando Dank Material Shell (dms-shell) vía $AUR_HELPER..."
        run_as_user "$AUR_HELPER" -S --needed --noconfirm dms-shell 2>/dev/null || true
    fi
    if ! command -v dcal &>/dev/null; then
        echo "ℹ️ Instalando dankcalendar vía $AUR_HELPER..."
        run_as_user "$AUR_HELPER" -S --needed --noconfirm dankcalendar-bin 2>/dev/null || true
    fi
    if ! command -v danksearch &>/dev/null; then
        echo "ℹ️ Instalando danksearch vía $AUR_HELPER..."
        run_as_user "$AUR_HELPER" -S --needed --noconfirm danksearch 2>/dev/null || true
    fi
    run_as_user "$AUR_HELPER" -S --needed --noconfirm cava kimageformats 2>/dev/null || true
fi

# Habilitar dms.service a nivel de usuario si está presente
if run_as_user systemctl --user list-unit-files dms.service &>/dev/null; then
    run_as_user systemctl --user enable --now dms.service 2>/dev/null || true
    echo "  ✅ Servicio dms.service habilitado para el usuario $REAL_USER."
fi

# 8. Limpieza de Paquetes Antiguos
echo "🧹 Limpiando caché y paquetes obsoletos..."
$SUDO pacman -Sc --noconfirm || true

echo "================================================================="
echo "✅ Arch Linux (Intel Core + Niri + Dank Material Shell) configurado con éxito."
echo "💡 Se recomienda reiniciar el equipo para arrancar con el nuevo Kernel y drivers Intel."
echo "================================================================="
