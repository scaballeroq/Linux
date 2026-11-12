#!/bin/bash
# ==============================================================================
# NEOVIM SETUP (neovim.sh) - Omarchy (Arch Linux + Hyprland)
# Verificación de Neovim y utilidades Wayland nativas
# ==============================================================================

set -euo pipefail

echo "ℹ️ Verificando Neovim y herramientas nativas Wayland..."

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

# Omarchy ya incluye una configuración curada y optimizada para Neovim por defecto
if [ -d "$HOME/.config/nvim" ]; then
    echo "✔️ Configuración de Neovim detectada en ~/.config/nvim."
    echo "💡 Omarchy 4.5 incluye su propia configuración 'omakase' de Neovim preintegrada con omarchy-launch-editor."
    echo "   Se preserva la configuración oficial por defecto de Omarchy."
else
    echo "ℹ️ No se detectó configuración previa. Instalando configuración base LazyVim..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
    echo "  ✅ LazyVim configurado en ~/.config/nvim."
fi

echo ""
echo "✅ Neovim listo para Wayland."
