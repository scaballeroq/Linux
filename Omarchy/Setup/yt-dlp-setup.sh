#!/bin/bash
# yt-dlp-setup.sh - Instalación de yt-dlp y dependencias para Arch Linux

set -e

echo "📺 Instalando yt-dlp y dependencias..."

# Instalar yt-dlp y ffmpeg
sudo pacman -S --noconfirm yt-dlp ffmpeg

# Instalar Deno como JS runtime para descifrado de YouTube
echo "ℹ️ Instalando Deno..."
sudo pacman -S --noconfirm deno

echo "✅ yt-dlp configurado correctamente"
