#!/bin/bash
# yt-dlp-setup.sh - Instalación y configuración de yt-dlp para Omarchy (Arch Linux)

set -euo pipefail

echo "📺 Instalando yt-dlp, FFmpeg, Deno y dependencias multimedia recomendadas..."

# 1. Instalar yt-dlp, ffmpeg, runtime de JS (Deno) y librerías para metadatos/carátulas
sudo pacman -S --needed --noconfirm \
    yt-dlp \
    ffmpeg \
    deno \
    atomicparsley \
    python-mutagen \
    python-pycryptodomex \
    python-secretstorage

echo ""
echo "✅ yt-dlp, motor Deno y códecs multimedia instalados correctamente."
echo "💡 Para descargar audio con carátula: yt-dlp -x --audio-format mp3 --embed-thumbnail <URL>"

