#!/bin/bash
# fonts.sh - Instalación de Fuentes de Desarrollo (Optimizado) para Kubuntu (KDE Plasma)

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

# Eliminar archivos innecesarios (txt, md) que a veces vienen en los zips
find "$FONT_DIR" -name "*.txt" -delete
find "$FONT_DIR" -name "*.md" -delete

echo "ℹ️ Actualizando caché de fuentes del sistema..."
fc-cache -f

echo "✅ Fuentes de desarrollo instaladas y actualizadas correctamente."
