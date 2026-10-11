#!/bin/bash
# fonts.sh - Instalación de Fuentes de Desarrollo (Nerd Fonts) para CachyOS
# Incluye JetBrainsMono, FiraCode, CascadiaCode, Meslo, Hack e Inter Variable (DMS)

set -euo pipefail

echo "================================================================="
echo "🔤 Instalando fuentes de desarrollo y Nerd Fonts para CachyOS..."
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        SUDO=""
    fi
else
    SUDO=""
fi

# 1. Intentar instalar vía paquetes oficiales de CachyOS/Arch Linux (más rápido y limpio)
echo "📦 [1/3] Instalando paquetes de fuentes oficiales de CachyOS..."
$SUDO pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-firacode-nerd \
    ttf-cascadia-code-nerd \
    ttf-meslo-nerd \
    ttf-hack-nerd \
    inter-font 2>/dev/null || true

# 2. Descargar fuentes adicionales si faltara alguna
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

FONTS=("JetBrainsMono" "FiraCode" "CascadiaCode" "Meslo" "Hack")

echo "⬇️ [2/3] Verificando cobertura de Nerd Fonts en $FONT_DIR..."
for font in "${FONTS[@]}"; do
    if fc-list : family | grep -qi "$font Nerd Font" || ls "$FONT_DIR/$font"* &>/dev/null; then
        echo "  ✅ $font ya disponible en el sistema."
    else
        echo "  ⬇️ Descargando $font desde releases..."
        URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.zip"
        if curl -fsSL -o "/tmp/$font.zip" "$URL" 2>/dev/null; then
            unzip -q -o "/tmp/$font.zip" -d "$FONT_DIR"
            rm -f "/tmp/$font.zip"
            echo "  ✅ $font instalada."
        fi
    fi
done

# Eliminar metadatos innecesarios
find "$FONT_DIR" -name "*.txt" -delete 2>/dev/null || true
find "$FONT_DIR" -name "*.md" -delete 2>/dev/null || true

# 3. Actualizar caché de fuentes
echo "🔄 [3/3] Actualizando caché de fuentes del sistema..."
fc-cache -f

echo "================================================================="
echo "✅ Fuentes tipográficas instaladas y actualizadas correctamente:"
echo "  • Tipografía normal: Inter Variable (Recomendada para Dank Material Shell)"
echo "  • Tipografía código: JetBrainsMono / FiraCode Nerd Font"
echo "================================================================="
