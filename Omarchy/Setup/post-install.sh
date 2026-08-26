#!/bin/bash
# post-install.sh - Paquetes adicionales, utilidades y aceleración para Omarchy

set -e

echo "🚀 Iniciando configuración post-instalación para Omarchy..."

# 1. Configuración del repositorio Chaotic-AUR
echo "ℹ️ Configurando repositorio Chaotic-AUR..."
if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
    echo "🔑 Añadiendo llaves de Chaotic-AUR..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB

    echo "📦 Instalando chaotic-keyring y chaotic-mirrorlist..."
    sudo pacman -U --needed --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    echo "📝 Añadiendo [chaotic-aur] a /etc/pacman.conf..."
    sudo tee -a /etc/pacman.conf > /dev/null << 'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF

    echo "🔄 Actualizando bases de datos de pacman..."
    sudo pacman -Sy
else
    echo "✔️ El repositorio Chaotic-AUR ya está configurado en /etc/pacman.conf."
fi

# 2. Utilidades de sistema y sistemas de archivos
echo "ℹ️ Instalando utilidades del sistema y compresión..."
sudo pacman -S --needed --noconfirm inxi exfatprogs p7zip unrar

# 3. Aplicaciones GUI adicionales
echo "ℹ️ Instalando aplicaciones adicionales de escritorio..."
sudo pacman -S --needed --noconfirm gimp gparted vlc

# 4. Codecs Multimedia extendidos (GStreamer)
echo "ℹ️ Configurando codecs multimedia..."
sudo pacman -S --needed --noconfirm \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav

# 5. Aceleración de video por Hardware para AMD (Mesa / VA-API)
echo "ℹ️ Configurando aceleración de hardware de video (Mesa AMD)..."
sudo pacman -S --needed --noconfirm libva-mesa-driver lib32-libva-mesa-driver || true

# 6. Flatpak (Descomentar si deseas usar aplicaciones de Flathub)
# echo "ℹ️ Configurando Flatpak..."
# sudo pacman -S --needed --noconfirm flatpak
# flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "✅ Configuración post-install de Omarchy completada."

