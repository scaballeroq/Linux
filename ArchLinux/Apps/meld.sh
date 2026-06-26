#!/bin/bash
# meld.sh - Instalación de Meld

set -e

echo "ℹ️ Instalando Meld..."
sudo pacman -S --noconfirm meld
echo "✅ Meld instalado."
