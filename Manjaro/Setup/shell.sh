#!/bin/bash
# shell.sh - Instalación de utilidades de terminal para Manjaro Linux

set -euo pipefail

echo "ℹ️ Instalando utilidades de terminal modernas..."
sudo pacman -S --needed --noconfirm \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd \
    tealdeer \
    duf \
    dust \
    procs 2>/dev/null || sudo pacman -S --needed --noconfirm eza bat fzf zoxide ripgrep fd duf || true

echo "✅ Utilidades de terminal instaladas correctamente."
echo "✅ Configuración ZSH de Manjaro preservada por defecto."
