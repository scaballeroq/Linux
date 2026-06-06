#!/bin/bash
# python.sh - Python Installation via Mise

set -e

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado."
    exit 1
fi

echo "ℹ️ Instalando dependencias de compilación para Python..."
sudo dnf5 install -y gcc gcc-c++ make automake autoconf curl \
    openssl-devel zlib-devel readline-devel libyaml-devel libffi-devel \
    bzip2-devel libxml2-devel libxslt-devel libtool patch \
    sqlite-devel perl-devel gdbm-devel ncurses-devel \
    tcl-devel tk-devel xz-devel libedit-devel || true

export MISE_PYTHON_COMPILE=1
echo "ℹ️ Instalando Python 3.12 vía Mise (Nativo)..."
mise use --global python@3.12

echo "✅ Python 3.12 instalado correctamente."
