#!/bin/bash
# shell.sh - Instalación de utilidades modernas de terminal para Arch Linux

set -e

echo "🐚 Instalando utilidades modernas de terminal..."

# Instalar utilidades desde repositorios oficiales
sudo pacman -S --noconfirm eza bat fzf zoxide ripgrep fd tldr duf dust bottom procs starship

# Instalar lazygit desde AUR
echo "ℹ️ Instalando Lazygit desde AUR..."
if command -v yay &> /dev/null; then
    yay -S --noconfirm lazygit
elif command -v paru &> /dev/null; then
    paru -S --noconfirm lazygit
else
    echo "⚠️ No se encontró yay ni paru. Instala lazygit manualmente."
fi

echo "✅ Utilidades de terminal instaladas correctamente"
