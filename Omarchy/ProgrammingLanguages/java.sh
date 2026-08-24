#!/bin/bash
# java.sh - Instalación de OpenJDK y dependencias para AutoFirma (Arch Linux)

set -euo pipefail

echo "ℹ️ Instalando OpenJDK y dependencias para AutoFirma..."

# Verificar si se necesita sudo
if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "❌ Error: Este script requiere privilegios de superusuario (root o sudo)."
        exit 1
    fi
else
    SUDO=""
fi

$SUDO pacman -S --noconfirm jdk-openjdk nss

echo "✅ OpenJDK y dependencias para AutoFirma instalados correctamente."
