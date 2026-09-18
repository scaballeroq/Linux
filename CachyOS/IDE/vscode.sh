#!/bin/bash
# vscode.sh - Instalación de Visual Studio Code para CachyOS / GNOME

set -euo pipefail

echo "ℹ️ Instalando Visual Studio Code..."

if command -v paru &> /dev/null; then
    paru -S --needed --noconfirm visual-studio-code-bin
elif command -v yay &> /dev/null; then
    yay -S --needed --noconfirm visual-studio-code-bin
else
    sudo pacman -S --needed --noconfirm code
fi

echo "✅ Visual Studio Code instalado con éxito."
