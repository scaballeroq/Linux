#!/bin/bash
# fonts.sh - Instalación de fuentes tipográficas para desarrollo (Nerd Fonts) en Manjaro Linux

set -euo pipefail

echo "🔤 Instalando fuentes de desarrollo y símbolos Nerd Fonts vía Pacman..."

sudo pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-firacode-nerd \
    ttf-cascadia-code-nerd \
    ttf-nerd-fonts-symbols \
    noto-fonts \
    noto-fonts-emoji \
    noto-fonts-cjk 2>/dev/null || sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd ttf-firacode-nerd noto-fonts || true

# Actualizar la caché de fuentes
echo "ℹ️ Regenerando caché de fuentes del sistema..."
fc-cache -fv > /dev/null || true

echo "✅ Tipografías de desarrollo instaladas correctamente."
