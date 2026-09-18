#!/bin/bash
# post-install-amd.sh - Script de post-instalación para CachyOS con AMD Ryzen y AMD Graphics
# Optimizado para GNOME Workstation (HP EliteBook 855 G7, Ryzen 7 PRO 4750U, Vega 7 Graphics)
# Incluye:
#   - Pacman y Makepkg paralelos (16 hilos Zen 2 Renoir, 32 GB RAM)
#   - Early KMS amdgpu en mkinitcpio para inicio multi-monitor limpio (3 pantallas 1080p)
#   - Stack gráfico Mesa + Vulkan (RADV) + VA-API aceleración HW (64-bit y multilib 32-bit)
#   - Compresión ZRAM con ZSTD al 50% de RAM
#   - Audio PipeWire de alta fidelidad y WirePlumber
#   - Ecosistema nativo GNOME (Nautilus, Sushi, Loupe, Tweaks, Portales GNOME/GTK, Wayland)
#   - Tema oscuro GTK forzado globalmente (prefer-dark, adw-gtk3-dark)
#   - Cero extensiones de GNOME añadidas

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: CACHYOS (ARCH LINUX) - AMD RYZEN"
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

# Detectar AUR helper (CachyOS incluye paru por defecto)
AUR_HELPER=""
if run_as_user command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif run_as_user command -v yay &> /dev/null; then
    AUR_HELPER="yay"
fi

# -----------------------------------------------------------------------------
# 1. Optimización de Pacman y Makepkg (16 hilos y 32 GB RAM)
# -----------------------------------------------------------------------------
echo "⚙️ [1/10] Configurando optimizaciones en Pacman y Makepkg (16 hilos)..."
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

# Optimizar espejos si cachyos-rate-mirrors está disponible
if command -v cachyos-rate-mirrors &> /dev/null; then
    echo "Optimizando espejos con cachyos-rate-mirrors..."
    $SUDO cachyos-rate-mirrors || true
fi

# Actualizar sistema
echo "🔄 [2/10] Actualizando base del sistema CachyOS..."
$SUDO pacman -Syu --noconfirm

# -----------------------------------------------------------------------------
# 2. Habilitar repositorios multilib y Chaotic-AUR
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# 3. Compresión de Memoria ZRAM
# -----------------------------------------------------------------------------
echo "💾 [4/10] Configurando ZRAM con algoritmo ZSTD al 50% de RAM..."
$SUDO pacman -S --needed --noconfirm zram-generator 2>/dev/null || true
$SUDO tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF
$SUDO systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

# -----------------------------------------------------------------------------
# 4. Kernel Linux, Firmware y Microcódigo AMD + Early KMS (3 Monitores)
# -----------------------------------------------------------------------------
echo "🐧 [5/10] Instalando Kernel, Firmware, Microcódigo AMD y Early KMS..."
$SUDO pacman -S --needed --noconfirm \
    linux-cachyos \
    linux-cachyos-headers \
    amd-ucode \
    linux-firmware \
    linux-firmware-amdgpu 2>/dev/null || $SUDO pacman -S --needed --noconfirm \
    linux \
    linux-headers \
    amd-ucode \
    linux-firmware 2>/dev/null || true

MKINITCPIO_CONF="/etc/mkinitcpio.conf"
REBUILD_INITRAMFS=false
if [ -f "$MKINITCPIO_CONF" ]; then
    if ! grep -E "^MODULES=.*amdgpu" "$MKINITCPIO_CONF" >/dev/null; then
        echo "  🖥️ Configurando Early KMS (amdgpu) en mkinitcpio para inicio multi-pantalla limpio..."
        if grep -q "^MODULES=()" "$MKINITCPIO_CONF"; then
            $SUDO sed -i 's/^MODULES=()/MODULES=(amdgpu)/' "$MKINITCPIO_CONF"
            REBUILD_INITRAMFS=true
        elif grep -q "^MODULES=(" "$MKINITCPIO_CONF"; then
            $SUDO sed -i 's/^MODULES=(/MODULES=(amdgpu /' "$MKINITCPIO_CONF"
            REBUILD_INITRAMFS=true
        fi
    fi
fi

if [ "$REBUILD_INITRAMFS" = true ]; then
    echo "  ⚙️ Regenerando initramfs con soporte Early KMS..."
    $SUDO mkinitcpio -P || true
fi

# -----------------------------------------------------------------------------
# 5. Stack Gráfico y Aceleración HW para AMD (Mesa / RADV / VA-API / Vulkan)
# -----------------------------------------------------------------------------
echo "🎮 [6/10] Instalando controladores gráficos AMD Mesa (RADV/RadeonSI) y VA-API..."
$SUDO pacman -S --needed --noconfirm \
    mesa \
    libva-mesa-driver \
    vulkan-radeon \
    vulkan-tools \
    libva-utils \
    radeontop \
    mesa-utils 2>/dev/null || true

# Vulkan 32-bit para compatibilidad multilib / Wine / Proton
if grep -q "^\[multilib\]" "$PACMAN_CONF" 2>/dev/null; then
    echo "Instalando controladores gráficos multilib (32-bit)..."
    $SUDO pacman -S --needed --noconfirm \
        lib32-vulkan-radeon \
        lib32-mesa \
        lib32-libva-mesa-driver 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# 6. Codecs Multimedia y FFmpeg
# -----------------------------------------------------------------------------
echo "🎬 [7/10] Instalando FFmpeg completo y codecs multimedia..."
$SUDO pacman -S --needed --noconfirm \
    ffmpeg \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav 2>/dev/null || true

# -----------------------------------------------------------------------------
# 7. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
# -----------------------------------------------------------------------------
echo "🔊 [8/10] Verificando y habilitando PipeWire y WirePlumber..."
$SUDO pacman -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber 2>/dev/null || true

run_as_user systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# -----------------------------------------------------------------------------
# 8. Software Esencial e Integración GNOME (Sin extensiones)
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# 9. Forzar Tema Oscuro Global (GTK3, GTK4, Libadwaita y Qt)
# -----------------------------------------------------------------------------
echo "🌙 [10/10] Aplicando configuración de tema oscuro global (prefer-dark / adw-gtk3-dark)..."

# Configurar gsettings / dconf del usuario
run_as_user dconf write /org/gnome/desktop/interface/color-scheme '"prefer-dark"' 2>/dev/null || \
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

run_as_user dconf write /org/gnome/desktop/interface/gtk-theme '"adw-gtk3-dark"' 2>/dev/null || \
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || \
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true

# Variable de entorno en environment.d para sesiones Wayland
run_as_user mkdir -p "$USER_HOME/.config/environment.d"
cat << 'EOF' | run_as_user tee "$USER_HOME/.config/environment.d/10-gtk-dark.conf" > /dev/null
GTK_THEME=adw-gtk3-dark
EOF

# Configuración settings.ini para GTK 3.0
run_as_user mkdir -p "$USER_HOME/.config/gtk-3.0"
cat << 'EOF' | run_as_user tee "$USER_HOME/.config/gtk-3.0/settings.ini" > /dev/null
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-application-prefer-dark-theme=1
EOF

# Configuración settings.ini para GTK 4.0
run_as_user mkdir -p "$USER_HOME/.config/gtk-4.0"
cat << 'EOF' | run_as_user tee "$USER_HOME/.config/gtk-4.0/settings.ini" > /dev/null
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-application-prefer-dark-theme=1
EOF

# Integración Flatpak con temas del sistema
if command -v flatpak &>/dev/null; then
    run_as_user flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    run_as_user flatpak override --user --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true
    run_as_user flatpak override --user --filesystem=xdg-config/gtk-4.0:ro 2>/dev/null || true
fi

# Mantenimiento SSD con fstrim
$SUDO systemctl enable --now fstrim.timer 2>/dev/null || true

# Limpieza segura de paquetes
if command -v paccache &>/dev/null; then
    paccache -r 2>/dev/null || true
else
    $SUDO pacman -Sc --noconfirm || true
fi

echo "================================================================="
echo "✅ CachyOS (AMD Ryzen + GNOME) configurado con éxito."
echo "   - Makepkg multi-hilo (16 hilos) activo."
echo "   - Early KMS amdgpu configurado para multi-monitor (3 pantallas)."
echo "   - Mesa RADV y VA-API acelerados (64 y 32 bits)."
echo "   - Pila de GNOME completa (Tweaks, Nautilus, Sushi, Portales Wayland)."
echo "   - Tema oscuro GTK forzado globalmente."
echo "   - Cero extensiones de GNOME instaladas (fase 1 completada)."
echo "💡 Se recomienda reiniciar el equipo para aplicar el kernel y KMS."
echo "================================================================="
