#!/bin/bash
# post-install.sh - Script maestro de configuración post-instalación para Kubuntu
# Compatible con Kubuntu 24.04 LTS, 24.10 y 26.04 LTS (KDE Plasma)

set -euo pipefail

# Detectar versión de Kubuntu/Ubuntu
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "plucky")
fi

echo "🚀 Iniciando configuración base de Kubuntu ($CODENAME)..."

# 1. Actualización Base
echo "ℹ️ Actualizando lista de paquetes..."
sudo apt update

echo "ℹ️ Actualizando sistema..."
sudo apt upgrade -y

# 2. Habilitar Repositorios Extra (Universe, Multiverse y Restricted)
echo "ℹ️ Habilitando repositorios universe, multiverse y restricted..."
sudo add-apt-repository -y universe
sudo add-apt-repository -y multiverse
sudo add-apt-repository -y restricted

sudo apt update

# 3. Software Esencial
echo "ℹ️ Instalando utilidades esenciales y soporte Flatpak para Discover..."
# Pre-aceptar la licencia de ttf-mscorefonts-installer para instalación desatendida
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections

sudo apt install -y build-essential linux-headers-$(uname -r) cmake curl wget btop htop inxi \
    fuse3 libfuse2t64 exfatprogs vlc gimp gparted p7zip unrar zip unzip bzip2 xz-utils \
    flatpak plasma-discover-backend-flatpak ca-certificates gnupg software-properties-common

# 4. Configurar Flathub en Discover
if command -v flatpak &> /dev/null; then
    echo "ℹ️ Configurando repositorio Flathub..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
fi

# 5. Multimedia Codecs
echo "ℹ️ Instalando codecs multimedia (Kubuntu Restricted Extras)..."
# Se configura la instalación no interactiva de apt para evitar prompts
sudo DEBIAN_FRONTEND=noninteractive apt install -y kubuntu-restricted-extras libavcodec-extra ffmpeg

# 6. Aceleración HW
echo "ℹ️ Instalando drivers de aceleración de hardware (Mesa/VA-API)..."
sudo apt install -y mesa-va-drivers mesa-vdpau-drivers

# 7. Limpieza Inicial
echo "ℹ️ Limpiando paquetes innecesarios..."
sudo apt autoremove -y
sudo apt clean

echo "✅ Sistema base de Kubuntu configurado correctamente (Se recomienda reiniciar)."
