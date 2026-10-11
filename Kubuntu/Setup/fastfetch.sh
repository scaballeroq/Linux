#!/bin/bash
# =============================================================================
# fastfetch.sh - Instalación y Configuración de Fastfetch para Kubuntu
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
Instalador y Configurador de Fastfetch - Kubuntu

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala Fastfetch (si no está presente) y aplica la configuración personalizada.
  --status, -s           Muestra la versión de Fastfetch y la ruta del archivo de configuración activo.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE FASTFETCH - KUBUNTU"
    echo "================================================================="
    echo "Fastfetch Binario:             $(command -v fastfetch 2>/dev/null || echo 'No instalado')"
    echo "Versión Fastfetch:             $(fastfetch --version 2>/dev/null || echo 'n/a')"
    echo "Configuración de Usuario:      $USER_HOME/.config/fastfetch/config.jsonc"
    echo "Configuración existente:       $(if [ -f "$USER_HOME/.config/fastfetch/config.jsonc" ]; then echo 'Sí'; else echo 'No'; fi)"
    echo "================================================================="
    if command -v fastfetch &>/dev/null && [ -f "$USER_HOME/.config/fastfetch/config.jsonc" ]; then
        echo ""
        run_as_user fastfetch
    fi
}

install_and_configure() {
    echo "ℹ️ Verificando instalación de Fastfetch..."
    if ! command -v fastfetch &>/dev/null; then
        echo "Instalando Fastfetch vía APT..."
        $SUDO apt update
        $SUDO apt install -y fastfetch
    fi

    # Asegurar directorio de configuración para el usuario real
    run_as_user mkdir -p "$USER_HOME/.config/fastfetch"

    # Copiar configuración personalizada
    if [ -f "$SCRIPT_DIR/config.jsonc" ]; then
        echo "ℹ️ Aplicando configuración personalizada ($SCRIPT_DIR/config.jsonc)..."
        run_as_user cp "$SCRIPT_DIR/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc"
    elif [ -f "$SCRIPT_DIR/Setup/config.jsonc" ]; then
        echo "ℹ️ Aplicando configuración personalizada ($SCRIPT_DIR/Setup/config.jsonc)..."
        run_as_user cp "$SCRIPT_DIR/Setup/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc"
    fi

    echo "✅ Fastfetch configurado correctamente para '$REAL_USER'."
    echo ""
    run_as_user fastfetch
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
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
