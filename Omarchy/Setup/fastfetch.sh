#!/bin/bash
# fastfetch.sh - Instalación y configuración de Fastfetch para Omarchy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "⚡ Verificando instalación de Fastfetch..."
sudo pacman -S --needed --noconfirm fastfetch

mkdir -p "$HOME/.config/fastfetch"

# Respetar configuración nativa de Omarchy si ya existe
if [ -f "$HOME/.config/fastfetch/config.jsonc" ]; then
    echo "ℹ️ Se detectó una configuración previa de Fastfetch en ~/.config/fastfetch/config.jsonc."
    echo "💡 Omarchy incluye su propia estética por defecto. Creando respaldo antes de actualizar..."
    cp "$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc.bak"
    cp "$SCRIPT_DIR/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
    echo "✅ Fastfetch actualizado con el perfil del monorepo (respaldo guardado en config.jsonc.bak)."
else
    cp "$SCRIPT_DIR/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
    echo "✅ Fastfetch configurado con el perfil del monorepo."
fi
