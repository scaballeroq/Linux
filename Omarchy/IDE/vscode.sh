#!/bin/bash
# vscode.sh - Instalación de Visual Studio Code para Arch Linux

set -euo pipefail

echo "ℹ️ Instalando Visual Studio Code..."

if command -v yay &> /dev/null; then
    yay -S --noconfirm visual-studio-code-bin
elif command -v paru &> /dev/null; then
    paru -S --noconfirm visual-studio-code-bin
else
    echo "⚠️ No se encontró yay ni paru. Instale VS Code manualmente o use un AUR helper."
    exit 1
fi

echo "✅ Visual Studio Code instalado correctamente."
