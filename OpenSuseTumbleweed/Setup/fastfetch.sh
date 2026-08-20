#!/bin/bash
# fastfetch.sh - Instalación y configuración de Fastfetch para OpenSUSE Tumbleweed

set -euo pipefail

echo "ℹ️ Instalando Fastfetch vía Zypper..."
sudo zypper --non-interactive install -y fastfetch 2>/dev/null || true

# Asegurar directorio de configuración
mkdir -p ~/.config/fastfetch

# Copiar configuración local
if [ -f "Setup/config.jsonc" ]; then
    echo "ℹ️ Aplicando configuración personalizada desde Setup/config.jsonc..."
    cp Setup/config.jsonc ~/.config/fastfetch/config.jsonc
elif [ -f "config.jsonc" ]; then
    echo "ℹ️ Aplicando configuración personalizada desde config.jsonc..."
    cp config.jsonc ~/.config/fastfetch/config.jsonc
fi

echo "✅ Fastfetch instalado y configurado."
fastfetch || true
