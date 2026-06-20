#!/bin/bash
# java.sh - Instalación de OpenJDK y dependencias para AutoFirma

set -e

echo "ℹ️ Instalando OpenJDK y dependencias para AutoFirma (libnss3-tools)..."

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

$SUDO apt-get update
$SUDO apt-get install -y default-jre default-jdk libnss3-tools

echo "✅ OpenJDK y dependencias para AutoFirma instalados correctamente."
