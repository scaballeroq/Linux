#!/bin/bash
# vscode.sh - Instalación de Visual Studio Code para Arch Linux

set -e

echo "ℹ️ Instalando Visual Studio Code..."

if command -v yay &> /dev/null; then
    yay -S --noconfirm visual-studio-code-bin
elif command -v paru &> /dev/null; then
    paru -S --noconfirm visual-studio-code-bin
else
    echo "ℹ️ Instalando VS Code desde repositorio oficial..."
    sudo pacman -S --noconfirm code
fi

echo "✅ VS Code instalado."
