#!/bin/bash
# python.sh - Instalación de Python 3.13 y uv vía Mise para Debian Testing / Trixie

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

echo "ℹ️ Instalando Python 3.13 vía Mise..."
mise use --global python@3.13

echo "ℹ️ Actualizando pip, setuptools y wheel..."
mise exec python@3.13 -- python -m pip install --upgrade pip setuptools wheel

echo "ℹ️ Instalando uv (gestor ultrarrápido de paquetes y entornos Python) vía Mise..."
mise use --global uv@latest
mise reshim

echo "✅ Python 3.13, pip y uv configurados correctamente."
