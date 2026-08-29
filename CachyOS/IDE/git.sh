#!/bin/bash
# git.sh - Instalación de Git, Delta y Lazygit (Optimizado) para CachyOS

set -euo pipefail

echo "ℹ️ Instalando Git y Delta vía Pacman..."
sudo pacman -S --needed --noconfirm git git-delta

# Configuración Global de Git
echo "ℹ️ Aplicando configuración global de Git..."
GIT_USER_NAME="${GIT_USER_NAME:-Sergio Caballero}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-scaballeroq@gmail.com}"

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

# Mejores prácticas modernas
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.editor "nvim"

# Configuración de Git-Delta (Diferencias mucho más legibles)
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global merge.conflictstyle zdiff3

# Instalación de Lazygit (TUI para Git)
echo "ℹ️ Instalando Lazygit..."
if ! command -v lazygit &> /dev/null; then
    sudo pacman -S --needed --noconfirm lazygit 2>/dev/null || true
fi

echo "✅ Git configurado con Delta y Lazygit."
