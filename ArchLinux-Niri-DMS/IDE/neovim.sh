#!/bin/bash
# neovim.sh - Instalación de Neovim y entorno moderno LazyVim para Arch Linux

set -euo pipefail

echo "================================================================="
echo "📝 Instalando Neovim y dependencias de desarrollo..."
echo "================================================================="

sudo pacman -S --needed --noconfirm \
    neovim \
    gcc \
    make \
    ripgrep \
    fd \
    wl-clipboard \
    git \
    curl \
    tree-sitter

if [ ! -d "$HOME/.config/nvim" ]; then
    echo "ℹ️ Configurando LazyVim como starter kit..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
    echo "✅ LazyVim configurado en ~/.config/nvim."
else
    echo "ℹ️ ~/.config/nvim ya existe. Se preserva la configuración actual."
fi

echo "================================================================="
echo "✅ Neovim instalado y preparado."
echo "💡 Abre 'nvim' y ejecuta ':LazyHealth' para revisar LSPs y plugins."
echo "================================================================="
