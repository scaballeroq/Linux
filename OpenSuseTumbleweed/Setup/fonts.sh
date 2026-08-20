#!/bin/bash
# fonts.sh - Instalación de Fuentes de Desarrollo (Nerd Fonts) para OpenSUSE Tumbleweed

set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

FONTS=("JetBrainsMono" "FiraCode" "CascadiaCode" "Meslo" "Hack")

echo "ℹ️ Verificando e instalando Nerd Fonts..."

for font in "${FONTS[@]}"; do
    if find "$FONT_DIR" -maxdepth 1 -name "${font}*.{ttf,otf}" -print -quit 2>/dev/null | grep -q .; then
        echo "✅ $font ya está instalada. Saltando..."
    else
        echo "⬇️ Descargando $font..."
        URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.zip"
        curl -L -o "/tmp/$font.zip" "$URL"
        
        echo "📦 Extrayendo $font..."
        unzip -q -o "/tmp/$font.zip" -d "$FONT_DIR"
        rm -f "/tmp/$font.zip"
    fi
done

# Eliminar archivos de texto innecesarios
find "$FONT_DIR" -name "*.txt" -delete
find "$FONT_DIR" -name "*.md" -delete

echo "ℹ️ Actualizando caché de fuentes..."
fc-cache -f

echo "✅ Fuentes Nerd Fonts instaladas y actualizadas correctamente."
