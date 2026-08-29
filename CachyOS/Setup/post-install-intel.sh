#!/bin/bash
# post-install-intel.sh - Script de post-instalacion para CachyOS con Intel Core y Intel Graphics
# (Configurado con ZRAM, Pacman optimizado, Microcodigo Intel, VA-API Intel, PipeWire)

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACION: CACHYOS (ARCH LINUX) - INTEL CORE"
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

# 1. Optimizacion de Pacman (Paralelismo de descargas)
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

# Optimizar espejos si esta disponible
if command -v cachyos-rate-mirrors &> /dev/null; then
    echo "Optimizando espejos con cachyos-rate-mirrors..."
    $SUDO cachyos-rate-mirrors || true
fi

# Actualizar sistema
echo "Actualizando base del sistema..."
$SUDO pacman -Syu --noconfirm

# 2. Habilitar repositorios multilib y Chaotic-AUR
echo "Habilitando repositorio multilib..."
if ! grep -q "^\[multilib\]" "$PACMAN_CONF"; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | $SUDO tee -a "$PACMAN_CONF" > /dev/null
fi

echo "Configurando e integrando repositorio Chaotic-AUR..."
if ! grep -q "^\[chaotic-aur\]" "$PACMAN_CONF"; then
    $SUDO pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null || true
    $SUDO pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true
    $SUDO pacman -U --needed --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null || true
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | $SUDO tee -a "$PACMAN_CONF" > /dev/null
    $SUDO pacman -Sy --noconfirm || true
    echo "✅ Repositorio Chaotic-AUR configurado correctamente."
else
    echo "✅ Repositorio Chaotic-AUR ya está presente en $PACMAN_CONF."
fi

# 3. Compresion de Memoria ZRAM
echo "Configurando ZRAM con algoritmo ZSTD al 50% de RAM..."
$SUDO pacman -S --needed --noconfirm zram-generator 2>/dev/null || true
$SUDO tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF
$SUDO systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

# 4. Kernel Linux, Firmware y Microcodigo para Intel
echo "Instalando Kernel Linux, Firmware oficial y Microcodigo para Intel..."
$SUDO pacman -S --needed --noconfirm \
    linux-cachyos \
    linux-cachyos-headers \
    intel-ucode \
    linux-firmware 2>/dev/null || $SUDO pacman -S --needed --noconfirm \
    linux \
    linux-headers \
    intel-ucode \
    linux-firmware 2>/dev/null || true

# 5. Stack Grafico y Aceleracion HW para Intel (Mesa / VA-API Intel)
echo "Instalando controladores graficos Intel y aceleracion de hardware..."
$SUDO pacman -S --needed --noconfirm \
    mesa \
    libva-intel-driver \
    intel-media-driver \
    vulkan-intel \
    vulkan-tools \
    libva-utils \
    mesa-utils 2>/dev/null || true

# Vulkan 32-bit (solo para Wine/Proton gaming)
if command -v wine &>/dev/null || command -v proton &>/dev/null; then
    echo "Wine/Proton detectado. Instalando drivers Vulkan 32-bit..."
    $SUDO pacman -S --needed --noconfirm lib32-vulkan-intel lib32-mesa lib32-intel-media-driver 2>/dev/null || true
fi

# 6. Codecs Multimedia y FFmpeg completo
echo "Instalando FFmpeg completo y codecs multimedia..."
$SUDO pacman -S --needed --noconfirm \
    ffmpeg \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav 2>/dev/null || true

# 7. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "Verificando y habilitando PipeWire y WirePlumber..."
$SUDO pacman -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber 2>/dev/null || true

run_as_user systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 8. Software Esencial de Sistema e Integracion KDE Plasma 6
echo "Instalando utilidades esenciales y plugins de KDE Plasma 6 (Dolphin Thumbnails, KIO, Portales)..."
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
    ffmpegthumbs \
    kdegraphics-thumbnailers \
    kimageformats \
    qt6-imageformats \
    taglib \
    poppler \
    breeze-icons \
    adwaita-icon-theme \
    kde-gtk-config \
    breeze-gtk \
    qt5-wayland \
    qt6-wayland \
    qqc2-desktop-style \
    qqc2-breeze-style \
    xdg-desktop-portal-kde \
    xdg-desktop-portal-gtk 2>/dev/null || true

# Configurar miniaturas avanzadas en Dolphin
echo "Configurando vistas previas y miniaturas en Dolphin..."
if command -v kwriteconfig6 &>/dev/null; then
    run_as_user kwriteconfig6 --file dolphinrc --group PreviewSettings --key Plugins "audiothumbnail,directorythumbnail,djvuthumbnail,exrthumbnail,ffmpegthumbs,fontthumbnail,imagethumbnail,jpegthumbnail,kraimagethumbnail,svgthumbnail,textthumbnail,windowsexethumbnail" 2>/dev/null || true
else
    DOLPHIN_CONF="$USER_HOME/.config/dolphinrc"
    run_as_user mkdir -p "$(dirname "$DOLPHIN_CONF")"
    if [ -f "$DOLPHIN_CONF" ]; then
        if grep -q "^\[PreviewSettings\]" "$DOLPHIN_CONF" 2>/dev/null; then
            sed -i '/^\[PreviewSettings\]/,/^\[/ s|^Plugins=.*|Plugins=audiothumbnail,directorythumbnail,djvuthumbnail,exrthumbnail,ffmpegthumbs,fontthumbnail,imagethumbnail,jpegthumbnail,kraimagethumbnail,svgthumbnail,textthumbnail,windowsexethumbnail|' "$DOLPHIN_CONF"
        else
            printf "\n[PreviewSettings]\nPlugins=audiothumbnail,directorythumbnail,djvuthumbnail,exrthumbnail,ffmpegthumbs,fontthumbnail,imagethumbnail,jpegthumbnail,kraimagethumbnail,svgthumbnail,textthumbnail,windowsexethumbnail\n" >> "$DOLPHIN_CONF"
        fi
    fi
fi

# 9. Integracion de Flatpak & Flathub
echo "Configurando Flatpak, Flathub e integracion de temas..."
$SUDO pacman -S --needed --noconfirm flatpak 2>/dev/null || true
run_as_user flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# Permitir que las aplicaciones Flatpak respeten los temas GTK del sistema
if command -v flatpak &>/dev/null; then
    run_as_user flatpak override --user --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true
    run_as_user flatpak override --user --filesystem=xdg-config/gtk-4.0:ro 2>/dev/null || true
fi

# 10. Limpieza de Paquetes Antiguos
echo "Limpiando cache y paquetes obsoletos..."
$SUDO pacman -Sc --noconfirm || true

echo "================================================================="
echo "CachyOS (Intel Core) configurado con exito."
echo "Se recomienda reiniciar el equipo para arrancar con el nuevo Kernel, drivers Intel y ZRAM."
echo "================================================================="
