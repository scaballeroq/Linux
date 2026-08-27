#!/bin/bash
# fonts.sh - Instalacion de Fuentes de Desarrollo (Nerd Fonts) para Fedora 44

set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

FONTS=("JetBrainsMono" "FiraCode" "CascadiaCode" "Meslo" "Hack")

echo "Verificando e instalando Nerd Fonts..."

for font in "${FONTS[@]}"; do
    if [ ! -d "$FONT_DIR/$font" ]; then
        echo "Descargando $font Nerd Font..."
        mkdir -p "$FONT_DIR/$font"
        curl -fLo "/tmp/${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
        unzip -qo "/tmp/${font}.zip" -d "$FONT_DIR/$font"
        rm -f "/tmp/${font}.zip"
        echo "$font instalada."
    else
        echo "$font ya esta instalada."
    fi
done

echo "Actualizando cache de fuentes del sistema..."
fc-cache -f "$FONT_DIR"

echo "Todas las fuentes se han instalado y configurado correctamente."
