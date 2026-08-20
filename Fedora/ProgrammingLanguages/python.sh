#!/bin/bash
# python.sh - Python Installation via Mise for Fedora 44

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando dependencias de cabeceras para Python en Fedora..."
sudo dnf5 install -y @development-tools openssl-devel zlib-devel bzip2-devel \
    readline-devel sqlite-devel curl git ncurses-devel xz-devel tk-devel \
    libxml2-devel libxmlsec1-devel libffi-devel

echo "ℹ️ Instalando Python 3.13..."
mise use --global python@3.13

echo "ℹ️ Actualizando pip..."
mise exec python@3.13 -- python -m pip install --upgrade pip

echo "✅ Python 3.13 instalado correctamente."
