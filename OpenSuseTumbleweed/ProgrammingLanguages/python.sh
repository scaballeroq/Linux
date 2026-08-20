#!/bin/bash
# python.sh - Python Installation via Mise for OpenSUSE Tumbleweed

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando dependencias de compilación para Python..."
sudo zypper --non-interactive install -y -t pattern devel_basis 2>/dev/null || true
sudo zypper --non-interactive install -y \
    libopenssl-devel \
    zlib-devel \
    libbz2-devel \
    readline-devel \
    sqlite3-devel \
    curl \
    git \
    ncurses-devel \
    xz-devel \
    tk-devel \
    libxml2-devel \
    libffi-devel 2>/dev/null || true

echo "ℹ️ Instalando Python 3.13..."
mise use --global python@3.13

echo "ℹ️ Actualizando pip..."
mise exec python@3.13 -- python -m pip install --upgrade pip

echo "✅ Python 3.13 instalado correctamente."
