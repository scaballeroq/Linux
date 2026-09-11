#!/bin/bash
# vscode.sh - Instalación de Visual Studio Code para Arch Linux
# Optimizado para Wayland (Ozone platform)

set -euo pipefail

echo "================================================================="
echo "💻 Instalando Visual Studio Code para Arch Linux"
echo "================================================================="

if command -v yay &> /dev/null; then
    echo "ℹ️ Instalando visual-studio-code-bin vía Yay (AUR)..."
    yay -S --needed --noconfirm visual-studio-code-bin
elif command -v paru &> /dev/null; then
    echo "ℹ️ Instalando visual-studio-code-bin vía Paru (AUR)..."
    paru -S --needed --noconfirm visual-studio-code-bin
else
    echo "ℹ️ AUR helper no encontrado. Instalando paquete 'code' desde repositorios oficiales..."
    sudo pacman -S --needed --noconfirm code
fi

echo "================================================================="
echo "✅ Visual Studio Code instalado con éxito."
echo "💡 Para ejecutar en Wayland nativo: code --enable-features=UseOzonePlatform --ozone-platform=wayland"
echo "================================================================="
