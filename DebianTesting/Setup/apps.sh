#!/bin/bash
# apps.sh - Instalación de aplicaciones esenciales, desarrollo, multimedia y Flatpak para Debian Testing (Trixie) + GNOME
# Paquetes depurados y optimizados para entornos modernos con Wayland, PipeWire y Libadwaita

set -euo pipefail

echo "================================================================="
echo "📦 INSTALACIÓN DE APLICACIONES Y UTILIDADES ESENCIALES (DEBIAN TESTING)"
echo "================================================================="

# Manejo de permisos de sudo
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# 1. Actualización de repositorios
echo "ℹ️ [1/5] Actualizando lista de paquetes de Debian Testing..."
$SUDO apt update

# 2. Herramientas de Desarrollo y Compilación
# Nota: 'build-essential' ya incluye gcc, g++, make y libc-dev
echo "ℹ️ [2/5] Instalando herramientas de compilación y monitoreo del sistema..."
DEV_TOOLS=(
    build-essential
    cmake
    automake
    autoconf
    git
    curl
    btop
    htop
    inxi
)

$SUDO apt install -y "${DEV_TOOLS[@]}" 2>/dev/null || true

# 3. Utilidades de Disco, Compresión y Sistema
# Nota: Usamos 'exfatprogs' (nativo en kernel) y '7zip' (soporte moderno oficial)
echo "ℹ️ [3/5] Instalando utilidades de compresión y gestión de almacenamiento..."
SYSTEM_TOOLS=(
    gparted
    exfatprogs
    7zip
    p7zip-full
    zip
    unzip
    bzip2
    xz-utils
)

$SUDO apt install -y "${SYSTEM_TOOLS[@]}" 2>/dev/null || true

# 4. Multimedia, Gráficos, Codecs y Aceleración por Hardware (VA-API / GStreamer / Nautilus)
# Nota: Incluye soporte para aceleración GPU, miniaturas en Nautilus (HEIC, WebP, vídeos) y formatos lossless
echo "ℹ️ [4/5] Instalando aplicaciones multimedia, suite completa de codecs y miniaturas..."
MEDIA_APPS=(
    vlc
    mpv
    gimp
    ffmpeg
    libavcodec-extra
    gstreamer1.0-plugins-base
    gstreamer1.0-plugins-good
    gstreamer1.0-plugins-bad
    gstreamer1.0-plugins-ugly
    gstreamer1.0-libav
    gstreamer1.0-vaapi
    flac
    lame
    opus-tools
    mediainfo
    vainfo
    ffmpegthumbnailer
    heif-gdk-pixbuf
    heif-thumbnailer
    webp-pixbuf-loader
)

$SUDO apt install -y "${MEDIA_APPS[@]}" 2>/dev/null || true

# 5. Tiendas de Aplicaciones y Ecosistema Flatpak
# Nota: 'flatpak' + 'gnome-software-plugin-flatpak' reemplazan a herramientas X11 obsoletas como synaptic
echo "ℹ️ [5/5] Configurando Flatpak y repositorio oficial Flathub..."
$SUDO apt install -y flatpak gnome-software-plugin-flatpak 2>/dev/null || true
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 6. Temas e Iconos (Papirus)
echo "ℹ️ Instalando tema de iconos Papirus..."
$SUDO apt install -y papirus-icon-theme 2>/dev/null || true

echo "================================================================="
echo "✅ Instalación de aplicaciones y herramientas completada con éxito."
echo "💡 Recuerda reiniciar la sesión para que todos los plugins de GNOME Software y Flatpak se integren."
echo "================================================================="
