#!/bin/bash
# yt-dlp-setup.sh - Instalación de dependencias para yt-dlp y multimedia en Manjaro Linux

set -euo pipefail

echo "ℹ️ Instalando yt-dlp, FFMPEG y AtomicParsley vía Pacman..."
sudo pacman -S --needed --noconfirm yt-dlp ffmpeg atomicparsley 2>/dev/null || sudo pacman -S --needed --noconfirm yt-dlp ffmpeg || true

echo "ℹ️ Configurando motor JavaScript (Deno) para descifrado de firmas..."
if command -v mise &> /dev/null; then
    echo "✅ Instalando Deno vía mise..."
    mise use --global deno@latest
elif command -v pacman &> /dev/null; then
    sudo pacman -S --needed --noconfirm deno 2>/dev/null || sudo pacman -S --needed --noconfirm nodejs || true
fi

echo "✅ Entorno multimedia preparado en Manjaro."
echo "💡 Usa los comandos: ytvideo, ytaudio, ytlista para descargar contenido."
