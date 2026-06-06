#!/bin/bash
# git.sh - Instalación de Git, Delta y Lazygit (Optimizado)

set -e

echo "ℹ️ Instalando Git, Git-Delta y Lazygit vía DNF5..."
sudo dnf5 install -y git git-delta

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
echo "ℹ️ Configurando repositorio para Lazygit..."
sudo dnf5 copr enable -y dejan/lazygit 
sudo dnf5 install -y lazygit

echo "✅ Git configurado con Delta y Lazygit."