#!/bin/bash
# git.sh - Instalación y optimización de Git, Git-Delta y Lazygit para Omarchy (Arch Linux)

set -euo pipefail

echo "📦 Instalando Git, Git-Delta y Lazygit..."
sudo pacman -S --needed --noconfirm git git-delta lazygit

echo "⚙️ Configurando integraciones de Git y Delta..."

# Paginador Delta para diffs legibles y modernos
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global merge.conflictstyle zdiff3

# Configuración recomendada de flujo de trabajo
git config --global pull.rebase true
git config --global push.autoSetupRemote true

echo ""
echo "✅ Git, Delta y Lazygit instalados y configurados correctamente."

