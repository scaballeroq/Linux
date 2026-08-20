#!/bin/bash
# firefox.sh - Instalación de Mozilla Firefox nativo con paquete de idioma español en Manjaro Linux

set -euo pipefail

echo "🌐 Instalando Mozilla Firefox e idioma español (es-ES) vía Pacman..."

sudo pacman -S --needed --noconfirm \
    firefox \
    firefox-i18n-es-es

echo "✅ Mozilla Firefox instalado correctamente en Manjaro."
