#!/bin/bash
# fonts.sh - Instalación de Fuentes de Desarrollo (Nerd Fonts) para Soplos Linux Tyson

set -euo pipefail

# Directorio de destino
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Lista de Nerd Fonts a instalar
FONTS=("JetBrainsMono" "FiraCode" "CascadiaCode" "Meslo" "Hack")

echo "ℹ️ Verificando e instalando Nerd Fonts..."

for font in "${FONTS[@]}"; do
    # Verificación robusta: buscar archivos .ttf o .otf de la fuente
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

# Eliminar archivos innecesarios (txt, md)
find "$FONT_DIR" -name "*.txt" -delete 2>/dev/null || true
find "$FONT_DIR" -name "*.md" -delete 2>/dev/null || true

echo "ℹ️ Actualizando caché de fuentes..."
fc-cache -f

echo "✅ Fuentes instaladas y actualizadas correctamente en Soplos Linux Tyson."
