#!/bin/bash
# yt-dlp-setup.sh - Instalación de dependencias para yt-dlp y multimedia para Debian Testing

set -euo pipefail

# Detectar codename de Debian
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || echo "trixie")

echo "ℹ️ Instalando yt-dlp y FFMPEG vía APT en Debian Testing ($CODENAME)..."
sudo apt update
sudo apt install -y yt-dlp ffmpeg

echo "ℹ️ Configurando motor JavaScript (Deno) vía Mise..."
# yt-dlp utiliza motores JS para descifrar algoritmos de YouTube (n-challenge).
# Deno es la opción recomendada por rendimiento.
if command -v mise &> /dev/null; then
    echo "✅ Instalando Deno vía mise..."
    mise use --global deno@latest
else
    echo "⚠️ 'mise' no detectado. Instalando NodeJS a nivel de sistema como respaldo..."
    sudo apt install -y nodejs
fi

echo "✅ Entorno multimedia preparado."
echo "💡 Usa los comandos: ytvideo, ytaudio, ytlista para descargar."
