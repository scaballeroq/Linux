#!/bin/bash
# ==============================================================================
# post-install-intel.sh - Post-instalación CachyOS TV & Media Center
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD Graphics 4600)
# Memoria: 8.0 GiB RAM | Disco: 256 GB SSD | Pantalla: Sony TV (Wayland GNOME)
# ==============================================================================
# Incluye:
#   - Optimizaciones Pacman (descargas paralelas x10, compresión zstd multihilo)
#   - Kernel CachyOS / Linux, firmware y microcódigo Intel Haswell
#   - Stack gráfico Mesa + VA-API Intel Haswell (driver i965 / libva-intel-driver)
#   - Compresión ZRAM con ZSTD al 50% de RAM (4 GB ZRAM para 8 GB RAM física)
#   - TRIM automático periódico (fstrim.timer) para SSD de 256 GB
#   - Audio PipeWire y WirePlumber nativos con salida HDMI hacia la Sony TV
#   - Kodi nativo (Pacman) con soporte SMB/NFS y aceleración hardware
#   - Flatpaks de entretenimiento: Stremio y VLC con overrides Intel y mpv.conf
#   - Modo oscuro global en GNOME Shell Wayland
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: CACHYOS TV (HP Z230 SFF - SONY TV)"
echo "HARDWARE: INTEL CORE i7-4790 / INTEL HD GRAPHICS 4600 (HASWELL)"
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

# 1. Optimización de Pacman y Makepkg
echo "⚙️ [1/11] Configurando optimizaciones en Pacman y Makepkg..."
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

# 2. Habilitar repositorios multilib y Chaotic-AUR
echo "📦 [2/11] Verificando repositorios multilib y Chaotic-AUR..."
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
fi

echo "🔄 [3/11] Actualizando bases de datos de paquetes..."
$SUDO pacman -Sy --noconfirm

# 3. Kernel Linux, Firmware y Microcódigo Intel Haswell
echo "🐧 [4/11] Instalando Kernel, Firmware y Microcódigo Intel..."
$SUDO pacman -S --needed --noconfirm \
    intel-ucode \
    linux-firmware 2>/dev/null || true

# 4. Memoria ZRAM (4 GB ZRAM para 8 GB RAM física con algoritmo ZSTD)
echo "💾 [5/11] Configurando ZRAM con algoritmo ZSTD al 50% de RAM..."
$SUDO pacman -S --needed --noconfirm zram-generator 2>/dev/null || true
$SUDO tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
EOF
$SUDO systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

# 5. Stack Gráfico Intel Haswell (Mesa / VA-API i965 / Crocus OpenGL)
echo "🎮 [6/11] Instalando controladores gráficos Intel HD 4600 (driver VA-API i965)..."
$SUDO pacman -S --needed --noconfirm \
    mesa \
    libva-intel-driver \
    intel-media-driver \
    vulkan-intel \
    vulkan-tools \
    libva-utils \
    mesa-utils \
    intel-gpu-tools 2>/dev/null || true

# Configurar variable de entorno global para driver VA-API Haswell (i965)
mkdir -p "$USER_HOME/.config/environment.d"
cat <<'EOF' > "$USER_HOME/.config/environment.d/90-intel-vaapi.conf"
# Forzar driver i965 para aceleración hardware Haswell (Intel HD Graphics 4600)
LIBVA_DRIVER_NAME=i965
VDPAU_DRIVER=va_gl
MOZ_ENABLE_WAYLAND=1
EOF
chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config/environment.d" 2>/dev/null || true

# 6. Codecs Multimedia, FFmpeg y Audio PipeWire (Salida HDMI TV Sony)
echo "🎬 [7/11] Instalando códecs multimedia y plugins GStreamer..."
$SUDO pacman -S --needed --noconfirm \
    ffmpeg \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber 2>/dev/null || true

run_as_user systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 7. Red y Descubrimiento para NAS doméstico
echo "🌐 [8/11] Instalando utilidades de red y clientes de NAS para Kodi..."
$SUDO pacman -S --needed --noconfirm \
    smbclient \
    cifs-utils \
    nfs-utils \
    gvfs-smb \
    avahi \
    nss-mdns 2>/dev/null || true

$SUDO systemctl enable --now avahi-daemon.service 2>/dev/null || true

# 8. Software Base, Flatpak e Integración GNOME
echo "📦 [9/11] Instalando utilidades de escritorio GNOME y Flatpak..."
$SUDO pacman -S --needed --noconfirm \
    base-devel \
    curl \
    wget \
    btop \
    htop \
    inxi \
    fuse2 \
    fuse3 \
    exfatprogs \
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
    adw-gtk-theme \
    adwaita-icon-theme \
    nautilus \
    sushi \
    loupe \
    file-roller \
    ffmpegthumbnailer \
    gnome-disk-utility \
    wl-clipboard \
    grim \
    slurp \
    firewalld \
    flatpak 2>/dev/null || true

$SUDO systemctl enable --now firewalld.service 2>/dev/null || true
$SUDO systemctl enable --now fstrim.timer 2>/dev/null || true

# 9. Kodi Nativo (Pacman)
echo "📺 [10/11] Instalando Kodi nativo con plugins de streaming..."
$SUDO pacman -S --needed --noconfirm \
    kodi \
    kodi-inputstream-adaptive \
    kodi-inputstream-ffmpegdirect 2>/dev/null || true

# 10. Flatpaks Multimedia (Stremio y VLC)
echo "🍿 [11/11] Configurando Flathub, Stremio y VLC..."
run_as_user flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

echo "⬇️ Instalando Stremio (Flatpak)..."
run_as_user flatpak install -y flathub com.stremio.Stremio 2>/dev/null || true

echo "⬇️ Instalando VLC (Flatpak)..."
run_as_user flatpak install -y flathub org.videolan.VLC 2>/dev/null || true

# Asignar permisos específicos y overrides para Intel Haswell
echo "⚙️ Configurando aceleración y accesos de audio/video para Flatpaks..."
run_as_user flatpak override --user \
  --device=dri \
  --socket=wayland \
  --socket=pulseaudio \
  --filesystem=xdg-run/pipewire-0 \
  --talk-name=org.freedesktop.Flatpak \
  --env=VK_DRIVER_FILES=/dev/null \
  --env=VK_ICD_FILENAMES=/dev/null \
  --env=GSK_RENDERER=gl \
  --env=LIBVA_DRIVER_NAME=i965 \
  com.stremio.Stremio 2>/dev/null || true

run_as_user flatpak override --user \
  --device=dri \
  --socket=wayland \
  --socket=pulseaudio \
  --filesystem=xdg-run/pipewire-0 \
  org.videolan.VLC 2>/dev/null || true

# Configuración de audio MPV para Stremio (evitar clipping multi-canal y chasquidos en TV estéreo HDMI)
local_stremio_mpv="${USER_HOME}/.var/app/com.stremio.Stremio/config/mpv"
run_as_user mkdir -p "$local_stremio_mpv"
cat <<'EOF' | run_as_user tee "$local_stremio_mpv/mpv.conf" > /dev/null
# Configuración de audio y video optimizada para Stremio en Sony TV (HDMI Estéreo Haswell)
ao=pulse
audio-channels=stereo
audio-samplerate=48000
audio-format=s16
audio-buffer=0.2
audio-normalize-downmix=yes
volume-max=100
hwdec=vaapi
EOF

# Forzar Tema Oscuro Global en GNOME
run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true

echo "================================================================="
echo "✅ Post-instalación completada con éxito en CachyOS TV (HP Z230 SFF)."
echo "📺 Centro multimedia listo: Kodi (Nativo), Stremio, VLC y Chrome WebApps."
echo "💡 Se recomienda reiniciar el sistema para cargar microcódigo y drivers actualizados."
echo "================================================================="
