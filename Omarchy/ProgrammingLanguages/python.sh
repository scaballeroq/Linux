#!/bin/bash
# python.sh - Python Installation via Mise

set -e

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado."
    exit 1
fi

echo "ℹ️ Instalando dependencias de compilación para Python..."
sudo pacman -S --noconfirm gcc make automake autoconf curl \
    openssl zlib readline libyaml libffi \
    bzip2 libxml2 libxslt libtool patch \
    sqlite perl gdbm ncurses \
    tcl tk xz libedit || true

export MISE_PYTHON_COMPILE=1
echo "ℹ️ Instalando Python 3.12 vía Mise (Nativo)..."
mise use --global python@3.12

echo "✅ Python 3.12 instalado correctamente."
