#!/bin/bash
# fonts.sh - Instalación de Nerd Fonts para Arch Linux

set -e

echo "🔤 Instalando Nerd Fonts..."

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

FONTS=(
    "JetBrainsMono"
    "FiraCode"
    "CascadiaCode"
    "Meslo"
    "Hack"
)

for font in "${FONTS[@]}"; do
    echo "ℹ️ Descargando $font..."
    case $font in
        "JetBrainsMono")
            REPO="JetBrains/JetBrainsMono"
            ;;
        "FiraCode")
            REPO="tonsky/FiraCode"
            ;;
        "CascadiaCode")
            REPO="microsoft/cascadia-code"
            ;;
        "Meslo")
            REPO="romkatv/powerlevel10k-media"
            ;;
        "Hack")
            REPO="source-foundry/Hack"
            ;;
    esac

    if [ "$font" = "Meslo" ]; then
        wget -q "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf" -P "$FONT_DIR"
        wget -q "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf" -P "$FONT_DIR"
        wget -q "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf" -P "$FONT_DIR"
        wget -q "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20BoldItalic.ttf" -P "$FONT_DIR"
    else
        TEMP_DIR=$(mktemp -d)
        wget -q "https://github.com/$REPO/releases/latest/download/$font.zip" -O "$TEMP_DIR/$font.zip" || \
        wget -q "https://github.com/$REPO/releases/download/$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep -oP '"tag_name": "\K[^"]*')/$font.zip" -O "$TEMP_DIR/$font.zip" || true

        if [ -f "$TEMP_DIR/$font.zip" ]; then
            unzip -q "$TEMP_DIR/$font.zip" -d "$TEMP_DIR"
            find "$TEMP_DIR" -name "*.ttf" -o -name "*.otf" | xargs -I {} mv {} "$FONT_DIR/"
            rm -rf "$TEMP_DIR"
        fi
    fi
done

# Limpiar archivos de texto en el directorio de fuentes
find "$FONT_DIR" -name "*.txt" -delete
find "$FONT_DIR" -name "*.md" -delete
find "$FONT_DIR" -name "LICENSE" -delete

# Actualizar caché de fuentes
fc-cache -fv

echo "✅ Nerd Fonts instaladas correctamente"
