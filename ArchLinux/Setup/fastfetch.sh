#!/bin/bash
# fastfetch.sh - Instalación y configuración de Fastfetch para Arch Linux

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "⚡ Instalando Fastfetch..."

sudo pacman -S --noconfirm fastfetch

echo "ℹ️ Configurando Fastfetch..."
mkdir -p ~/.config/fastfetch
cp "$SCRIPT_DIR/config.jsonc" ~/.config/fastfetch/config.jsonc

echo "✅ Fastfetch configurado correctamente"
