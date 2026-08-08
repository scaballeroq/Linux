#!/bin/bash
# meld.sh - Instalación de Meld para CachyOS

set -euo pipefail

echo "ℹ️ Instalando Meld vía Pacman..."
sudo pacman -S --needed --noconfirm meld
echo "✅ Meld instalado."
