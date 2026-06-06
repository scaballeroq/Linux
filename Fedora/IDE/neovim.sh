#!/bin/bash
# neovim.sh - Instalación de Neovim y LazyVim (Optimizado)

set -e

echo "ℹ️ Instalando Neovim y dependencias vía DNF5..."
sudo dnf5 install -y neovim gcc make gcc-c++ ripgrep fd-find xclip wl-copy

# LazyVim setup
if [ ! -d "$HOME/.config/nvim" ]; then
    echo "ℹ️ Configurando LazyVim..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    # Mantener el .git es útil para actualizaciones de LazyVim, 
    # pero el original borraba el starter .git para hacerlo propio. 
    # Seguimos la lógica original pero con un aviso.
    rm -rf "$HOME/.config/nvim/.git"
else
    echo "⚠️ $HOME/.config/nvim ya existe. Saltando clonación de LazyVim."
fi

echo "✅ Neovim instalado. Ejecuta 'nvim' y usa ':LazyHealth' para verificar LSPs."
