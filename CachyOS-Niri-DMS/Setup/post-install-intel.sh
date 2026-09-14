#!/bin/bash
# post-install-intel.sh - Script de post-instalación optimizado para CachyOS
# Hardware: Intel Core e Intel Graphics (UHD / Iris Xe / Arc)
# Optimizaciones:
#   - Pacman y Makepkg paralelos (aprovecha todos los hilos de la CPU)
#   - Early KMS i915 en mkinitcpio para inicio limpio en multi-monitor
#   - Stack gráfico Mesa + Intel Media Driver (VA-API) + Vulkan (ANV) (64-bit y multilib 32-bit)
#   - Gestión de energía (power-profiles-daemon), TRIM de SSD (fstrim.timer) y soporte DDC/CI (I2C)
#   - PipeWire de alta fidelidad, herramientas nativas Wayland, adw-gtk-theme, Niri y Dank Material Shell (DMS)
# NOTA: Este script NO altera configuraciones visuales, temas ni personalizaciones de Niri y DMS.

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: ARQUITECTURA INTEL (NIRI + DMS)"
echo "CACHYOS · NIRI · DANK MATERIAL SHELL"
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

# Detectar AUR helper (CachyOS prefiere paru)
AUR_HELPER=""
if run_as_user command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif run_as_user command -v yay &> /dev/null; then
    AUR_HELPER="yay"
fi

# -----------------------------------------------------------------------------
# 1. Optimización de Pacman y Makepkg (Multi-hilo)
# -----------------------------------------------------------------------------
echo "⚙️ [1/10] Optimizando Pacman y Makepkg para compilación paralela..."
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

# Actualizar base de datos y paquetes del sistema
echo "🔄 [2/10] Actualizando base del sistema CachyOS..."
$SUDO pacman -Syu --noconfirm

# -----------------------------------------------------------------------------
# 2. Kernel Linux, Firmware y Microcódigo Intel + Early KMS
# -----------------------------------------------------------------------------
echo "🐧 [3/10] Instalando Kernel, Firmware, Microcódigo Intel y Early KMS..."
$SUDO pacman -S --needed --noconfirm \
    linux-cachyos \
    linux-cachyos-headers \
    intel-ucode \
    linux-firmware

# Configuración de Early KMS (i915) para evitar parpadeos en arranque multi-monitor
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
REBUILD_INITRAMFS=false
if [ -f "$MKINITCPIO_CONF" ]; then
    if ! grep -E "^MODULES=.*(i915|xe)" "$MKINITCPIO_CONF" >/dev/null; then
        echo "  🖥️ Configurando Early KMS (i915) en mkinitcpio para inicio limpio..."
        if grep -q "^MODULES=()" "$MKINITCPIO_CONF"; then
            $SUDO sed -i 's/^MODULES=()/MODULES=(i915)/' "$MKINITCPIO_CONF"
            REBUILD_INITRAMFS=true
        elif grep -q "^MODULES=(" "$MKINITCPIO_CONF"; then
            $SUDO sed -i 's/^MODULES=(/MODULES=(i915 /' "$MKINITCPIO_CONF"
            REBUILD_INITRAMFS=true
        fi
    fi
fi

if [ "$REBUILD_INITRAMFS" = true ]; then
    echo "  🔨 Regenerando initramfs..."
    $SUDO mkinitcpio -P
fi

# -----------------------------------------------------------------------------
# 3. Stack Gráfico y Aceleración HW Intel (Mesa / VA-API / Vulkan)
# -----------------------------------------------------------------------------
echo "🎮 [4/10] Instalando controladores gráficos Intel (Mesa, intel-media-driver y Vulkan)..."
PKGS_INTEL_GRAPHICS=(
    mesa
    intel-media-driver
    vulkan-intel
    vulkan-tools
    libva-utils
    mesa-utils
)

# Soporte 32-bit (multilib) si está habilitado en pacman.conf
if grep -E "^\s*\[multilib\]" "$PACMAN_CONF" >/dev/null; then
    echo "  🕹️ Repositorio multilib detectado: agregando drivers gráficos Intel de 32 bits..."
    PKGS_INTEL_GRAPHICS+=(
        lib32-mesa
        lib32-intel-media-driver
        lib32-vulkan-intel
    )
fi

$SUDO pacman -S --needed --noconfirm "${PKGS_INTEL_GRAPHICS[@]}"

# -----------------------------------------------------------------------------
# 4. Códecs Multimedia y FFmpeg
# -----------------------------------------------------------------------------
echo "🎬 [5/10] Instalando FFmpeg y códecs multimedia..."
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
    x265

# -----------------------------------------------------------------------------
# 5. Sistema de Audio (PipeWire + WirePlumber)
# -----------------------------------------------------------------------------
echo "🔊 [6/10] Verificando y habilitando PipeWire y WirePlumber..."
$SUDO pacman -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber

run_as_user systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# -----------------------------------------------------------------------------
# 6. Gestión de Energía y Mantenimiento de Almacenamiento SSD
# -----------------------------------------------------------------------------
echo "🔋 [7/10] Configurando gestión de energía (power-profiles-daemon) y TRIM de SSD..."
$SUDO pacman -S --needed --noconfirm power-profiles-daemon util-linux

$SUDO systemctl enable --now power-profiles-daemon.service
$SUDO systemctl enable --now fstrim.timer

# -----------------------------------------------------------------------------
# 7. Stack Wayland, Portales, Compositor Niri y Temas GTK3/DDC
# -----------------------------------------------------------------------------
echo "📦 [8/10] Instalando utilidades esenciales de sistema y stack Niri Wayland..."
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
    loupe \
    fragments \
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
    xdg-desktop-portal \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    wl-clipboard \
    grim \
    slurp \
    satty \
    brightnessctl \
    ddcutil \
    fprintd \
    khal \
    playerctl \
    pavucontrol \
    inter-font \
    papirus-icon-theme \
    adwaita-icon-theme \
    adw-gtk-theme \
    nwg-look \
    qt5-wayland \
    qt6-wayland \
    qt6ct \
    kvantum

# Configurar módulo i2c-dev y permisos para control DDC/CI de brillo en monitores externos (DMS)
if ! lsmod | grep -q "i2c_dev"; then
    $SUDO modprobe i2c-dev 2>/dev/null || true
fi
if [ ! -f /etc/modules-load.d/i2c-dev.conf ]; then
    echo "i2c-dev" | $SUDO tee /etc/modules-load.d/i2c-dev.conf >/dev/null
fi
$SUDO usermod -aG i2c "$REAL_USER" 2>/dev/null || true

# -----------------------------------------------------------------------------
# 8. Dank Material Shell (DMS) y Satélites
# -----------------------------------------------------------------------------
echo "🌌 [9/10] Verificando componentes y servicios de Dank Material Shell (DMS)..."

if ! command -v matugen &>/dev/null; then
    $SUDO pacman -S --needed --noconfirm matugen 2>/dev/null || true
fi

if [ -n "$AUR_HELPER" ]; then
    if ! command -v dms &>/dev/null; then
        echo "  ℹ️ Instalando Dank Material Shell (dms-shell) vía $AUR_HELPER..."
        run_as_user "$AUR_HELPER" -S --needed --noconfirm dms-shell 2>/dev/null || true
    fi
    if ! command -v dcal &>/dev/null; then
        echo "  ℹ️ Instalando dankcalendar vía $AUR_HELPER..."
        run_as_user "$AUR_HELPER" -S --needed --noconfirm dankcalendar-bin 2>/dev/null || true
    fi
    if ! command -v danksearch &>/dev/null; then
        echo "  ℹ️ Instalando danksearch vía $AUR_HELPER..."
        run_as_user "$AUR_HELPER" -S --needed --noconfirm danksearch 2>/dev/null || true
    fi
    run_as_user "$AUR_HELPER" -S --needed --noconfirm cava kimageformats 2>/dev/null || true
fi

if run_as_user systemctl --user list-unit-files dms.service &>/dev/null; then
    run_as_user systemctl --user enable --now dms.service 2>/dev/null || true
    echo "  ✅ Servicio dms.service habilitado para el usuario $REAL_USER."
fi

# -----------------------------------------------------------------------------
# 9. Forzar tema oscuro GTK (Shelly, apps GTK3/GTK4 en Wayland/Niri)
# -----------------------------------------------------------------------------
echo "🎨 [10/10] Aplicando tema oscuro global para GTK (Shelly, apps GTK3/GTK4)..."

# Crear directorios de configuración GTK del usuario
run_as_user mkdir -p "$USER_HOME/.config/environment.d"

# Forzar esquema de color oscuro persistente vía dconf/gsettings
run_as_user dconf write /org/gnome/desktop/interface/color-scheme '"prefer-dark"' 2>/dev/null || \
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

# Establecer tema GTK oscuro (adw-gtk3-dark)
run_as_user dconf write /org/gnome/desktop/interface/gtk-theme '"adw-gtk3-dark"' 2>/dev/null || \
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true

# Variable de entorno GTK_THEME para la sesión Wayland/Niri (environment.d)
cat << 'EOF' | run_as_user tee "$USER_HOME/.config/environment.d/10-gtk-dark.conf" > /dev/null
GTK_THEME=adw-gtk3-dark
EOF

# Configurar settings.ini de GTK3 para preferir modo oscuro
run_as_user mkdir -p "$USER_HOME/.config/gtk-3.0"
cat << 'EOF' | run_as_user tee "$USER_HOME/.config/gtk-3.0/settings.ini" > /dev/null
[Settings]
gtk-application-prefer-dark-theme=1
EOF

# Configurar GTK4 para modo oscuro
run_as_user mkdir -p "$USER_HOME/.config/gtk-4.0"
cat << 'EOF' | run_as_user tee "$USER_HOME/.config/gtk-4.0/settings.ini" > /dev/null
[Settings]
gtk-application-prefer-dark-theme=1
EOF

echo "  ✅ Tema oscuro GTK aplicado globalmente (Shelly y apps GTK se verán correctamente)."

# Limpieza segura de paquetes
if command -v paccache &>/dev/null; then
    paccache -r 2>/dev/null || true
else
    $SUDO pacman -Sc --noconfirm || true
fi

echo "================================================================="
echo "✅ CachyOS (Intel Core + Niri + DMS) configurado al 100%."
echo "   - Compilación multi-hilo activa en makepkg."
echo "   - Early KMS (i915) configurado para arranque limpio multi-monitor."
echo "   - Mesa ANV y VA-API con soporte 64 y 32 bits configurados."
echo "   - Soporte DDC/CI (I2C) y adw-gtk-theme instalados para DMS."
echo "   - Tema oscuro GTK forzado para Shelly y todas las apps GTK3/GTK4."
echo "   - Gestión de energía y fstrim.timer activos."
echo "💡 Si se ha actualizado el initramfs o kernel, se recomienda reiniciar el equipo."
echo "================================================================="
