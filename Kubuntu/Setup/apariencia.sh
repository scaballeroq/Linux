#!/bin/bash
# apariencia.sh - Instalación de temas e iconos para Kubuntu (KDE Plasma)

set -euo pipefail

echo "🚀 Instalando temas e iconos para KDE Plasma (Papirus, Breeze)..."

# Verificar privilegios de sudo
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

$SUDO apt update
$SUDO apt install -y \
    papirus-icon-theme \
    breeze-icon-theme \
    breeze-cursor-theme

# Configuración opcional de tema oscuro Breeze si lookandfeeltool está presente
if command -v lookandfeeltool &> /dev/null; then
    echo "ℹ️ Aplicando tema global Breeze Dark..."
    lookandfeeltool -a org.kde.breezedark.desktop 2>/dev/null || true
fi

echo "✅ Temas e iconos instalados y configurados correctamente."
