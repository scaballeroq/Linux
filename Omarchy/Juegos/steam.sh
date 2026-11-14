#!/bin/bash
# ==============================================================================
# STEAM & GAMING SETUP (steam.sh) - Omarchy (Arch Linux + Hyprland)
# Optimizado para AMD Radeon Graphics (RADV Vulkan, GameMode, MangoHud)
# ==============================================================================

set -euo pipefail

echo "🎮 Configurando entorno de Gaming en Omarchy (Arch Linux)..."

# Asegurar multilib habilitado en pacman.conf
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "ℹ️ Habilitando repositorio [multilib] en /etc/pacman.conf..."
    sudo sed -i "/\[multilib\]/,/Include/s/^[ \t]*#[ \t]*//" /etc/pacman.conf
    sudo pacman -Sy
fi

echo "ℹ️ Instalando Steam, GameMode, MangoHud y drivers Vulkan de 32 y 64 bits..."
sudo pacman -S --needed --noconfirm \
    steam \
    gamemode \
    lib32-gamemode \
    mangohud \
    lib32-mangohud \
    vulkan-radeon \
    lib32-vulkan-radeon

echo "✅ Entorno de Steam y Gaming en Omarchy configurado correctamente."
