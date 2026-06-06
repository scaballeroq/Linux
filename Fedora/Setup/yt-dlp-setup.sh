#!/bin/bash
# yt-dlp-setup.sh - Instalación de dependencias para yt-dlp y multimedia (DNF5 Optimized)

set -e

echo "ℹ️ Instalando yt-dlp y FFMPEG vía DNF5..."
# ffmpeg es esencial para la mezcla de streams y conversión de audio
sudo dnf5 install -y yt-dlp ffmpeg

echo "ℹ️ Configurando motor JavaScript (Deno) vía Mise..."
# yt-dlp utiliza motores JS para descifrar algoritmos de YouTube (n-challenge).
# Deno es la opción recomendada por rendimiento.
if command -v mise &> /dev/null; then
    echo "✅ Instalando Deno vía mise..."
    mise use --global deno@latest
else
    echo "⚠️ 'mise' no detectado. Instalando Deno a nivel de sistema como respaldo..."
    sudo dnf5 install -y deno || sudo dnf5 install -y nodejs
fi

echo "✅ Entorno multimedia preparado."
echo "💡 Usa los comandos: ytvideo, ytaudio, ytlista para descargar."
