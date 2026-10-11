#!/bin/bash
# git.sh - Instalación de Git, Delta y Lazygit para Arch Linux

set -e

echo "ℹ️ Instalando Git y Git-Delta..."
sudo pacman -S --noconfirm git delta

echo "ℹ️ Aplicando configuración global de Git..."
git config --global user.name "Sergio Caballero"
git config --global user.email "scaballeroq@gmail.com"

git config --global init.defaultBranch develop
git config --global pull.rebase true
git config --global core.editor "nano"

git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global merge.conflictstyle zdiff3

echo "ℹ️ Instalando Lazygit desde AUR..."
if command -v yay &> /dev/null; then
    yay -S --noconfirm lazygit
elif command -v paru &> /dev/null; then
    paru -S --noconfirm lazygit
else
    echo "⚠️ No se encontró yay ni paru. Instala lazygit manualmente."
fi

echo "✅ Git configurado con Delta y Lazygit."
