#!/bin/bash
# steam.sh - Instalación de Steam y Proton-GE via Flatpak

set -e

echo "🚀 Iniciando instalación de Steam y Proton-GE..."

# 1. Instalar Steam
echo "ℹ️ Instalando Steam desde Flathub..."
flatpak install flathub com.valvesoftware.Steam -y

# 2. Instalar Proton-GE
echo "ℹ️ Instalando Proton-GE (Proton Glorious Eggroll) desde Flathub..."
flatpak install flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE -y

# 3. Actualizar sistema de Flatpak (limpieza y verificación)
echo "ℹ️ Actualizando el sistema Flatpak..."
flatpak update -y

echo "✅ ¡Instalación completada! Steam y Proton-GE están listos."

