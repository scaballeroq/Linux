#!/usr/bin/env bash
# ==============================================================================
# yt-dlp-setup.sh - Instalación, Optimización y Diagnóstico de yt-dlp y FFmpeg en NixOS
# ==============================================================================

set -euo pipefail

# Detección de usuario
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

CONFIG_DIR="$USER_HOME/.config/yt-dlp"
CONFIG_FILE="$CONFIG_DIR/config"

show_help() {
    cat <<EOF
🎥 Gestor y Optimizador de yt-dlp - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Genera la configuración optimizada ~/.config/yt-dlp/config.
  --status, -s        Comprueba el estado de yt-dlp, FFmpeg y aria2.
  --update, -u        Actualiza yt-dlp.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE YT-DLP Y MULTIMEDIA - NIXOS"
    echo "================================================================="
    echo -n "• yt-dlp: "
    if command -v yt-dlp &>/dev/null; then
        echo "✅ $(yt-dlp --version)"
    else
        echo "❌ No instalado"
    fi

    echo -n "• FFmpeg: "
    if command -v ffmpeg &>/dev/null; then
        echo "✅ Presente"
    else
        echo "❌ No instalado"
    fi

    echo -n "• Descargador aria2c: "
    if command -v aria2c &>/dev/null; then
        echo "✅ Presente"
    else
        echo "ℹ️ No instalado"
    fi

    echo -n "• Archivo de configuración: "
    if [ -f "$CONFIG_FILE" ]; then
        echo "✅ Presente ($CONFIG_FILE)"
    else
        echo "ℹ️ No generado aún"
    fi
    echo "================================================================="
}

setup_config() {
    mkdir -p "$CONFIG_DIR"

    echo "ℹ️ Escribiendo configuración optimizada en $CONFIG_FILE..."
    cat << 'EOF' > "$CONFIG_FILE"
# =============================================================================
# YT-DLP CONFIGURATION - NIXOS (KDE Plasma 6)
# =============================================================================

# Directorio de descargas predeterminado
-P "~/Downloads/Media"

# Formato preferido: mejor calidad de video y audio combinada en MP4 / MKV
-f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv*+ba/b"
--merge-output-format mp4

# Metadatos y carátula integrados
--embed-thumbnail
--embed-metadata
--embed-chapters
--embed-subs
--sub-langs "es.*,en.*"

# Rendimiento y reintentos
--concurrent-fragments 4
--retries 10
--fragment-retries 10

# Nombres legibles y ordenados
-o "%(title)s [%(id)s].%(ext)s"
EOF

    chown -R "$REAL_USER:" "$CONFIG_DIR" 2>/dev/null || true
    echo "✅ Configuración de yt-dlp generada correctamente."
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --update|-u|update)
        if command -v yt-dlp &>/dev/null; then
            yt-dlp -U 2>/dev/null || echo "ℹ️ En NixOS, las actualizaciones se gestionan mediante 'nix flake update' o nixpkgs."
        fi
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        setup_config
        check_status
        ;;
esac
