#!/bin/bash
# neovim.sh - Instalación de Neovim y LazyVim para Kubuntu

set -e

echo "ℹ️ Instalando Neovim y dependencias vía APT..."
sudo apt update
sudo apt install -y neovim gcc make g++ ripgrep fd-find xclip wl-copy git

# Configurar symlink para fd si no existe
mkdir -p ~/.local/bin
[ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind ~/.local/bin/fd

# LazyVim setup
if [ ! -d "$HOME/.config/nvim" ]; then
    echo "ℹ️ Configurando LazyVim..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
else
    echo "⚠️ $HOME/.config/nvim ya existe. Saltando clonación de LazyVim."
fi

echo "✅ Neovim instalado. Ejecuta 'nvim' y usa ':LazyHealth' para verificar LSPs."
