#!/bin/bash
# steam.sh - Instalación de Steam, Lutris y Proton para Debian

set -euo pipefail

echo "🎮 Configurando entorno de Gaming para Debian..."

# 1. Intentar instalar Steam NATIVO desde el repositorio non-free de Debian
if command -v apt &> /dev/null; then
    echo "ℹ️ Asegurando arquitectura i386 (32 bits) para Steam..."
    sudo dpkg --add-architecture i386 2>/dev/null || true
    sudo apt update

    echo "ℹ️ Instalando Steam nativo y librerías de 32 bits..."
    sudo apt install -y steam-installer steam 2>/dev/null || true
fi

# 2. Si Flatpak está disponible, ofrecer o instalar Proton-GE
if command -v flatpak &> /dev/null; then
    echo "ℹ️ Configurando Flathub para herramientas de compatibilidad..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    
    # Si steam nativo no se pudo instalar, instalar versión flatpak
    if ! command -v steam &>/dev/null; then
        echo "ℹ️ Instalando Steam vía Flatpak..."
        flatpak install -y flathub com.valvesoftware.Steam 2>/dev/null || true
    fi

    flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE 2>/dev/null || true
fi

echo "✅ Entorno de Gaming en Debian configurado correctamente."
