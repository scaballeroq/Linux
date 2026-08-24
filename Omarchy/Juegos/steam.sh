#!/bin/bash
# steam.sh - Instalación de Steam para Arch Linux

set -euo pipefail

echo "🎮 Instalando Steam..."

# Habilitar multilib si no está habilitado
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    echo "ℹ️ Habilitando repositorio multilib..."
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Syu --noconfirm
fi

# Instalar Steam y dependencias de gaming
echo "ℹ️ Instalando Steam y dependencias..."
sudo pacman -S --noconfirm steam steam-native-runtime gamemode

echo "✅ Steam instalado correctamente."
echo "💡 Ejecuta 'steam' para iniciar la configuración inicial."
