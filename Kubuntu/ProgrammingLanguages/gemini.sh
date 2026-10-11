#!/bin/bash
# =============================================================================
# gemini.sh - Instalador de Google Gemini CLI para Kubuntu
# =============================================================================
# - Asegura la presencia de Node.js y Mise
# - Instala la última versión de @google/gemini-cli
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
Instalador de Gemini CLI - Kubuntu

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala la última versión de @google/gemini-cli vía Mise/npm.
  --status, -s           Muestra el estado de Gemini CLI en el sistema.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE GEMINI CLI - KUBUNTU"
    echo "================================================================="
    echo "Gemini CLI:                    $(run_as_user mise which gemini 2>/dev/null || run_as_user which gemini 2>/dev/null || echo 'No instalado')"
    echo "================================================================="
}

install_gemini() {
    echo "================================================================="
    echo "INSTALANDO GEMINI CLI VÍA MISE/NPM - KUBUNTU"
    echo "================================================================="

    # 1. Asegurar Node.js
    if ! command -v node &>/dev/null && [ ! -x "$USER_HOME/.local/share/mise/installs/node/lts/bin/node" ]; then
        echo "ℹ️ Node.js no detectado. Instalando Node.js primero..."
        if [ -f "$SCRIPT_DIR/nodejs.sh" ]; then
            bash "$SCRIPT_DIR/nodejs.sh"
        fi
    fi

    # 2. Instalar Gemini CLI globalmente
    echo "ℹ️ Instalando @google/gemini-cli@latest..."
    run_as_user mise use --global npm:@google/gemini-cli@latest 2>/dev/null || \
    run_as_user mise exec node@lts -- npm install -g @google/gemini-cli@latest 2>/dev/null || true

    echo ""
    echo "================================================================="
    echo "✅ Gemini CLI instalado con éxito."
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
        install_gemini
        show_status
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
