#!/bin/bash
# python.sh - Python Installation via Mise for Debian 13

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando dependencias para Python..."
# Mantener dependencias de librerías es útil para paquetes PIP que requieren compilación de extensiones C,
# aunque Python en sí se descargue precompilado.
sudo apt update
sudo apt install -y build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl git \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev

echo "ℹ️ Instalando Python 3.13..."
mise use --global python@3.13

echo "ℹ️ Actualizando pip..."
mise exec python@3.13 -- python -m pip install --upgrade pip

echo "✅ Python 3.13 instalado correctamente."
