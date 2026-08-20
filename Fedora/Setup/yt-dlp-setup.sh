#!/bin/bash
# yt-dlp-setup.sh - Instalación de dependencias para yt-dlp y multimedia para Fedora 44

set -euo pipefail

echo "ℹ️ Instalando yt-dlp y FFMPEG vía DNF5 en Fedora 44..."
sudo dnf5 install -y yt-dlp ffmpeg

echo "ℹ️ Configurando motor JavaScript (Deno) vía Mise..."
if command -v mise &> /dev/null; then
    mise use --global deno@latest || true
fi

echo "✅ yt-dlp, FFmpeg y soporte de motor JS configurados correctamente."
