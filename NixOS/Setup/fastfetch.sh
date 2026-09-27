#!/usr/bin/env bash
# ==============================================================================
# fastfetch.sh - Instalación y Configuración Estética de Fastfetch en NixOS
# ==============================================================================

set -euo pipefail

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_CONFIG_DIR="$USER_HOME/.config/fastfetch"
USER_CONFIG_FILE="$USER_CONFIG_DIR/config.jsonc"

get_theme_path() {
    local theme_name="$1"
    case "$theme_name" in
        nix|nixos|default)
            if [ -f "$SCRIPT_DIR/config-nix.jsonc" ]; then
                echo "$SCRIPT_DIR/config-nix.jsonc"
            else
                echo "$SCRIPT_DIR/config.jsonc"
            fi
            ;;
        compact|fastcat|minimal)
            echo "$SCRIPT_DIR/config-compact.jsonc"
            ;;
        *)
            if [ -f "$SCRIPT_DIR/config-${theme_name}.jsonc" ]; then
                echo "$SCRIPT_DIR/config-${theme_name}.jsonc"
            elif [ -f "$theme_name" ]; then
                echo "$theme_name"
            else
                echo ""
            fi
            ;;
    esac
}

show_help() {
    cat <<EOF
❄️ Gestor de Configuración Fastfetch - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)        Instala/despliega la configuración predeterminada de NixOS ('nix').
  --theme, -t <nombre>    Aplica un tema específico ('nix' o 'compact').
  --list-themes           Lista los temas disponibles en el repositorio.
  --status, -s            Muestra el estado de la configuración instalada.
  --run, -r               Ejecuta fastfetch con la configuración actual.
  --force, -f             Sobrescribe la configuración existente sin generar backup.
  --help, -h              Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE FASTFETCH - NIXOS"
    echo "================================================================="
    echo -n "• Binario fastfetch: "
    if command -v fastfetch &>/dev/null; then
        echo "✅ $(fastfetch --version 2>/dev/null || echo 'instalado')"
    else
        echo "❌ No encontrado en PATH"
    fi

    echo -n "• Archivo de configuración: "
    if [ -f "$USER_CONFIG_FILE" ]; then
        echo "✅ Presente ($USER_CONFIG_FILE)"
    else
        echo "ℹ️ No configurado en ~/.config/fastfetch/"
    fi
    echo "================================================================="
}

apply_theme() {
    local theme_input="${1:-nix}"
    local force_flag="${2:-false}"
    local theme_path

    theme_path=$(get_theme_path "$theme_input")
    if [ -z "$theme_path" ] || [ ! -f "$theme_path" ]; then
        echo "❌ Error: El tema '$theme_input' no existe."
        exit 1
    fi

    mkdir -p "$USER_CONFIG_DIR"

    if [ -f "$USER_CONFIG_FILE" ] && [ "$force_flag" != "true" ]; then
        if ! cmp -s "$theme_path" "$USER_CONFIG_FILE"; then
            cp "$USER_CONFIG_FILE" "${USER_CONFIG_FILE}.bak-$(date +%Y%m%d-%H%M%S)"
        fi
    fi

    cp "$theme_path" "$USER_CONFIG_FILE"
    chown -R "$REAL_USER:" "$USER_CONFIG_DIR" 2>/dev/null || true
    echo "✅ Tema Fastfetch '$theme_input' aplicado correctamente en $USER_CONFIG_FILE."
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --run|-r|run)
        if command -v fastfetch &>/dev/null; then
            fastfetch
        else
            echo "❌ Fastfetch no está instalado."
        fi
        exit 0
        ;;
    --list-themes)
        echo "Temas disponibles: nix, compact"
        exit 0
        ;;
    --theme|-t)
        shift
        apply_theme "${1:-nix}" false
        exit 0
        ;;
    --force|-f)
        apply_theme "nix" true
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        apply_theme "nix" false
        ;;
esac
