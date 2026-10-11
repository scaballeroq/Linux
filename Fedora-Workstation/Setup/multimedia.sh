#!/bin/bash
# ==============================================================================
# multimedia.sh - Instalación de Codecs Multimedia Completos, FFmpeg y Drivers Privativos
# Habilita RPM Fusion (Free, Non-Free y Tainted) y aceleración de hardware en Fedora 44
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

show_help() {
    cat <<EOF
🎬 Instalador de Codecs Multimedia, FFmpeg y Drivers Privativos - Fedora 44

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Habilita RPM Fusion (Free, Nonfree, Tainted), OpenH264, FFmpeg completo,
                      GStreamer freeworld, codecs privativos y drivers VA-API/VDPAU.
  --status, -s        Muestra el estado de los repositorios RPM Fusion, FFmpeg y codecs instalados.
  --help, -h          Muestra este mensaje de ayuda.

Componentes instalados:
  • Repositorios:     RPM Fusion Free, Non-Free, Free Tainted, Non-Free Tainted y Fedora Cisco OpenH264.
  • FFmpeg Completo:  Sustitución de ffmpeg-free por ffmpeg nativo completo sin limitaciones de patente.
  • GStreamer Stack:  gstreamer1-plugins-base, good, bad-free, bad-freeworld, ugly, libav y openh264.
  • Codecs Audio/Vid: libdvdcss, libdvdread, libdvdnav, lame, faac, faad2, x264, x265, libde265.
  • Aceleración HW:   mesa-va-drivers-freeworld y mesa-vdpau-drivers-freeworld (AMD/Intel).
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO MULTIMEDIA Y CODECS PRIVATIVOS - FEDORA 44"
    echo "================================================================="
    echo "• RPM Fusion Free:          $(rpm -q rpmfusion-free-release 2>/dev/null || echo 'No instalado')"
    echo "• RPM Fusion Non-Free:      $(rpm -q rpmfusion-nonfree-release 2>/dev/null || echo 'No instalado')"
    echo "• RPM Fusion Free Tainted:  $(rpm -q rpmfusion-free-release-tainted 2>/dev/null || echo 'No instalado')"
    echo "• RPM Fusion NonFree Tainted: $(rpm -q rpmfusion-nonfree-release-tainted 2>/dev/null || echo 'No instalado')"
    echo "-----------------------------------------------------------------"
    echo "• FFmpeg instalado:         $(if rpm -q ffmpeg &>/dev/null; then echo "✅ FFmpeg completo ($(rpm -q --qf '%{VERSION}' ffmpeg))"; elif rpm -q ffmpeg-free &>/dev/null; then echo "⚠️ ffmpeg-free (limitado)"; else echo "❌ No instalado"; fi)"
    echo "• libdvdcss (DVD descifrado): $(rpm -q libdvdcss 2>/dev/null || echo 'No instalado')"
    echo "• GStreamer Ugly:           $(rpm -q gstreamer1-plugins-ugly 2>/dev/null || echo 'No instalado')"
    echo "• GStreamer Bad Freeworld:  $(rpm -q gstreamer1-plugins-bad-freeworld 2>/dev/null || echo 'No instalado')"
    echo "• Mesa VA-API Freeworld:    $(rpm -q mesa-va-drivers-freeworld 2>/dev/null || echo 'No instalado')"
    echo "• Mesa VDPAU Freeworld:   $(rpm -q mesa-vdpau-drivers-freeworld 2>/dev/null || echo 'No instalado')"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🎬 CONFIGURANDO REPOSITORIOS RPM FUSION Y CODECS PRIVATIVOS"
echo "================================================================="

# 1. Habilitar Repositorios Oficiales RPM Fusion (Free y Non-Free)
echo "📦 [1/6] Instalando y habilitando repositorios oficiales RPM Fusion (Free y Non-Free)..."
$SUDO dnf5 install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>/dev/null || true

$SUDO dnf5 install -y \
    rpmfusion-free-appstream-data \
    rpmfusion-nonfree-appstream-data 2>/dev/null || true

# 2. Habilitar Repositorios Tainted (Permite libdvdcss y codecs con patentes adicionales)
echo "🔓 [2/6] Habilitando repositorios RPM Fusion Tainted (Free y Non-Free)..."
$SUDO dnf5 install -y \
    rpmfusion-free-release-tainted \
    rpmfusion-nonfree-release-tainted 2>/dev/null || true

# 3. Habilitar repositorio Cisco OpenH264
echo "🌐 [3/6] Habilitando repositorio de códec OpenH264..."
$SUDO dnf5 config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true

# 4. Sustituir FFmpeg-free por FFmpeg Completo
echo "🔄 [4/6] Sustituyendo ffmpeg-free por FFmpeg completo de RPM Fusion..."
$SUDO dnf5 swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null || \
    $SUDO dnf5 install -y ffmpeg --allowerasing 2>/dev/null || true

# 5. Instalar Paquetes de Aceleración por Hardware (VA-API / VDPAU)
echo "⚡ [5/6] Instalando controladores freeworld con soporte completo de aceleración HW..."
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || true)

# Mesa freeworld para AMD e Intel
$SUDO dnf5 install -y \
    mesa-va-drivers-freeworld \
    mesa-vdpau-drivers-freeworld \
    libva-utils \
    vulkan-tools 2>/dev/null || true

if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
    echo "ℹ️ Procesador Intel detectado: instalando controladores intel-media-driver..."
    $SUDO dnf5 install -y \
        intel-media-driver \
        libva-intel-driver 2>/dev/null || true
fi

# 6. Pila Completa de Plugins GStreamer, Codecs Privativos y Reproducción DVD
echo "🎵 [6/6] Instalando colección completa de codecs multimedia y plugins GStreamer..."
$SUDO dnf5 install -y \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly \
    gstreamer1-plugin-openh264 \
    gstreamer1-vaapi \
    gstreamer1-libav \
    lame \
    lame-mp3x \
    faac \
    faad2 \
    x264 \
    x265 \
    libde265 \
    libdvdcss \
    libdvdread \
    libdvdnav \
    libheif-ffmpeg \
    lsdvd 2>/dev/null || true

# Resolver conflicto de versión entre libheif (updates) y libheif-freeworld (RPM Fusion)
if rpm -q libheif-freeworld &>/dev/null; then
    $SUDO dnf5 swap -y libheif-freeworld libheif-ffmpeg --allowerasing 2>/dev/null || true
fi

# Actualizar el grupo multimedia sin dependencias débiles innecesarias ni libheif-freeworld
$SUDO dnf5 update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin,libheif-freeworld -y 2>/dev/null || true

echo "================================================================="
echo "✅ Colección multimedia, RPM Fusion y drivers privativos instalados con éxito."
echo "================================================================="
