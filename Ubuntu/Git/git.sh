#!/bin/bash
# git.sh - Instalación de Git, Delta y Lazygit (Optimizado) para Ubuntu

set -e

echo "ℹ️ Instalando Git y Git-Delta vía APT..."
sudo apt update
sudo apt install -y git git-delta

# Configuración Global de Git
echo "ℹ️ Aplicando configuración global de Git..."
git config --global user.name "Sergio Caballero"
git config --global user.email "scaballeroq@gmail.com"

# Mejores prácticas modernas
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.editor "nvim"

# Configuración de Git-Delta (Diferencias mucho más legibles)
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global merge.conflictstyle zdiff3

# Instalación de Lazygit (TUI para Git)
echo "ℹ️ Instalando Lazygit..."
if ! command -v lazygit &> /dev/null; then
    # Usar el script oficial de instalación o PPA
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
fi

echo "✅ Git configurado con Delta y Lazygit."
