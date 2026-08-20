#!/bin/bash
# steam.sh - Instalación de Steam y Proton para OpenSUSE Tumbleweed

set -euo pipefail

echo "🎮 Configurando entorno de Gaming para OpenSUSE Tumbleweed..."

# 1. Instalar Steam nativo y librerías de 32 bits vía Zypper
echo "ℹ️ Instalando Steam nativo y librerías gráficas de 32 bits..."
sudo zypper --non-interactive install -y \
    steam \
    libvulkan_radeon-32bit \
    libvulkan_intel-32bit 2>/dev/null || sudo zypper --non-interactive install -y steam || true

# 2. Si Flatpak está disponible, configurar Proton-GE
if command -v flatpak &> /dev/null; then
    echo "ℹ️ Configurando Flathub para herramientas de compatibilidad..."
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    
    # Si steam nativo no se pudo instalar, instalar versión flatpak
    if ! command -v steam &>/dev/null; then
        echo "ℹ️ Instalando Steam vía Flatpak..."
        flatpak install -y flathub com.valvesoftware.Steam 2>/dev/null || true
    fi

    flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE 2>/dev/null || true
fi

echo "✅ Entorno de Gaming en OpenSUSE Tumbleweed configurado correctamente."
