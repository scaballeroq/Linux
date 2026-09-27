#!/usr/bin/env bash
# ==============================================================================
# multimedia.sh - Diagnóstico de Códecs y Aceleración de Hardware en NixOS
# ==============================================================================

set -euo pipefail

show_help() {
    cat <<EOF
🎬 Diagnóstico Multimedia y Aceleración por Hardware - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica códecs y aceleración por hardware.
  --status, -s        Comprueba el estado de VA-API, VDPAU y FFmpeg.
  --help, -h          Muestra este mensaje de ayuda.

Nota:
  En NixOS, los controladores y códecs se definen en modules/hardware.nix (hardware.graphics).
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO MULTIMEDIA Y CODECS (NIXOS)"
    echo "================================================================="

    echo -n "• Binario FFmpeg: "
    if command -v ffmpeg &>/dev/null; then
        echo "✅ $(ffmpeg -version 2>/dev/null | head -n1)"
    else
        echo "❌ No instalado"
    fi

    echo -n "• Aceleración VA-API (vainfo): "
    if command -v vainfo &>/dev/null; then
        vainfo --display drm 2>&1 | grep -E 'Driver version|VAProfile' | head -n 3 || echo "⚠️ vainfo reportó errores"
    else
        echo "ℹ️ vainfo no disponible en PATH (instalar libva-utils)"
    fi

    echo -n "• Reproductor VLC (Flatpak o Nativo): "
    if flatpak list 2>/dev/null | grep -qi "org.videolan.VLC"; then
        echo "✅ Presente vía Flatpak Flathub"
    elif command -v vlc &>/dev/null; then
        echo "✅ Presente nativo"
    else
        echo "❌ No instalado (instalar con just flatpak)"
    fi
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        check_status
        ;;
esac
