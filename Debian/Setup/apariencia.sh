#!/bin/bash
# apariencia.sh - Instalación de temas e iconos para Debian 13

set -euo pipefail

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
    gnome-themes-extra \
    adwaita-qt \
    adwaita-qt6

# Configuración de tema Adwaita Dark en gsettings
if command -v gsettings &> /dev/null; then
    echo "ℹ️ Configurando tema oscuro Adwaita (Dark)..."
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
fi

echo "✅ Temas e iconos instalados y configurados correctamente."
