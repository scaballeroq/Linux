#!/bin/bash
# fastfetch.sh - Instalación y configuración de Fastfetch (Optimizado) para Kubuntu

set -e

echo "ℹ️ Instalando Fastfetch..."
# Fastfetch está disponible en los repositorios oficiales de Kubuntu 26.04 LTS
sudo apt update
sudo apt install -y fastfetch

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
fastfetch
