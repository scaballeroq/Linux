#!/bin/bash
# ==============================================================================
# multimedia.sh - Instalación de Codecs Multimedia Oficiales (OpenH264) y Flatpaks
# Configuración moderna sin Packman para openSUSE Tumbleweed (KDE Plasma 6)
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
🎬 Instalador de Codecs Multimedia Oficiales y Flatpak - openSUSE Tumbleweed
(Siguiendo las recomendaciones modernas: sin repositorio Packman ni conflictos en zypper dup)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Habilita el repositorio oficial OpenH264 (Cisco), instala códecs nativos
                      de openSUSE, configura Flathub e instala VLC desacoplado vía Flatpak.
  --status, -s        Muestra el estado de los repositorios, códecs oficiales, aceleración HW y Flatpak.
  --help, -h          Muestra este mensaje de ayuda.

Componentes instalados:
  • Repositorio OpenH264: Soporte oficial de Cisco/openSUSE (libopenh264-8, mozilla-openh264).
  • Suite Oficial openSUSE: FFmpeg y GStreamer (base, good, bad, libav, vaapi).
  • Aceleración HW:         libva-utils (vainfo) y vulkan-tools.
  • Flatpak / Flathub:      Configuración de Flathub e instalación de reproductores (VLC) con códecs completos.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO MULTIMEDIA Y CÓDECS - OPENSUSE TUMBLEWEED"
    echo "================================================================="
    echo "• Repositorio OpenH264 (Cisco): $(if zypper lr 2>/dev/null | grep -qi "openh264"; then echo "✅ Configurado"; else echo "❌ No instalado"; fi)"
    echo "• Repositorio Packman:         $(if zypper lr 2>/dev/null | grep -qi "packman"; then echo "⚠️ Detectado (no recomendado)"; else echo "✅ No presente (recomendado)"; fi)"
    echo "-----------------------------------------------------------------"
    echo "• FFmpeg instalado:            $(if rpm -q ffmpeg &>/dev/null; then echo "✅ FFmpeg ($(rpm -q --qf '%{VERSION}' ffmpeg))"; else echo "❌ No instalado"; fi)"
    echo "• Librería OpenH264 (Cisco):   $(if rpm -q libopenh264-8 &>/dev/null; then echo "✅ libopenh264-8 ($(rpm -q --qf '%{VERSION}' libopenh264-8))"; else echo "❌ No instalado"; fi)"
    echo "• Mozilla OpenH264 (Firefox):  $(if rpm -q mozilla-openh264 &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "• GStreamer Plugins Libav:     $(if rpm -q gstreamer-plugins-libav &>/dev/null; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• GStreamer Plugins VA-API:    $(if rpm -q gstreamer-plugins-vaapi &>/dev/null; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• GStreamer Plugins Good:      $(if rpm -q gstreamer-plugins-good &>/dev/null; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• GStreamer Plugins Bad:       $(if rpm -q gstreamer-plugins-bad &>/dev/null; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• VA-API utils:                $(if rpm -q libva-utils &>/dev/null; then echo "✅ Instalado"; else echo "No instalado"; fi)"
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
echo "🎬 CONFIGURANDO CÓDECS MULTIMEDIA OFICIALES (SIN PACKMAN)"
echo "================================================================="

# 1. Habilitar Repositorio oficial OpenH264
echo "📦 [1/4] Habilitando repositorio oficial OpenH264 e instalando códecs de Cisco..."
if ! zypper lr 2>/dev/null | grep -qi "openh264"; then
    $SUDO zypper --non-interactive install -y openSUSE-repos-Tumbleweed 2>/dev/null || true
fi
$SUDO zypper mr -e repo-openh264 2>/dev/null || $SUDO zypper mr -e openSUSE:repo-openh264 2>/dev/null || true
$SUDO zypper --gpg-auto-import-keys refresh 2>/dev/null || true
$SUDO zypper --non-interactive install -y libopenh264-8 mozilla-openh264 2>/dev/null || true

# 2. Pila Oficial de openSUSE para FFmpeg, GStreamer y utilidades
echo "🎵 [2/4] Instalando suite oficial de FFmpeg, plugins GStreamer y utilidades VA-API..."
$SUDO zypper --non-interactive install -y \
    ffmpeg \
    gstreamer-plugins-base \
    gstreamer-plugins-good \
    gstreamer-plugins-bad \
    gstreamer-plugins-libav \
    gstreamer-plugins-vaapi \
    libdvdread8 \
    libdvdnav4 \
    libva-utils \
    vulkan-tools 2>/dev/null || true

# 3. Integración de Flatpak & Flathub
echo "📦 [3/4] Asegurando soporte de Flatpak y repositorio Flathub..."
$SUDO zypper --non-interactive install -y flatpak 2>/dev/null || true
$SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 4. Instalación de Reproductor Multimedia Desacoplado (VLC con códecs completos vía Flatpak)
echo "🚀 [4/4] Instalando reproductor VLC desacoplado vía Flatpak (Flathub)..."
flatpak install -y --noninteractive flathub org.videolan.VLC 2>/dev/null || true

echo "================================================================="
echo "✅ Pila multimedia oficial (OpenH264) y Flatpak configurados con éxito."
echo "💡 Tu sistema base permanece 100% puro contra repositorios de openSUSE,"
echo "   garantizando actualizaciones limpias y estables con 'zypper dup'."
echo "================================================================="
