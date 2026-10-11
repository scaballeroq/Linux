#!/bin/bash
# fastfetch.sh - Instalación y configuración de Fastfetch para CachyOS

set -euo pipefail

echo "ℹ️ Instalando Fastfetch vía Pacman..."
sudo pacman -S --needed --noconfirm fastfetch

# Asegurar directorio de configuración
mkdir -p "$HOME/.config/fastfetch"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copiar configuración local
if [ -f "$SCRIPT_DIR/config.jsonc" ]; then
    echo "ℹ️ Aplicando configuración personalizada desde $SCRIPT_DIR/config.jsonc..."
    cp "$SCRIPT_DIR/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
elif [ -f "Setup/config.jsonc" ]; then
    echo "ℹ️ Aplicando configuración personalizada desde Setup/config.jsonc..."
    cp Setup/config.jsonc "$HOME/.config/fastfetch/config.jsonc"
fi

echo "✅ Fastfetch instalado y configurado."
fastfetch
