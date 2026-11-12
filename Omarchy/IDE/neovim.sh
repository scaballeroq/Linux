#!/bin/bash
# ==============================================================================
# NEOVIM SETUP (neovim.sh) - Omarchy (Arch Linux + Hyprland)
# Instalación de Neovim, utilidades Wayland nativas y LazyVim Starter
# ==============================================================================

set -euo pipefail

echo "ℹ️ Instalando Neovim y herramientas de compilación/búsqueda..."

# En Wayland nativo utilizamos wl-clipboard (Prohibido xclip)
sudo pacman -S --needed --noconfirm \
    neovim \
    gcc \
    make \
    ripgrep \
    fd \
    wl-clipboard \
    tree-sitter \
    tree-sitter-cli

if [ ! -d "$HOME/.config/nvim" ]; then
    echo "ℹ️ Instalando configuración base LazyVim..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
    echo "  ✅ LazyVim configurado en ~/.config/nvim."
else
    echo "⚠️ $HOME/.config/nvim ya existe. Saltando clonación de LazyVim."
fi

echo ""
echo "✅ Neovim instalado y listo para Wayland."
echo "💡 Ejecuta 'nvim' y escribe ':LazyHealth' para comprobar el estado."
