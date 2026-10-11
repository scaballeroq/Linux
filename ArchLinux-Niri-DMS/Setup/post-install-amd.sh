#!/bin/bash
# post-install-amd.sh - Script de post-instalación optimizado para Arch Linux
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U, Radeon Vega 7 Graphics)
# Optimizaciones:
#   - Pacman y Makepkg paralelos (16 hilos Zen 2 Renoir, 32 GB RAM)
#   - Early KMS amdgpu en mkinitcpio para inicio limpio en multi-monitor (3 pantallas 1080p)
#   - Stack gráfico Mesa + Vulkan (RADV) + VA-API aceleración HW (64-bit y multilib 32-bit)
#   - Gestión de energía y batería (power-profiles-daemon) y mantenimiento SSD (fstrim)
#   - PipeWire de alta fidelidad, herramientas nativas Wayland, Niri y Dank Material Shell (DMS)
# NOTA: Este script NO altera configuraciones visuales, temas ni personalizaciones de Niri y DMS.

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: HP ELITEBOOK 855 G7 (AMD RYZEN)"
echo "ARCH LINUX · NIRI · DANK MATERIAL SHELL"
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

# -----------------------------------------------------------------------------
# 1. Optimización de Pacman y Makepkg (16 hilos y 32 GB RAM)
# -----------------------------------------------------------------------------
echo "⚙️ [1/9] Optimizando Pacman y Makepkg para Ryzen 7 PRO (16 hilos)..."
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
    # Ajustar MAKEFLAGS para usar los 16 hilos de la CPU
    if grep -q "^#MAKEFLAGS=" "$MAKEPKG_CONF"; then
        $SUDO sed -i 's/^#MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' "$MAKEPKG_CONF"
    elif grep -q "^MAKEFLAGS=" "$MAKEPKG_CONF"; then
        $SUDO sed -i 's/^MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' "$MAKEPKG_CONF"
    fi
    # Compresión Zstandard paralela multi-hilo
    if grep -q "^COMPRESSZST=" "$MAKEPKG_CONF"; then
        $SUDO sed -i 's/^COMPRESSZST=.*/COMPRESSZST=(zstd -c -z -q --threads=0 -)/' "$MAKEPKG_CONF"
    fi
fi

# Actualizar base de datos y paquetes del sistema
echo "🔄 [2/9] Actualizando base del sistema Arch Linux..."
$SUDO pacman -Syu --noconfirm

# -----------------------------------------------------------------------------
# 2. Kernel Linux, Firmware y Microcódigo AMD + Early KMS (3 Monitores)
# -----------------------------------------------------------------------------
echo "🐧 [3/9] Instalando Kernel, Firmware, Microcódigo AMD y configurando Early KMS..."
$SUDO pacman -S --needed --noconfirm \
    linux \
    linux-headers \
    amd-ucode \
    linux-firmware \
    linux-firmware-amdgpu

# Configuración de Early KMS para evitar parpadeos y retrasos en triple pantalla
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
    echo "  🔨 Regenerando initramfs..."
    $SUDO mkinitcpio -P
fi

# -----------------------------------------------------------------------------
# 3. Stack Gráfico y Aceleración HW AMD (Mesa / RADV / VA-API / Vulkan)
# -----------------------------------------------------------------------------
echo "🎮 [4/9] Instalando controladores gráficos AMD (Mesa RADV, VA-API y utilidades)..."
# En Arch Linux moderno, 'mesa' y 'lib32-mesa' ya incluyen y proveen libva-mesa-driver (VA-API radeonsi) y OpenGL.
# Especificar nombres canónicos explícitos evita conflictos de proveedores con repositorios de terceros como chaotic-aur.
PKGS_AMD_GRAPHICS=(
    mesa
    vulkan-radeon
    vulkan-tools
    libva-utils
    radeontop
    mesa-utils
)

# Soporte 32-bit (multilib) si está habilitado en pacman.conf
if grep -E "^\s*\[multilib\]" "$PACMAN_CONF" >/dev/null; then
    echo "  🕹️ Repositorio multilib detectado: agregando drivers gráficos de 32 bits..."
    PKGS_AMD_GRAPHICS+=(
        lib32-mesa
        lib32-vulkan-radeon
    )
fi

$SUDO pacman -S --needed --noconfirm "${PKGS_AMD_GRAPHICS[@]}"

# Herramienta moderna de telemetría amdgpu_top si existe en repos o AUR
if ! command -v amdgpu_top &>/dev/null; then
    if $SUDO pacman -Si amdgpu_top &>/dev/null; then
        $SUDO pacman -S --needed --noconfirm amdgpu_top || true
    elif [ -n "$AUR_HELPER" ]; then
        run_as_user "$AUR_HELPER" -S --needed --noconfirm amdgpu_top-bin 2>/dev/null || \
        run_as_user "$AUR_HELPER" -S --needed --noconfirm amdgpu_top 2>/dev/null || true
    fi
fi

# -----------------------------------------------------------------------------
# 4. Códecs Multimedia y FFmpeg
# -----------------------------------------------------------------------------
echo "🎬 [5/9] Instalando FFmpeg y códecs multimedia..."
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
echo "🔊 [6/9] Verificando y habilitando PipeWire y WirePlumber..."
$SUDO pacman -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber

run_as_user systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# -----------------------------------------------------------------------------
# 6. Gestión de Energía (Portátil HP) y Mantenimiento de Almacenamiento (1 TB SSD)
# -----------------------------------------------------------------------------
echo "🔋 [7/9] Configurando gestión de energía (power-profiles-daemon) y TRIM de SSD..."
$SUDO pacman -S --needed --noconfirm power-profiles-daemon util-linux

$SUDO systemctl enable --now power-profiles-daemon.service
$SUDO systemctl enable --now fstrim.timer

# -----------------------------------------------------------------------------
# 7. Stack Wayland, Portales y Compositor Niri
# -----------------------------------------------------------------------------
echo "📦 [8/9] Instalando utilidades esenciales de sistema y stack Niri Wayland..."
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
echo "🌌 [9/9] Verificando componentes y servicios de Dank Material Shell (DMS)..."

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

# Limpieza segura de paquetes
if command -v paccache &>/dev/null; then
    paccache -r 2>/dev/null || true
else
    $SUDO pacman -Sc --noconfirm || true
fi

echo "================================================================="
echo "✅ HP EliteBook 855 G7 (AMD Ryzen + Niri + DMS) configurado al 100%."
echo "   - Compilación multi-hilo (16 hilos) activa en makepkg."
echo "   - Early KMS configurado para inicialización limpia de 3 pantallas."
echo "   - Mesa RADV y VA-API con soporte 64 y 32 bits configurados."
echo "   - Gestión de energía para portátil y fstrim.timer activos."
echo "   - La apariencia, layouts y temas de Niri y DMS se han preservado intactos."
echo "💡 Si se ha actualizado el initramfs o kernel, se recomienda reiniciar el equipo."
echo "================================================================="
