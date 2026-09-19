#!/bin/bash
# fastfetch.sh - Instalación y configuración de Fastfetch para Fedora 44

set -euo pipefail

echo "ℹ️ Instalando Fastfetch vía DNF5..."
sudo dnf5 install -y fastfetch

# Crear directorio de configuración si no existe
mkdir -p ~/.config/fastfetch

# Copiar configuración personalizada
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.jsonc" ]; then
    cp "$SCRIPT_DIR/config.jsonc" ~/.config/fastfetch/config.jsonc
    echo "✅ Configuración personalizada aplicada en ~/.config/fastfetch/config.jsonc"
fi

echo "✅ Fastfetch instalado correctamente. Ejecuta 'fastfetch' para probarlo."
