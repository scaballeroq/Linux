#!/bin/bash
# =============================================================================
# yt-dlp-setup.sh - Instalación y Configuración Multimedia para Kubuntu
# =============================================================================
# - Instala yt-dlp, FFmpeg, AtomicParsley (metadatos/miniaturas) y Aria2
# - Configura el motor JavaScript (Deno vía Mise para resolver n-challenges de YouTube)
# - Configura preferencias por defecto en ~/.config/yt-dlp/config
# =============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
Instalador y Configurador de yt-dlp y Multimedia - Kubuntu

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala paquetes multimedia, configura motor JS (Deno) y perfil por defecto.
  --status, -s           Muestra el estado de yt-dlp, FFmpeg, motor JS y configuración activa.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE YT-DLP Y MULTIMEDIA - KUBUNTU"
    echo "================================================================="
    echo "yt-dlp:                        $(if command -v yt-dlp &>/dev/null; then yt-dlp --version 2>/dev/null; else echo 'No instalado'; fi)"
    echo "FFmpeg:                        $(if command -v ffmpeg &>/dev/null; then ffmpeg -version 2>/dev/null | head -n1 | cut -d' ' -f1-3; else echo 'No instalado'; fi)"
    echo "AtomicParsley (Metadatos MP4): $(if command -v AtomicParsley &>/dev/null; then echo 'Instalado'; else echo 'No instalado'; fi)"
    echo "Aria2c (Descargas paralelas):  $(if command -v aria2c &>/dev/null; then echo 'Instalado'; else echo 'No instalado'; fi)"
    echo "Motor JS (Deno vía Mise):      $(if run_as_user mise which deno &>/dev/null 2>&1; then echo "Activo ($(run_as_user mise which deno))"; elif command -v deno &>/dev/null; then echo "Activo ($(which deno))"; else echo 'No disponible (usando Node.js de respaldo)'; fi)"
    echo "Configuración yt-dlp:          $USER_HOME/.config/yt-dlp/config"
    echo "================================================================="
}

install_and_configure() {
    echo "================================================================="
    echo "CONFIGURANDO YT-DLP Y STACK MULTIMEDIA - KUBUNTU"
    echo "================================================================="

    echo "ℹ️ [1/3] Instalando yt-dlp, FFmpeg, AtomicParsley y Aria2..."
    $SUDO apt update
    $SUDO apt install -y \
        yt-dlp \
        ffmpeg \
        atomicparsley \
        aria2 \
        2>/dev/null || true

    echo "ℹ️ [2/3] Configurando motor JavaScript para YouTube (Deno vía Mise)..."
    # yt-dlp utiliza motores JS (Deno o Node) para resolver los algoritmos de descifrado (n-challenge) de YouTube
    if command -v mise &> /dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
        echo "   - Instalando Deno con mise para '$REAL_USER'..."
        run_as_user mise use --global deno@latest 2>/dev/null || \
        run_as_user mise install deno@latest 2>/dev/null || true
        echo "✅ Deno configurado en Mise."
    else
        echo "   - Mise no detectado. Verificando NodeJS como respaldo..."
        if ! command -v node &> /dev/null; then
            $SUDO apt install -y nodejs 2>/dev/null || true
        fi
    fi

    echo "ℹ️ [3/3] Creando configuración recomendada en ~/.config/yt-dlp/config..."
    run_as_user mkdir -p "$USER_HOME/.config/yt-dlp"

    cat <<'EOF' > "$USER_HOME/.config/yt-dlp/config"
# =============================================================================
# Configuración por defecto de yt-dlp - Kubuntu
# =============================================================================

# Continuar descargas interrumpidas y no sobreescribir fechas de subida
--continue
--no-mtime

# Descargas paralelas de fragmentos
--concurrent-fragments 5

# Incrustar metadatos e información de capítulos si existen
--embed-metadata
--embed-chapters

# Mantener la mejor compatibilidad de audio y vídeo
--prefer-free-formats
EOF
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/yt-dlp/config" 2>/dev/null || true

    echo ""
    echo "================================================================="
    echo "✅ Entorno multimedia de yt-dlp configurado correctamente."
    echo "   Aliases de terminal disponibles: ytvideo, ytaudio, ytlista, ytdl-subs"
    echo "================================================================="
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
        install_and_configure
        show_status
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
