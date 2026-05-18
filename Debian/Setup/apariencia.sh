#!/bin/bash
# apariencia.sh - Instalación de temas e iconos para Debian 13

set -e

echo "ℹ️ Instalando temas e iconos (Papirus y Adwaita completos con tema Dark)..."

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
$SUDO apt-get install -y \
    papirus-icon-theme \
    adwaita-icon-theme \
    adwaita-icon-theme-legacy \
    gnome-themes-extra

echo "✅ Temas e iconos instalados correctamente."
