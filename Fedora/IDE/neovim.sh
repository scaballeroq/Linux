#!/bin/bash
# neovim.sh - Instalación de Neovim y LazyVim para Fedora 44

set -euo pipefail

echo "Instalando Neovim y dependencias vía DNF5..."
sudo dnf5 install -y neovim gcc make gcc-c++ ripgrep fd-find xclip wl-clipboard git

# Configurar symlink para fd si no existe
mkdir -p ~/.local/bin
[ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind ~/.local/bin/fd

# LazyVim setup
if [ ! -d "$HOME/.config/nvim" ]; then
    echo "Configurando LazyVim..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
else
    echo "$HOME/.config/nvim ya existe. Saltando clonación de LazyVim."
fi

echo "Neovim instalado. Ejecuta 'nvim' y usa ':LazyHealth' para verificar LSPs."
