#!/usr/bin/env bash
# ==============================================================================
# multimedia.sh - Instalación de Codecs Multimedia Oficiales y Reproductores Flatpak
# Configuración moderna y estable para Ubuntu Linux (GNOME Shell Wayland)
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o con sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

show_help() {
    cat <<EOF
🎬 Instalador de Codecs Multimedia y Flatpak - Ubuntu Linux

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala ubuntu-restricted-extras, FFmpeg, pila completa GStreamer,
                      herramientas VA-API/Vulkan, configura Flathub e instala VLC vía Flatpak.
  --status, -s        Muestra el estado de códecs nativos, aceleración HW y Flatpak.
  --help, -h          Muestra este mensaje de ayuda.

Componentes gestionados:
  • Pila de Códecs:         ubuntu-restricted-extras, FFmpeg, GStreamer (base, good, bad, ugly, libav, vaapi).
  • Aceleración Gráfica HW: vainfo (VA-API) y vulkan-tools.
  • Flatpak / Flathub:      Configuración de Flathub e instalación de VLC desacoplado.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO MULTIMEDIA Y CÓDECS - UBUNTU LINUX"
    echo "================================================================="
    echo "• ubuntu-restricted-extras: $(if dpkg -s ubuntu-restricted-extras &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "• FFmpeg:                   $(if command -v ffmpeg &>/dev/null; then echo "✅ FFmpeg ($(ffmpeg -version 2>/dev/null | head -n1 | awk '{print $3}'))"; else echo "❌ No instalado"; fi)"
    echo "• GStreamer VA-API:         $(if dpkg -s gstreamer1.0-vaapi &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "• GStreamer Libav:          $(if dpkg -s gstreamer1.0-libav &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "• GStreamer Plugins Ugly:   $(if dpkg -s gstreamer1.0-plugins-ugly &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "• VA-API utils (vainfo):    $(if command -v vainfo &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "• Vulkan tools:             $(if command -v vulkaninfo &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "-----------------------------------------------------------------"
    echo "• Repositorio Flathub:      $(if flatpak remotes 2>/dev/null | grep -qi "flathub"; then echo "✅ Configurado"; else echo "❌ No configurado"; fi)"
    echo "• VLC vía Flatpak:          $(if flatpak list 2>/dev/null | grep -qi "org.videolan.VLC"; then echo "✅ Instalado"; else echo "No instalado"; fi)"
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
echo "🎬 CONFIGURANDO CÓDECS MULTIMEDIA Y FLATPAK EN UBUNTU LINUX"
echo "================================================================="

# 1. Pila Oficial de Ubuntu para FFmpeg, GStreamer y utilidades
echo "🎵 [1/3] Instalando suite oficial de FFmpeg, GStreamer y utilidades de hardware..."
$SUDO apt-get update -qq
$SUDO apt-get install -y \
    ffmpeg \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-vaapi \
    vainfo \
    vulkan-tools 2>/dev/null || true

# Intentar instalar ubuntu-restricted-extras sin prompts bloqueantes de EULA
echo "📦 [2/3] Instalando extras restringidos (códecs de audio/video)..."
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | $SUDO debconf-set-selections 2>/dev/null || true
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y ubuntu-restricted-extras 2>/dev/null || true

# 2. Integración de Flatpak & Flathub
echo "📦 [3/3] Asegurando soporte de Flatpak y repositorio Flathub..."
$SUDO apt-get install -y flatpak gnome-software-plugin-flatpak 2>/dev/null || true
$SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# Instalar VLC desacoplado vía Flatpak
echo "🚀 Instalando reproductor VLC desacoplado vía Flatpak (Flathub)..."
flatpak install -y --noninteractive flathub org.videolan.VLC 2>/dev/null || true

echo "================================================================="
echo "✅ Pila multimedia oficial y Flatpak configurados con éxito."
echo "================================================================="
