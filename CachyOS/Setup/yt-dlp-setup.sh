#!/bin/bash
# yt-dlp-setup.sh - Instalación de dependencias para yt-dlp y multimedia para CachyOS

set -euo pipefail

echo "ℹ️ Instalando yt-dlp y FFMPEG vía Pacman..."
sudo pacman -S --needed --noconfirm yt-dlp ffmpeg

echo "ℹ️ Configurando motor JavaScript (Deno/NodeJS)..."
if command -v mise &> /dev/null; then
    echo "✅ Instalando Deno vía mise..."
    mise use --global deno@latest || true
elif ! command -v deno &> /dev/null; then
    echo "ℹ️ Instalando Deno desde repositorios de Pacman..."
    sudo pacman -S --needed --noconfirm deno || sudo pacman -S --needed --noconfirm nodejs
fi

echo "✅ Entorno multimedia preparado."
echo "💡 Usa los comandos: ytvideo, ytaudio, ytlista para descargar."
