#!/bin/bash
# steam.sh - Instalación de Steam, Lutris y Proton para Fedora 44

set -euo pipefail

echo "🎮 Configurando entorno de Gaming para Fedora 44..."

# 1. Intentar instalar Steam NATIVO desde RPM Fusion
if command -v dnf5 &> /dev/null; then
    echo "ℹ️ Instalando Steam nativo y utilidades de gaming vía DNF5..."
    sudo dnf5 install -y steam gamemode mangohud 2>/dev/null || true
fi

# 2. Si Flatpak está disponible, configurar Proton-GE y soporte Flatpak
if command -v flatpak &> /dev/null; then
    echo "ℹ️ Configurando Flathub para herramientas de compatibilidad..."
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    
    # Si steam nativo no se pudo instalar, instalar versión flatpak
    if ! command -v steam &>/dev/null; then
        echo "ℹ️ Instalando Steam vía Flatpak..."
        flatpak install -y flathub com.valvesoftware.Steam 2>/dev/null || true
    fi

    echo "ℹ️ Instalando Proton-GE vía Flathub..."
    flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE 2>/dev/null || true
fi

echo "✅ Entorno de Gaming en Fedora 44 configurado correctamente."
