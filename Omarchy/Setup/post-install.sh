#!/bin/bash
# post-install.sh - Paquetes adicionales, utilidades y aceleración para Omarchy

set -e

echo "🚀 Iniciando configuración post-instalación para Omarchy..."

# 1. Utilidades de sistema y sistemas de archivos
echo "ℹ️ Instalando utilidades del sistema y compresión..."
sudo pacman -S --needed --noconfirm inxi exfatprogs p7zip unrar

# 2. Aplicaciones GUI adicionales
echo "ℹ️ Instalando aplicaciones adicionales de escritorio..."
sudo pacman -S --needed --noconfirm gimp gparted vlc

# 3. Codecs Multimedia extendidos (GStreamer)
echo "ℹ️ Configurando codecs multimedia..."
sudo pacman -S --needed --noconfirm \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav

# 4. Aceleración de video por Hardware para AMD (Mesa / VA-API)
echo "ℹ️ Configurando aceleración de hardware de video (Mesa AMD)..."
sudo pacman -S --needed --noconfirm libva-mesa-driver lib32-libva-mesa-driver || true

# 5. Flatpak (Descomentar si deseas usar aplicaciones de Flathub)
# echo "ℹ️ Configurando Flatpak..."
# sudo pacman -S --needed --noconfirm flatpak
# flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "✅ Configuración post-install de Omarchy completada."

