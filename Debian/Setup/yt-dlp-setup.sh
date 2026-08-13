#!/bin/bash
# yt-dlp-setup.sh - Instalación de dependencias para yt-dlp y multimedia para Debian

set -e

# Detectar codename de Debian y si es Testing/Unstable/Forky
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || echo "bookworm")
IS_TESTING=false
if [[ "$CODENAME" =~ ^(testing|sid|unstable|forky)$ ]] || grep -q -i -E "testing|unstable|sid|forky" /etc/os-release 2>/dev/null; then
    IS_TESTING=true
fi

APT_TARGET_FLAG=()
if [ "$IS_TESTING" = false ]; then
    APT_TARGET_FLAG=("-t" "${CODENAME}-backports")
fi

echo "ℹ️ Instalando yt-dlp y FFMPEG vía APT..."
# ffmpeg es esencial para la mezcla de streams y conversión de audio
sudo apt update
sudo apt install -y ${APT_TARGET_FLAG+"${APT_TARGET_FLAG[@]}"} yt-dlp ffmpeg 2>/dev/null || sudo apt install -y yt-dlp ffmpeg

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
