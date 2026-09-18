#!/bin/bash
# meld.sh - Instalación de Meld (Visual Diff and Merge tool para GNOME)

set -euo pipefail

echo "ℹ️ Instalando Meld vía Pacman..."
sudo pacman -S --needed --noconfirm meld
echo "✅ Meld instalado con éxito."
