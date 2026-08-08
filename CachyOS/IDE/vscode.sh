#!/bin/bash
# vscode.sh - Instalación de Visual Studio Code para CachyOS

set -euo pipefail

echo "ℹ️ Instalando Visual Studio Code en CachyOS..."

if command -v paru &> /dev/null; then
    echo "ℹ️ Instalando visual-studio-code-bin vía paru (AUR)..."
    paru -S --needed --noconfirm visual-studio-code-bin || sudo pacman -S --needed --noconfirm code
elif command -v yay &> /dev/null; then
    echo "ℹ️ Instalando visual-studio-code-bin vía yay (AUR)..."
    yay -S --needed --noconfirm visual-studio-code-bin || sudo pacman -S --needed --noconfirm code
else
    echo "ℹ️ Instalando 'code' (Code - OSS) vía Pacman..."
    sudo pacman -S --needed --noconfirm code
fi

echo "✅ Visual Studio Code instalado correctamente."
