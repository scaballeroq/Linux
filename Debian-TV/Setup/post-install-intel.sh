#!/bin/bash
# ==============================================================================
# post-install-intel.sh - Post-instalación Debian TV & Media Center (HP Z230 SFF)
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD Graphics 4600)
# Memoria: 8.0 GiB RAM | Disco: 256 GB SSD | Pantalla: Sony TV (Wayland GNOME)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: DEBIAN TV (HP Z230 SFF - INTEL CORE)"
echo "================================================================="

CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "trixie")
fi

echo "Debian detectado: $CODENAME"

# 1. Actualización Base y Herramientas de Gestión de Repositorios
echo "ℹ️ [1/10] Actualizando repositorios y herramientas base..."
sudo apt update
sudo apt install -y curl wget ca-certificates gnupg lsb-release

# 2. Habilitar Repositorios Extra (Contrib, Non-Free, Non-Free-Firmware)
echo "ℹ️ [2/10] Habilitando contrib, non-free y non-free-firmware para $CODENAME..."
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sudo sed -i '/^Components:/ {/contrib/! s/$/ contrib/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
    sudo sed -i '/^Components:/ {/non-free/! s/$/ non-free/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
    sudo sed -i '/^Components:/ {/non-free-firmware/! s/$/ non-free-firmware/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
fi
if [ -f /etc/apt/sources.list ]; then
    sudo sed -i '/^deb / {/contrib/! s/\(main\)/\1 contrib non-free non-free-firmware/}' /etc/apt/sources.list 2>/dev/null || true
fi

sudo apt update
sudo apt upgrade -y

# 3. Pre-aceptar licencias de tipografías si aplica
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections 2>/dev/null || true

# 4. Software Esencial y Utilidades de Sistema (GNOME Wayland)
echo "ℹ️ [3/10] Instalando utilidades esenciales del sistema..."
sudo apt install -y \
    build-essential \
    linux-headers-amd64 \
    curl \
    wget \
    btop \
    htop \
    inxi \
    fuse3 \
    exfatprogs \
    gparted \
    7zip \
    p7zip-full \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz-utils \
    fastfetch \
    ca-certificates \
    gnupg \
    flatpak \
    gnome-software-plugin-flatpak \
    gnome-tweaks \
    power-profiles-daemon \
    wl-clipboard 2>/dev/null || true

# Compatibilidad FUSE para AppImages
sudo apt install -y libfuse2t64 2>/dev/null || sudo apt install -y libfuse2 2>/dev/null || true

# 5. Microcódigo y Firmware Intel oficial
echo "ℹ️ [4/10] Instalando microcódigo Intel Haswell y firmware oficial..."
sudo apt install -y \
    intel-microcode \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree 2>/dev/null || sudo apt install -y intel-microcode firmware-linux-nonfree 2>/dev/null || true

# 6. Stack Gráfico Intel (Mesa / VA-API i965 / Vulkan / Herramientas)
echo "ℹ️ [5/10] Instalando controladores gráficos Intel HD 4600 (driver VA-API i965)..."
sudo apt install -y \
    i965-va-driver \
    i965-va-driver-shaders \
    intel-media-va-driver \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    mesa-vulkan-drivers \
    libva-wayland2 \
    vulkan-tools \
    vainfo \
    intel-gpu-tools \
    mesa-utils \
    libgl1-mesa-dri 2>/dev/null || sudo apt install -y i965-va-driver intel-media-va-driver mesa-va-drivers vainfo || true

# Configurar variable de entorno global para driver VA-API Haswell (i965)
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    TARGET_USER="$SUDO_USER"
else
    USER_HOME="${HOME:-/home/${USER:-caballero}}"
    TARGET_USER="${USER:-caballero}"
fi

mkdir -p "$USER_HOME/.config/environment.d"
cat <<'EOF' > "$USER_HOME/.config/environment.d/90-intel-vaapi.conf"
# Forzar driver i965 para aceleración hardware Haswell (Intel HD Graphics 4600)
LIBVA_DRIVER_NAME=i965
VDPAU_DRIVER=va_gl
MOZ_ENABLE_WAYLAND=1
EOF
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.config/environment.d" 2>/dev/null || true

# 7. Codecs Multimedia, FFmpeg, GStreamer y PipeWire (Salida HDMI TV Sony)
echo "ℹ️ [6/10] Instalando códecs multimedia y plugins GStreamer..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    ffmpeg \
    libavcodec-extra \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-gl \
    gstreamer1.0-pipewire 2>/dev/null || true

# Servidor de audio PipeWire & WirePlumber nativo
sudo apt install -y pipewire pipewire-alsa pipewire-pulse wireplumber 2>/dev/null || true
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    sudo -u "$SUDO_USER" systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
fi

# 8. Memoria ZRAM (4 GB ZRAM para 8 GB RAM física con ZSTD)
echo "ℹ️ [7/10] Configurando swap comprimida en RAM (ZRAM con ZSTD)..."
if [ -f "$(dirname "$0")/zram-setup.sh" ]; then
    bash "$(dirname "$0")/zram-setup.sh"
else
    sudo apt install -y zram-tools 2>/dev/null || true
    if [ -f /etc/default/zramswap ]; then
        sudo sed -i 's/^#*ALGORITHM=.*/ALGORITHM=zstd/' /etc/default/zramswap
        sudo sed -i 's/^#*PERCENT=.*/PERCENT=50/' /etc/default/zramswap
        sudo systemctl enable --now zramswap.service 2>/dev/null || true
        sudo systemctl restart zramswap.service 2>/dev/null || true
    fi
fi

# 9. Habilitar TRIM para el SSD de 256 GB
echo "ℹ️ [8/10] Habilitando TRIM automático periódico para el SSD..."
sudo systemctl enable --now fstrim.timer 2>/dev/null || true

# 10. Integración de Flathub e instalación de aplicaciones clave (Kodi, Stremio, VLC)
echo "ℹ️ [9/10] Registrando Flathub e instalando aplicaciones multimedia (Kodi, Stremio, VLC)..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# Instalar aplicaciones multimedia en Flatpak
echo "⬇️ Instalando Kodi (Flatpak)..."
flatpak install -y flathub tv.kodi.Kodi 2>/dev/null || true

echo "⬇️ Instalando Stremio (Flatpak)..."
flatpak install -y flathub com.stremio.Stremio 2>/dev/null || true

echo "⬇️ Instalando VLC (Flatpak)..."
flatpak install -y flathub org.videolan.VLC 2>/dev/null || true

# Asignar permisos para aceleración gráfica por hardware en Flatpaks
echo "⚙️ Configurando aceleración y accesos de audio/video para Flatpaks multimedia..."
flatpak override --user --device=all tv.kodi.Kodi 2>/dev/null || true
flatpak override --user --socket=wayland --socket=pulseaudio tv.kodi.Kodi 2>/dev/null || true
flatpak override --user --device=all com.stremio.Stremio 2>/dev/null || true
flatpak override --user --socket=wayland --socket=pulseaudio com.stremio.Stremio 2>/dev/null || true
flatpak override --user --device=all org.videolan.VLC 2>/dev/null || true
flatpak override --user --socket=wayland --socket=pulseaudio org.videolan.VLC 2>/dev/null || true

# Limpieza de paquetes residuales para proteger el espacio del SSD de 256 GB
echo "ℹ️ [10/10] Limpiando dependencias huérfanas y cachés..."
sudo apt autoremove --purge -y
sudo apt clean
flatpak uninstall --unused -y 2>/dev/null || true

echo "================================================================="
echo "✅ Post-instalación completada con éxito en Debian TV (HP Z230 SFF)."
echo "📺 Aplicaciones listas: Kodi, Stremio, VLC y aceleración Intel HD 4600."
echo "💡 Reinicia el equipo para cargar el microcódigo y controladores actualizados."
echo "================================================================="
