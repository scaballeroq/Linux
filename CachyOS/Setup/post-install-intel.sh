#!/bin/bash
# post-install-intel.sh - Script de post-instalación para CachyOS con Intel Core e Intel Graphics
# Optimizado para GNOME Workstation (Intel Core, Intel UHD/Iris/Arc Graphics)
# Incluye:
#   - Pacman y Makepkg paralelos con compresión zstd multi-hilo
#   - Stack gráfico Mesa + VA-API Intel (intel-media-driver)
#   - Compresión ZRAM con ZSTD al 50% de RAM
#   - Audio PipeWire de alta fidelidad y WirePlumber
#   - Ecosistema nativo GNOME (Nautilus, Sushi, Loupe, Tweaks, Portales GNOME/GTK, Wayland)
#   - Tema oscuro GTK forzado globalmente (prefer-dark, adw-gtk3-dark)
#   - Cero extensiones de GNOME añadidas

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: CACHYOS (ARCH LINUX) - INTEL CORE"
echo "ENTORNO: GNOME WORKSTATION (MODO OSCURO)"
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
if run_as_user command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif run_as_user command -v yay &> /dev/null; then
    AUR_HELPER="yay"
fi

# 1. Optimización de Pacman y Makepkg
echo "⚙️ [1/10] Configurando optimizaciones en Pacman y Makepkg..."
PACMAN_CONF="/etc/pacman.conf"
if [ -f "$PACMAN_CONF" ]; then
    if grep -q "^#ParallelDownloads" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^#ParallelDownloads = .*/ParallelDownloads = 10/' "$PACMAN_CONF"
    elif ! grep -q "^ParallelDownloads" "$PACMAN_CONF"; then
        $SUDO sed -i '/^\[options\]/a ParallelDownloads = 10' "$PACMAN_CONF"
    fi
    if grep -q "^#Color" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^#Color/Color/' "$PACMAN_CONF"
    elif ! grep -q "^Color" "$PACMAN_CONF"; then
        $SUDO sed -i '/^\[options\]/a Color' "$PACMAN_CONF"
    fi
    if ! grep -q "ILoveCandy" "$PACMAN_CONF"; then
        $SUDO sed -i '/^Color/a ILoveCandy' "$PACMAN_CONF" 2>/dev/null || true
    fi
fi

MAKEPKG_CONF="/etc/makepkg.conf"
if [ -f "$MAKEPKG_CONF" ]; then
    if grep -q "^#MAKEFLAGS=" "$MAKEPKG_CONF"; then
        $SUDO sed -i 's/^#MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' "$MAKEPKG_CONF"
    elif grep -q "^MAKEFLAGS=" "$MAKEPKG_CONF"; then
        $SUDO sed -i 's/^MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' "$MAKEPKG_CONF"
    fi
    if grep -q "^COMPRESSZST=" "$MAKEPKG_CONF"; then
        $SUDO sed -i 's/^COMPRESSZST=.*/COMPRESSZST=(zstd -c -z -q --threads=0 -)/' "$MAKEPKG_CONF"
    fi
fi

# Optimizar espejos si está disponible
if command -v cachyos-rate-mirrors &> /dev/null; then
    echo "Optimizando espejos con cachyos-rate-mirrors..."
    $SUDO cachyos-rate-mirrors || true
fi

# Actualizar sistema
echo "🔄 [2/10] Actualizando base del sistema CachyOS..."
$SUDO pacman -Syu --noconfirm

# 2. Habilitar repositorios multilib y Chaotic-AUR
echo "📦 [3/10] Verificando repositorios multilib y Chaotic-AUR..."
if ! grep -q "^\[multilib\]" "$PACMAN_CONF"; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | $SUDO tee -a "$PACMAN_CONF" > /dev/null
fi

if ! grep -q "^\[chaotic-aur\]" "$PACMAN_CONF"; then
    $SUDO pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null || true
    $SUDO pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true
    $SUDO pacman -U --needed --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null || true
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | $SUDO tee -a "$PACMAN_CONF" > /dev/null
    $SUDO pacman -Sy --noconfirm || true
fi

# 3. Compresión de Memoria ZRAM
echo "💾 [4/10] Configurando ZRAM con algoritmo ZSTD al 50% de RAM..."
$SUDO pacman -S --needed --noconfirm zram-generator 2>/dev/null || true
$SUDO tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF
$SUDO systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

# 4. Kernel Linux, Firmware y Microcódigo Intel
echo "🐧 [5/10] Instalando Kernel Linux, Firmware y Microcódigo Intel..."
$SUDO pacman -S --needed --noconfirm \
    linux-cachyos \
    linux-cachyos-headers \
    intel-ucode \
    linux-firmware 2>/dev/null || $SUDO pacman -S --needed --noconfirm \
    linux \
    linux-headers \
    intel-ucode \
    linux-firmware 2>/dev/null || true

# 5. Stack Gráfico y Aceleración HW para Intel
echo "🎮 [6/10] Instalando controladores gráficos Intel Mesa y VA-API..."
$SUDO pacman -S --needed --noconfirm \
    mesa \
    intel-media-driver \
    libva-intel-driver \
    vulkan-intel \
    vulkan-tools \
    libva-utils \
    mesa-utils 2>/dev/null || true

# Vulkan 32-bit para multilib
if grep -q "^\[multilib\]" "$PACMAN_CONF" 2>/dev/null; then
    $SUDO pacman -S --needed --noconfirm \
        lib32-vulkan-intel \
        lib32-mesa 2>/dev/null || true
fi

# 6. Codecs Multimedia y FFmpeg
echo "🎬 [7/10] Instalando FFmpeg completo y codecs multimedia..."
$SUDO pacman -S --needed --noconfirm \
    ffmpeg \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav 2>/dev/null || true

# 7. Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "🔊 [8/10] Verificando y habilitando PipeWire y WirePlumber..."
$SUDO pacman -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber 2>/dev/null || true

run_as_user systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 8. Software Esencial e Integración GNOME (Sin extensiones)
echo "🎨 [9/10] Instalando utilidades esenciales del sistema e integración GNOME..."
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
    gnome-tweaks \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    adw-gtk-theme \
    adwaita-icon-theme \
    nautilus \
    sushi \
    loupe \
    file-roller \
    ffmpegthumbnailer \
    gnome-disk-utility \
    baobab \
    seahorse \
    brightnessctl \
    wl-clipboard \
    grim \
    slurp \
    satty \
    qt5-wayland \
    qt6-wayland \
    kvantum 2>/dev/null || true

# 9. Forzar Tema Oscuro Global
echo "🌙 [10/10] Aplicando configuración de tema oscuro global (prefer-dark / adw-gtk3-dark)..."

run_as_user dconf write /org/gnome/desktop/interface/color-scheme '"prefer-dark"' 2>/dev/null || \
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

run_as_user dconf write /org/gnome/desktop/interface/gtk-theme '"adw-gtk3-dark"' 2>/dev/null || \
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || \
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true

# Asegurar que no exista GTK_THEME en environment.d (rompe el modo oscuro en apps GTK4 como Shelly)
run_as_user rm -f "$USER_HOME/.config/environment.d/10-gtk-dark.conf"

run_as_user mkdir -p "$USER_HOME/.config/gtk-3.0"
cat << 'EOF' | run_as_user tee "$USER_HOME/.config/gtk-3.0/settings.ini" > /dev/null
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-application-prefer-dark-theme=1
EOF

run_as_user mkdir -p "$USER_HOME/.config/gtk-4.0"
cat << 'EOF' | run_as_user tee "$USER_HOME/.config/gtk-4.0/settings.ini" > /dev/null
[Settings]
gtk-application-prefer-dark-theme=1
EOF

# Integración Flatpak
if command -v flatpak &>/dev/null; then
    run_as_user flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    run_as_user flatpak override --user --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true
    run_as_user flatpak override --user --filesystem=xdg-config/gtk-4.0:ro 2>/dev/null || true
fi

$SUDO systemctl enable --now fstrim.timer 2>/dev/null || true

if command -v paccache &>/dev/null; then
    paccache -r 2>/dev/null || true
else
    $SUDO pacman -Sc --noconfirm || true
fi

echo "================================================================="
echo "✅ CachyOS (Intel Core + GNOME) configurado con éxito."
echo "   - Pila de GNOME completa (Tweaks, Nautilus, Sushi, Portales Wayland)."
echo "   - Tema oscuro GTK forzado globalmente."
echo "   - Cero extensiones de GNOME instaladas."
echo "💡 Se recomienda reiniciar el equipo para aplicar cambios de kernel."
echo "================================================================="
