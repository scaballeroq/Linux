#!/bin/bash
# ==============================================================================
# fonts.sh - Instalación de Fuentes de Desarrollo (Nerd Fonts) para Fedora 44
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no esta disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecucion con sudo
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

FONT_DIR="$USER_HOME/.local/share/fonts"
run_as_user mkdir -p "$FONT_DIR"

FONTS=("JetBrainsMono" "FiraCode" "CascadiaCode" "Meslo" "Hack")

echo "================================================================="
echo "🔤 Verificando e instalando Nerd Fonts para $REAL_USER..."
echo "================================================================="

for font in "${FONTS[@]}"; do
    if [ ! -d "$FONT_DIR/$font" ] && ! ls "$FONT_DIR/$font"* &>/dev/null; then
        echo "⬇️ Descargando $font Nerd Font..."
        run_as_user mkdir -p "$FONT_DIR/$font"
        curl -fLo "/tmp/${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
        run_as_user unzip -qo "/tmp/${font}.zip" -d "$FONT_DIR/$font"
        rm -f "/tmp/${font}.zip"
        echo "  ✅ $font instalada."
    else
        echo "  ✅ $font ya está instalada."
    fi
done

# Eliminar archivos innecesarios de documentación dentro del directorio de fuentes
run_as_user find "$FONT_DIR" -name "*.txt" -delete 2>/dev/null || true
run_as_user find "$FONT_DIR" -name "*.md" -delete 2>/dev/null || true

echo "ℹ️ Actualizando caché de fuentes del sistema..."
run_as_user fc-cache -f "$FONT_DIR"

echo "================================================================="
echo "✅ Fuentes instaladas y actualizadas correctamente."
echo "================================================================="
