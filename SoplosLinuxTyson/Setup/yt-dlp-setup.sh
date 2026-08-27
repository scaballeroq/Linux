#!/bin/bash
# yt-dlp-setup.sh - Instalación de dependencias para yt-dlp y multimedia para Soplos Linux Tyson (Debian Testing)

set -euo pipefail

echo "ℹ️ Instalando yt-dlp y FFMPEG vía APT en Soplos Linux Tyson..."
sudo apt update
sudo apt install -y yt-dlp ffmpeg

echo "ℹ️ Configurando motor JavaScript (Deno) para extracción multimedia..."
# yt-dlp utiliza motores JS para descifrar algoritmos de YouTube (n-challenge).
if command -v mise &> /dev/null; then
    echo "✅ Instalando Deno vía mise..."
    mise use --global deno@latest || true
else
    echo "ℹ️ Instalando NodeJS como motor JS de respaldo..."
    sudo apt install -y nodejs
fi

echo "✅ Entorno multimedia preparado en Soplos Linux Tyson."
echo "💡 Usa los comandos: ytvideo, ytaudio, ytlista para descargar."
