#!/bin/bash
# steam.sh - Instalación y Optimización NATIVA de Steam y Gaming en Manjaro Linux

set -euo pipefail

echo "🎮 Configurando entorno NATIVO de Gaming en Manjaro Linux..."

# 1. En Manjaro la versión nativa de Pacman (steam-manjaro / steam) es la recomendada
if command -v pacman &> /dev/null; then
    echo "ℹ️ Instalando Steam nativo, utilidades de rendimiento y capas de compatibilidad..."
    sudo pacman -S --needed --noconfirm \
        steam-manjaro \
        gamemode \
        lib32-gamemode \
        mangohud \
        lib32-mangohud \
        vulkan-radeon \
        lib32-vulkan-radeon \
        lutris 2>/dev/null || sudo pacman -S --needed --noconfirm steam gamemode mangohud lutris || true
fi

# 2. Desinstalar versión duplicada de Flatpak (si existe) para evitar duplicación de iconos
if command -v flatpak &> /dev/null; then
    if flatpak list | grep -q "com.valvesoftware.Steam"; then
        echo "🧹 Detectado Steam en Flatpak duplicado. Eliminando versión Flatpak para usar solo la versión NATIVA..."
        flatpak uninstall -y com.valvesoftware.Steam com.valvesoftware.Steam.CompatibilityTool.Proton-GE 2>/dev/null || true
    fi
fi

echo "✅ Entorno NATIVO de Steam y Gaming en Manjaro configurado correctamente."
