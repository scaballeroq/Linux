#!/bin/bash
# git.sh - Instalación de Git, Delta y Lazygit (Optimizado) para Debian

set -euo pipefail

echo "ℹ️ Instalando Git y Delta vía APT..."
sudo apt update
sudo apt install -y git delta

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
git config --global merge.conflictstyle zdiff3

# Instalación de Lazygit (TUI para Git)
echo "ℹ️ Instalando Lazygit..."
if ! command -v lazygit &> /dev/null; then
    ARCH=$(dpkg --print-architecture)
    case "$ARCH" in
        amd64) LAZYGIT_ARCH="x86_64" ;;
        arm64) LAZYGIT_ARCH="arm64" ;;
        *) echo "❌ Arquitectura no soportada: $ARCH"; exit 1 ;;
    esac
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_ARCH}_Linux_${LAZYGIT_ARCH}.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
fi

echo "✅ Git configurado con Delta y Lazygit."
