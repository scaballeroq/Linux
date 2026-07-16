#!/bin/bash
# mise.sh - Instalador de Mise (Gestor de Versiones) para Arch Linux

set -e

echo "ℹ️ Instalando Mise desde repositorios oficiales..."

sudo pacman -S --noconfirm mise

mkdir -p ~/.bashrc.d

cat <<EOF > ~/.bashrc.d/mise.sh
# Mise (Language Version Manager)
eval "\$(mise activate bash)"
EOF

echo "✅ Mise configurado modularmente en ~/.bashrc.d/mise.sh"
