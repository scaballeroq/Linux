#!/bin/bash
# ==============================================================================
# fastfetch.sh - Instalación y configuración de Fastfetch para openSUSE Tumbleweed
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
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

echo "================================================================="
echo "ℹ️ Instalando Fastfetch vía Zypper..."
echo "================================================================="
$SUDO zypper --non-interactive install -y fastfetch 2>/dev/null || true

# Crear directorio de configuración para el usuario real
CONFIG_DIR="$USER_HOME/.config/fastfetch"
run_as_user mkdir -p "$CONFIG_DIR"

# Copiar configuración personalizada
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.jsonc" ]; then
    run_as_user cp "$SCRIPT_DIR/config.jsonc" "$CONFIG_DIR/config.jsonc"
    echo "✅ Configuración personalizada aplicada en ~/.config/fastfetch/config.jsonc"
fi

echo "================================================================="
echo "✅ Fastfetch instalado y configurado con éxito."
echo "💡 Ejecuta 'fastfetch' para probarlo."
echo "================================================================="
run_as_user fastfetch 2>/dev/null || true
