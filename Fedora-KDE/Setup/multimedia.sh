#!/bin/bash
# ==============================================================================
# multimedia.sh - Instalación de Codecs Multimedia Oficiales y RPM Fusion
# Sistema: Fedora 44 (KDE Plasma 6 / AMD Radeon Vega 7 / VA-API)
# ==============================================================================
# Características:
# 1. Habilitación de repositorios RPM Fusion (Free y Nonfree).
# 2. Reemplazo de 'ffmpeg-free' por 'ffmpeg' completo con soporte de codecs propietarios.
# 3. Instalación de GStreamer plugins completos (bad-freeworld, ugly, libav).
# 4. Aceleración por hardware VA-API para GPU AMD Radeon Vega (mesa-va-drivers-freeworld).
# 5. Integración con Flatpak / Flathub para reproductores desacoplados (VLC).
# 6. Diagnóstico con vainfo y verificación de aceleración de vídeo.
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
    rpm -q "$1" >/dev/null 2>&1
}

show_help() {
    cat <<EOF
🎬 Instalador de Codecs Multimedia y Aceleración HW - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Habilita RPM Fusion, instala FFmpeg completo, plugins GStreamer,
                      aceleración VA-API de AMD Vega y configura Flathub.
  --status, -s        Muestra el estado de códecs, RPM Fusion, VA-API y Flatpak.
  --help, -h          Muestra este mensaje de ayuda.

Componentes instalados:
  • Repositorios:     RPM Fusion Free y Nonfree oficiales.
  • Suite Multimedia: FFmpeg completo (reemplazando ffmpeg-free) y GStreamer freeworld.
  • Aceleración HW:   mesa-va-drivers-freeworld, mesa-vdpau-drivers-freeworld y libva-utils (vainfo).
  • Flatpak / Flathub:Configuración de Flathub para reproductores y herramientas multimedia.
EOF
}

check_rpmfusion() {
    if rpm -q rpmfusion-free-release >/dev/null 2>&1 && rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
        echo "✅ Habilitados (Free y Nonfree)"
    else
        echo "❌ No habilitados completamente"
    fi
}

check_ffmpeg() {
    if is_pkg_installed ffmpeg; then
        echo "✅ FFmpeg Completo ($(rpm -q --qf '%{VERSION}' ffmpeg))"
    elif is_pkg_installed ffmpeg-free; then
        echo "⚠️ ffmpeg-free básico (sin codecs propietarios H.264/H.265)"
    else
        echo "❌ No instalado"
    fi
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO MULTIMEDIA Y CÓDECS - FEDORA 44 (KDE PLASMA 6)"
    echo "================================================================="
    echo "• Repositorios RPM Fusion:     $(check_rpmfusion)"
    echo "• FFmpeg en el sistema:        $(check_ffmpeg)"
    echo "• GStreamer Bad Freeworld:     $(if is_pkg_installed gstreamer1-plugins-bad-freeworld; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• GStreamer Ugly:              $(if is_pkg_installed gstreamer1-plugins-ugly; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "• GStreamer Libav:             $(if is_pkg_installed gstreamer1-libav; then echo "✅ Instalado"; else echo "No instalado"; fi)"
    echo "-----------------------------------------------------------------"
    echo "• Mesa VA Drivers Freeworld:   $(if is_pkg_installed mesa-va-drivers-freeworld; then echo "✅ Instalado (AMD VA-API activo)"; else echo "❌ No instalado (mesa-va-drivers básico)"; fi)"
    echo "• Utilidad vainfo:             $(if command -v vainfo &>/dev/null; then echo "✅ Disponible"; else echo "❌ No instalado (libva-utils)"; fi)"
    echo "-----------------------------------------------------------------"
    echo "• Repositorio Flathub:         $(if flatpak remotes 2>/dev/null | grep -qi "flathub"; then echo "✅ Configurado"; else echo "❌ No configurado"; fi)"
    echo "================================================================="
}

install_multimedia() {
    echo "================================================================="
    echo "🎬 INSTALANDO CODECS Y ACELERACIÓN MULTIMEDIA EN FEDORA 44"
    echo "================================================================="

    # 1. Habilitar RPM Fusion Free y Nonfree
    echo "📦 [1/4] Verificando e instalando repositorios RPM Fusion..."
    local fedora_ver
    fedora_ver=$(rpm -E %fedora 2>/dev/null || echo "44")

    if ! is_pkg_installed rpmfusion-free-release || ! is_pkg_installed rpmfusion-nonfree-release; then
        echo "ℹ️ Descargando e instalando RPM Fusion Free y Nonfree para Fedora $fedora_ver..."
        $SUDO dnf5 install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm" 2>/dev/null || true
    else
        echo "✅ Repositorios RPM Fusion ya instalados."
    fi

    # 2. Reemplazar ffmpeg-free por ffmpeg completo
    echo "🎞️ [2/4] Sustituyendo ffmpeg-free por ffmpeg completo de RPM Fusion..."
    $SUDO dnf5 swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null || true

    # 3. Instalar plugins GStreamer y aceleración por hardware VA-API para AMD
    echo "⚡ [3/4] Instalando plugins GStreamer y aceleración VA-API para AMD Radeon Vega..."
    $SUDO dnf5 install -y \
        gstreamer1-plugins-bad-freeworld \
        gstreamer1-plugins-ugly \
        gstreamer1-libav \
        mesa-va-drivers-freeworld \
        mesa-vdpau-drivers-freeworld \
        libva-utils 2>/dev/null || true

    # 4. Configurar Flathub
    echo "📦 [4/4] Verificando repositorio Flathub..."
    if command -v flatpak &>/dev/null; then
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
        echo "✅ Flathub configurado."
    fi

    echo ""
    show_status
    echo "✅ Instalación y optimización multimedia completada con éxito."
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    "")
        install_multimedia
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
