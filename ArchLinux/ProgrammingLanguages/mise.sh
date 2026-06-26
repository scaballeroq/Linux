#!/bin/bash
# mise.sh - Instalador de Mise (Gestor de Versiones) para Arch Linux

set -e

echo "ℹ️ Instalando Mise desde AUR..."

if command -v yay &> /dev/null; then
    yay -S --noconfirm mise
elif command -v paru &> /dev/null; then
    paru -S --noconfirm mise
else
    echo "ℹ️ Instalando Mise mediante script oficial..."
    curl https://mise.run | sh
fi

mkdir -p ~/.bashrc.d

cat <<EOF > ~/.bashrc.d/mise.sh
# Mise (Language Version Manager)
eval "\$(mise activate bash)"
EOF

echo "✅ Mise configurado modularmente en ~/.bashrc.d/mise.sh"
