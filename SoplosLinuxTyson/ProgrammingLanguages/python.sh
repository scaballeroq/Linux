#!/usr/bin/env bash
# python.sh - Instalación de la última versión estable de Python y uv vía Mise para Soplos Linux Tyson

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando dependencias de compilación para Python..."
sudo apt update
sudo apt install -y build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl git \
    libncurses-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev

echo "ℹ️ Instalando la última versión estable de Python vía Mise..."
mise use --global python@latest

echo "ℹ️ Actualizando pip, setuptools y wheel..."
mise exec python@latest -- python -m pip install --upgrade pip setuptools wheel

echo "ℹ️ Instalando uv (gestor ultrarrápido de paquetes y entornos Python) vía Mise..."
mise use --global uv@latest
mise reshim

echo "✅ Python (última versión estable), pip y uv configurados correctamente con Mise."
