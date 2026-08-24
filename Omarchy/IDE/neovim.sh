#!/bin/bash
# neovim.sh - Instalación de Neovim y LazyVim para Arch Linux

set -euo pipefail

echo "ℹ️ Instalando Neovim y dependencias..."
sudo pacman -S --noconfirm neovim gcc make ripgrep fd wl-clipboard xclip

# Configurar symlink para fd si no existe
mkdir -p ~/.local/bin
[ -f /usr/bin/fd ] && ln -sf /usr/bin/fd ~/.local/bin/fd 2>/dev/null || true

if [ ! -d "$HOME/.config/nvim" ]; then
    echo "ℹ️ Configurando LazyVim..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
else
    echo "⚠️ $HOME/.config/nvim ya existe. Saltando clonación de LazyVim."
fi

echo "✅ Neovim instalado. Ejecuta 'nvim' y usa ':LazyHealth' para verificar LSPs."
