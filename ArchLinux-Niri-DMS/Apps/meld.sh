#!/bin/bash
# meld.sh - Instalación de Meld (Herramienta visual de diferencias y mezclas)

set -euo pipefail

echo "ℹ️ Instalando Meld vía Pacman..."
sudo pacman -S --needed --noconfirm meld
echo "✅ Meld instalado con éxito."
