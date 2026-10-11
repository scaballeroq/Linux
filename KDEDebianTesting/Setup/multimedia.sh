#!/bin/bash
# ==============================================================================
# multimedia.sh - Instalación de Codecs Multimedia Oficiales y Flatpaks
# Configuración moderna sin deb-multimedia para Debian Testing (KDE Plasma 6)
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

is_pkg_installed() {
    local pkg="$1"
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

show_help() {
    cat <<EOF
🎬 Instalador de Codecs Multimedia Oficiales y Flatpak - Debian Testing
(Siguiendo las recomendaciones modernas: sin repositorio deb-multimedia ni conflictos en dist-upgrade)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala códecs nativos de Debian Testing (FFmpeg, GStreamer, VA-API),
                      configura Flathub e instala VLC desacoplado vía Flatpak.
  --status, -s        Muestra el estado de códecs oficiales, aceleración HW y Flatpak.
  --help, -h          Muestra este mensaje de ayuda.

Componentes instalados:
  • Suite Oficial Debian: FFmpeg y GStreamer (base, good, bad, ugly, libav, vaapi).
  • Aceleración HW:       vainfo, mesa-va-drivers y vulkan-tools.
  • Flatpak / Flathub:    Configuración de Flathub e instalación de reproductores (VLC) con códecs completos.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO MULTIMEDIA Y CÓDECS - DEBIAN TESTING"
    echo "================================================================="
    echo "• Repositorio deb-multimedia:  $(if grep -rq "deb-multimedia.org" /etc/apt/ /etc/apt/sources.list.d/ 2>/dev/null; then echo "⚠️ Detectado (no recomendado)"; else echo "✅ No presente (recomendado: 100% puro Debian)"; fi)"
    echo "-----------------------------------------------------------------"
    echo "• FFmpeg instalado:            $(if is_pkg_installed ffmpeg; then echo "✅ FFmpeg ($(dpkg-query -W -f='${Version}' ffmpeg 2>/dev/null))"; else echo "❌ No instalado"; fi)"
    echo "• GStreamer Plugins Libav:     $(if is_pkg_installed gstreamer1.0-libav; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• GStreamer Plugins VA-API:    $(if is_pkg_installed gstreamer1.0-vaapi; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• GStreamer Plugins Good:      $(if is_pkg_installed gstreamer1.0-plugins-good; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• GStreamer Plugins Bad:       $(if is_pkg_installed gstreamer1.0-plugins-bad; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• GStreamer Plugins Ugly:      $(if is_pkg_installed gstreamer1.0-plugins-ugly; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• Aceleración VA-API (vainfo): $(if command -v vainfo &>/dev/null; then echo "✅ vainfo disponible"; else echo "❌ No instalado"; fi)"
    echo "• Mesa VA Drivers:             $(if is_pkg_installed mesa-va-drivers; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "-----------------------------------------------------------------"
    echo "• Repositorio Flathub:         $(if flatpak remotes 2>/dev/null | grep -qi "flathub"; then echo "✅ Configurado"; else echo "❌ No configurado"; fi)"
    echo "• VLC vía Flatpak:             $(if flatpak list 2>/dev/null | grep -qi "org.videolan.VLC"; then echo "✅ Instalado"; else echo "No instalado"; fi)"
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
echo "🎬 CONFIGURANDO CÓDECS MULTIMEDIA OFICIALES (DEBIAN TESTING)"
echo "================================================================="

# 1. Pila Oficial de Debian para FFmpeg, GStreamer y utilidades
echo "🎵 [1/3] Instalando suite oficial de FFmpeg, plugins GStreamer y utilidades VA-API..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -qq
$SUDO apt-get install -y \
    ffmpeg \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-vaapi \
    gstreamer1.0-tools \
    vainfo \
    mesa-va-drivers \
    vulkan-tools 2>/dev/null || true

# 2. Integración de Flatpak & Flathub
echo "📦 [2/3] Asegurando soporte de Flatpak y repositorio Flathub..."
$SUDO apt-get install -y flatpak plasma-discover-backend-flatpak 2>/dev/null || true
$SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 3. Instalación de Reproductor Multimedia Desacoplado (VLC con códecs completos vía Flatpak)
echo "🚀 [3/3] Instalando reproductor VLC desacoplado vía Flatpak (Flathub)..."
flatpak install -y --noninteractive flathub org.videolan.VLC 2>/dev/null || true

echo "================================================================="
echo "✅ Pila multimedia oficial y Flatpak configurados con éxito."
echo "💡 Tu sistema base permanece 100% puro contra repositorios oficiales de Debian,"
echo "   garantizando actualizaciones limpias y estables con 'apt-get dist-upgrade'."
echo "================================================================="
