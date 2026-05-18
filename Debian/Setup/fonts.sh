#!/bin/bash
# fonts.sh - Instalación de Fuentes de Desarrollo (Optimizado) para Debian

set -e

# Directorio de destino
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Lista de Nerd Fonts a instalar
FONTS=("JetBrainsMono" "FiraCode" "CascadiaCode" "Meslo" "Hack")

echo "ℹ️ Verificando e instalando Nerd Fonts..."

for font in "${FONTS[@]}"; do
    if ls "$FONT_DIR/$font"* &>/dev/null; then
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

# Eliminar archivos innecesarios (txt, md) que a veces vienen en los zips
find "$FONT_DIR" -name "*.txt" -delete
find "$FONT_DIR" -name "*.md" -delete

echo "ℹ️ Actualizando caché de fuentes..."
fc-cache -f

echo "✅ Fuentes instaladas y actualizadas correctamente."
