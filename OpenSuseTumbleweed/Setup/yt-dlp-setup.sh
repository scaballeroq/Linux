#!/bin/bash
# yt-dlp-setup.sh - Instalación de dependencias para yt-dlp y multimedia para OpenSUSE Tumbleweed

set -euo pipefail

echo "ℹ️ Instalando yt-dlp y FFMPEG vía Zypper en OpenSUSE Tumbleweed..."
sudo zypper --non-interactive install -y yt-dlp ffmpeg 2>/dev/null || true

echo "ℹ️ Configurando motor JavaScript (Deno) vía Mise..."
if command -v mise &> /dev/null; then
    echo "✅ Instalando Deno vía mise..."
    mise use --global deno@latest
else
    echo "⚠️ 'mise' no detectado. Instalando NodeJS a nivel de sistema como respaldo..."
    sudo zypper --non-interactive install -y nodejs22 2>/dev/null || sudo zypper --non-interactive install -y nodejs || true
fi

echo "✅ Entorno multimedia preparado."
echo "💡 Usa los comandos: ytvideo, ytaudio, ytlista para descargar."
