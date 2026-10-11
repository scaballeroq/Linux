#!/bin/bash
# meld.sh - Instalación de Meld para Manjaro Linux

set -euo pipefail

echo "ℹ️ Instalando Meld (Visor gráfico de diferencias) vía Pacman..."
sudo pacman -S --needed --noconfirm meld
echo "✅ Meld instalado correctamente."
