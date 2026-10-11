#!/bin/bash
# git.sh - Instalación y configuración de Git, Git-Delta y Lazygit para Manjaro Linux

set -euo pipefail

echo "ℹ️ Instalando Git, Git-Delta y Lazygit vía Pacman..."
sudo pacman -S --needed --noconfirm git git-delta lazygit

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

# Configuración de Git-Delta
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global merge.conflictstyle zdiff3

echo "✅ Git configurado con Delta y Lazygit en Manjaro."
