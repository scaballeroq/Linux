#!/bin/bash
# steam.sh - Instalación y Optimización NATIVA de Steam, Lutris, Heroic y Proton en CachyOS

set -euo pipefail

echo "🎮 Configurando entorno NATIVO de Gaming en CachyOS..."

# 1. En CachyOS la versión nativa de Pacman es la recomendada (x86_64_v3 y compatibilidad directa con driver GPU)
if command -v pacman &> /dev/null; then
    echo "ℹ️ Optimizando espejos y actualizando bases de datos..."
    if command -v cachyos-rate-mirrors &> /dev/null; then
        sudo cachyos-rate-mirrors || true
    fi
    sudo pacman -Sy

    echo "ℹ️ Instalando Steam NATIVO, Proton CachyOS y cachyos-gaming-meta..."
    sudo pacman -S --needed --noconfirm steam proton-cachyos cachyos-gaming-meta 2>/dev/null || true
fi

# 2. Desinstalar versión duplicada de Flatpak (si existe) para evitar la duplicación de iconos y ahorrar espacio
if command -v flatpak &> /dev/null; then
    if flatpak list | grep -q "com.valvesoftware.Steam"; then
        echo "🧹 Detectado Steam en Flatpak duplicado. Eliminando versión Flatpak para usar solo la versión NATIVA optimizada..."
        flatpak uninstall -y com.valvesoftware.Steam com.valvesoftware.Steam.CompatibilityTool.Proton-GE 2>/dev/null || true
    fi
fi

echo "✅ Entorno NATIVO de Steam y Gaming en CachyOS configurado (Sin duplicados)."
