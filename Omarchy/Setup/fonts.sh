#!/bin/bash
# ==============================================================================
# FONTS SETUP (fonts.sh) - Omarchy (Arch Linux + Hyprland)
# Instalación de Nerd Fonts (JetBrainsMono, FiraCode, CascadiaCode, Meslo, Hack)
# ==============================================================================

set -euo pipefail

echo "🔤 Instalando Nerd Fonts recomendadas para Omarchy..."

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# 1. Intentar instalar paquetes oficiales de pacman primero (rápido y limpio)
if sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd ttf-fira-code ttf-cascadia-code-nerd 2>/dev/null; then
    echo "✅ Fuentes base instaladas desde repositorios oficiales."
fi

# 2. Descargar fuentes adicionales si faltan (Meslo, Hack)
FONTS=(
    "JetBrainsMono"
    "FiraCode"
    "CascadiaCode"
    "Meslo"
    "Hack"
)

for font in "${FONTS[@]}"; do
    if [ ! -d "$FONT_DIR/$font" ] && ! fc-list : family | grep -qi "$font"; then
        echo "ℹ️ Descargando e instalando $font Nerd Font..."
        TEMP_DIR=$(mktemp -d)
        if curl -fsSL -o "$TEMP_DIR/$font.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.zip" 2>/dev/null; then
            mkdir -p "$FONT_DIR/$font"
            unzip -qo "$TEMP_DIR/$font.zip" -d "$FONT_DIR/$font/"
            find "$FONT_DIR/$font" -type f ! -name "*.ttf" ! -name "*.otf" -delete
            echo "  ✔️ $font instalado en $FONT_DIR/$font"
        else
            echo "  ⚠️ No se pudo descargar $font desde GitHub releases, omitiendo..."
        fi
        rm -rf "$TEMP_DIR"
    else
        echo "✔️ $font ya se encuentra disponible."
    fi
done

# 3. Limpiar y reconstruir caché de fuentes
echo "🔄 Actualizando caché de fuentes de fontconfig..."
fc-cache -fv > /dev/null 2>&1 || true

echo "✅ Fuentes de desarrollo configuradas correctamente."
