#!/bin/bash
# apariencia.sh - Instalación de temas e iconos para CachyOS

set -euo pipefail

echo "ℹ️ Instalando temas e iconos (Papirus icon theme)..."
sudo pacman -S --needed --noconfirm papirus-icon-theme

echo "✅ Temas e iconos instalados correctamente."
