#!/bin/bash
# mise.sh - Instalación de Mise (Polyglot Runtime / Version Manager) para Omarchy

set -euo pipefail

echo "⚡ Instalando Mise desde repositorios oficiales..."
sudo pacman -S --needed --noconfirm mise

echo ""
echo "✅ Mise instalado correctamente ($(mise --version))."
echo "💡 Omarchy integra y activa Mise automáticamente en cada terminal (/usr/share/omarchy/default/bash/init)."

