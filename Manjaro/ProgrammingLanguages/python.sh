#!/bin/bash
# python.sh - Python Installation via Mise for Manjaro

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando dependencias de compilación para Python en Manjaro..."
sudo pacman -S --needed --noconfirm base-devel openssl zlib bzip2 readline sqlite curl git ncurses xz tk libffi

echo "ℹ️ Instalando Python 3.12 vía Mise..."
mise use --global python@3.12

echo "ℹ️ Actualizando pip..."
mise exec python@3.12 -- python -m pip install --upgrade pip

echo "✅ Python 3.12 instalado correctamente."
