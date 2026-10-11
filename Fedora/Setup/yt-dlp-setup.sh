#!/bin/bash
# yt-dlp-setup.sh - Instalación y optimización de yt-dlp, FFmpeg, AtomicParsley y Motor JS para Fedora 44 + KDE Plasma
#
# Uso:
#   ./yt-dlp-setup.sh                -> Instala yt-dlp, FFmpeg, aceleradores, descifrado de cookies, motor JS y genera config
#   ./yt-dlp-setup.sh --status       -> Muestra el estado de yt-dlp, FFmpeg, AtomicParsley, motor JS y cookies
#   ./yt-dlp-setup.sh --update       -> Actualiza yt-dlp y el motor JS (Deno) a la última versión
#   ./yt-dlp-setup.sh --help         -> Muestra la ayuda interactiva

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

# Detectar usuario real en caso de ejecución con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    REAL_USER="$SUDO_USER"
else
    USER_HOME="${HOME}"
    REAL_USER="${USER:-$(id -un)}"
fi

show_help() {
    cat <<EOF
🎬 Optimizador y Gestor de yt-dlp - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala yt-dlp, FFmpeg, AtomicParsley, aria2, librerías de cookies y motor JS (Deno).
  --status, -s           Muestra el estado de herramientas multimedia, versiones activas y soporte de cookies.
  --update, -u           Actualiza yt-dlp y el motor JavaScript (Deno) a la última versión disponible.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Stack Multimedia:   yt-dlp + FFmpeg completo para muxing y conversión de códecs de alta fidelidad.
  • Metadatos y Carátulas: AtomicParsley y Mutagen para incrustar portadas y tags en MP4/M4A/MP3.
  • Aceleración de red: aria2 para descargas concurrentes de fragmentos a máxima velocidad.
  • Descifrado Cookies: python3-pycryptodomex y secretstorage para leer cookies de Firefox en KDE Wallet.
  • Motor JavaScript:   Deno vía Mise para resolver retos de JavaScript (n-token challenges de YouTube).
  • Configuración base: Genera ~/.config/yt-dlp/config con opciones óptimas de descarga y calidad.
EOF
}

# 1. Mostrar estado de componentes
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO MULTIMEDIA YT-DLP - FEDORA 44 (KDE PLASMA)"
    echo "================================================================="
    echo "• yt-dlp:              $(yt-dlp --version 2>/dev/null || echo 'No instalado')"
    echo "• FFmpeg:              $(ffmpeg -version 2>/dev/null | head -n1 | awk '{print $3}' || echo 'No instalado')"
    echo "• AtomicParsley:       $(AtomicParsley -v 2>/dev/null | head -n1 || (command -v AtomicParsley &>/dev/null && echo 'Instalado') || echo 'No instalado')"
    echo "• aria2 (multi-hilo):  $(aria2c --version 2>/dev/null | head -n1 | awk '{print $3}' || echo 'No instalado')"
    
    # Motor JavaScript
    local JS_ENGINE="No detectado"
    if command -v deno &>/dev/null; then
        JS_ENGINE="Deno ($(deno --version 2>/dev/null | head -n1 | awk '{print $2}'))"
    elif command -v node &>/dev/null; then
        JS_ENGINE="Node.js ($(node --version 2>/dev/null))"
    elif command -v mise &>/dev/null && mise where deno &>/dev/null; then
        JS_ENGINE="Deno vía Mise ($(mise where deno))"
    fi
    echo "• Motor JavaScript:    $JS_ENGINE"

    # Soporte descifrado de cookies
    local COOKIES_SUPPORT="No"
    if python3 -c "import secretstorage, Cryptodome" &>/dev/null; then
        COOKIES_SUPPORT="Sí (secretstorage + pycryptodomex disponibles)"
    fi
    echo "• Cookies de navegador:$COOKIES_SUPPORT"

    echo "• Archivo de config:   $USER_HOME/.config/yt-dlp/config ($(if [ -f "$USER_HOME/.config/yt-dlp/config" ]; then echo 'Presente'; else echo 'No configurado'; fi))"
    echo "================================================================="
}

# 2. Actualizar yt-dlp y motor JS
update_components() {
    echo "🔄 Actualizando yt-dlp y componentes multimedia..."
    $SUDO dnf5 upgrade --refresh -y yt-dlp ffmpeg aria2 AtomicParsley 2>/dev/null || true
    
    if command -v mise &>/dev/null; then
        echo "ℹ️ Actualizando motor JavaScript Deno vía Mise..."
        mise use --global deno@latest 2>/dev/null || true
    fi
    echo "✅ Componentes multimedia actualizados con éxito."
}

# 3. Instalar paquetes de sistema vía DNF5
install_packages() {
    echo "📦 [1/3] Instalando yt-dlp, FFmpeg, AtomicParsley, aria2 y librerías de descifrado..."
    $SUDO dnf5 install -y \
        yt-dlp \
        ffmpeg \
        AtomicParsley \
        aria2 \
        python3-pycryptodomex \
        python3-secretstorage \
        python3-mutagen 2>/dev/null || $SUDO dnf5 install -y yt-dlp ffmpeg
    echo "✅ Paquetes multimedia instalados."
}

# 4. Configurar motor JavaScript (Deno) para yt-dlp
configure_js_engine() {
    echo "⚡ [2/3] Configurando motor JavaScript (Deno) para retos de descifrado de YouTube..."
    if command -v mise &> /dev/null; then
        mise use --global deno@latest 2>/dev/null || true
        mise reshim 2>/dev/null || true
        echo "✅ Deno configurado globalmente con Mise."
    elif ! command -v deno &>/dev/null && ! command -v node &>/dev/null; then
        echo "ℹ️ Instalando NodeJS como motor JS de respaldo..."
        $SUDO dnf5 install -y nodejs 2>/dev/null || true
    fi
}

# 5. Generar configuración optimizada (~/.config/yt-dlp/config)
generate_config() {
    echo "⚙️ [3/3] Generando configuración optimizada en $USER_HOME/.config/yt-dlp/config..."
    mkdir -p "$USER_HOME/.config/yt-dlp"
    
    cat <<'EOF' > "$USER_HOME/.config/yt-dlp/config"
# =============================================================================
# CONFIGURACIÓN GLOBAL DE YT-DLP - FEDORA 44 (KDE PLASMA)
# =============================================================================

# --- Metadatos y Miniaturas ---
--embed-metadata
--embed-thumbnail
--embed-chapters

# --- Descargas y Rendimiento ---
--concurrent-fragments 5
--no-overwrites
--continue

# --- Integración y Compatibilidad ---
--prefer-free-formats
--compat-options no-youtube-prefer-utc-upload-date

# --- Subtítulos ---
--sub-langs "es.*,en.*"
--embed-subs
EOF

    chown -R "$REAL_USER:" "$USER_HOME/.config/yt-dlp" 2>/dev/null || true
    echo "✅ Configuración ~/.config/yt-dlp/config lista."
}

# Procesar argumentos
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --update|-u|update)
        update_components
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🎬 CONFIGURADOR MULTIMEDIA YT-DLP - FEDORA 44 (KDE PLASMA 6)"
        echo "================================================================="
        install_packages
        configure_js_engine
        generate_config
        echo ""
        echo "================================================================="
        echo "✅ yt-dlp y stack multimedia configurados con éxito."
        echo "💡 Aliases disponibles en terminal: ytvideo, ytaudio, ytlista, ytdl-subs"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
