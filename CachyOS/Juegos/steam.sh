#!/bin/bash
# steam.sh - Instalación de Steam y Proton en CachyOS

set -euo pipefail

echo "🎮 Instalando Steam y herramientas de compatibilidad Proton en CachyOS..."

if command -v pacman &> /dev/null; then
    echo "ℹ️ Instalando Steam nativo y Proton CachyOS vía Pacman..."
    sudo pacman -S --needed --noconfirm steam 2>/dev/null || true
    sudo pacman -S --needed --noconfirm proton-cachyos proton-ge-custom 2>/dev/null || true
fi

if command -v flatpak &> /dev/null; then
    echo "ℹ️ Instalando Steam vía Flatpak (opcional/respaldo)..."
    flatpak install -y flathub com.valvesoftware.Steam || true
    flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE || true
fi

echo "✅ Steam y Proton configurados."
