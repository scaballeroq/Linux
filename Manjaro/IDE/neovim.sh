#!/bin/bash
# neovim.sh - Instalación de Neovim y LazyVim para Manjaro Linux

set -euo pipefail

echo "ℹ️ Instalando Neovim y dependencias de desarrollo vía Pacman..."
sudo pacman -S --needed --noconfirm neovim gcc make ripgrep fd xclip wl-clipboard git

# LazyVim setup
if [ ! -d "$HOME/.config/nvim" ]; then
    echo "ℹ️ Configurando LazyVim..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
else
    echo "⚠️ $HOME/.config/nvim ya existe. Saltando clonación de LazyVim."
fi

echo "✅ Neovim instalado. Ejecuta 'nvim' y usa ':LazyHealth' para verificar LSPs."
