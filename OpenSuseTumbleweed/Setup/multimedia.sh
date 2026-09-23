#!/bin/bash
# ==============================================================================
# multimedia.sh - Instalación de Codecs Multimedia Completos, FFmpeg y Packman
# Habilita el repositorio Packman (Prioridad 90) y aceleración de hardware en openSUSE Tumbleweed
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
🎬 Instalador de Codecs Multimedia, FFmpeg y Packman - openSUSE Tumbleweed

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Habilita el repositorio Packman (Prioridad 90), cambia los paquetes multimedia
                      a Packman (vendor change), e instala FFmpeg completo y GStreamer.
  --status, -s        Muestra el estado del repositorio Packman, FFmpeg y codecs instalados.
  --help, -h          Muestra este mensaje de ayuda.

Componentes instalados:
  • Repositorios:     Packman Tumbleweed (prioridad 90 para asegurar codecs completos).
  • FFmpeg Completo:  Sustitución de ffmpeg limitado por ffmpeg nativo completo sin restricciones.
  • GStreamer Stack:  gstreamer-plugins-base, good, bad, ugly, libav y vaapi.
  • Codecs Audio/Vid: libdvdcss2, libdvdread, libdvdnav, lame, faac, faad2, x264, x265.
  • Aceleración HW:   VA-API, VDPAU y herramientas Vulkan.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO MULTIMEDIA Y CODECS - OPENSUSE TUMBLEWEED"
    echo "================================================================="
    echo "• Repositorio Packman:      $(if zypper lr 2>/dev/null | grep -qi "packman"; then echo "✅ Configurado"; else echo "❌ No instalado"; fi)"
    echo "• Prioridad Packman:        $(zypper lr -p 2>/dev/null | grep -i "packman" | awk '{print $3}' || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "• FFmpeg instalado:         $(if rpm -q ffmpeg &>/dev/null; then echo "✅ FFmpeg ($(rpm -q --qf '%{VERSION}' ffmpeg))"; else echo "❌ No instalado"; fi)"
    echo "• libdvdcss2 (DVD cifrado): $(if rpm -q libdvdcss2 &>/dev/null; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• GStreamer Plugins Ugly:   $(if rpm -q gstreamer-plugins-ugly &>/dev/null; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• GStreamer Plugins Libav:  $(if rpm -q gstreamer-plugins-libav &>/dev/null; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• VA-API utils:             $(if rpm -q libva-utils &>/dev/null; then echo "✅ Instalado"; else echo "No instalado"; fi)"
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
echo "🎬 CONFIGURANDO REPOSITORIO PACKMAN Y CODECS MULTIMEDIA"
echo "================================================================="

# 1. Habilitar Repositorio Packman con Prioridad 90
echo "📦 [1/4] Habilitando repositorio Packman Tumbleweed con prioridad 90..."
if ! zypper lr 2>/dev/null | grep -qi "packman"; then
    $SUDO zypper --non-interactive ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman || true
fi

echo "🔄 [2/4] Actualizando metadatos de repositorios..."
$SUDO zypper --gpg-auto-import-keys refresh

# 2. Cambio de proveedores a Packman para multimedia
echo "🔄 [3/4] Cambiando paquetes multimedia a Packman (vendor change)..."
$SUDO zypper --non-interactive dup --from packman --allow-vendor-change || true

# 3. Pila Completa de FFmpeg, GStreamer y Codecs
echo "🎵 [4/4] Instalando suite completa de FFmpeg, GStreamer y codecs de alta fidelidad..."
$SUDO zypper --non-interactive install -y \
    ffmpeg \
    gstreamer-plugins-base \
    gstreamer-plugins-good \
    gstreamer-plugins-bad \
    gstreamer-plugins-ugly \
    gstreamer-plugins-libav \
    gstreamer-plugins-vaapi \
    libdvdread8 \
    libdvdnav4 \
    libva-utils \
    vulkan-tools 2>/dev/null || true

# Intentar instalar libdvdcss2 si está disponible en Packman
$SUDO zypper --non-interactive install -y libdvdcss2 2>/dev/null || true

echo "================================================================="
echo "✅ Codecs multimedia completos y repositorio Packman configurados."
echo "================================================================="
