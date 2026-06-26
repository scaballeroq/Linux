#!/bin/bash
# post-install.sh - Optimización de Pacman, actualización, AUR, Codecs y Flathub

set -e

echo "🚀 Iniciando configuración base de Arch Linux Workstation (GNOME Optimized)..."

# 1. Optimización Pacman
echo "ℹ️ Configurando Pacman..."
if [ -f /etc/pacman.conf ]; then
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
    sudo sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
fi

# 2. Actualización Base
echo "ℹ️ Actualizando sistema con Pacman..."
sudo pacman -Syu --noconfirm

# 3. Habilitar multilib (si no está habilitado)
echo "ℹ️ Habilitando repositorio multilib..."
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Syu --noconfirm
fi

# 4. Instalar base-devel y herramientas esenciales
echo "ℹ️ Instalando base-devel y herramientas de desarrollo..."
sudo pacman -S --noconfirm base-devel git wget curl

# 5. Instalar Yay (AUR Helper)
echo "ℹ️ Instalando Yay (AUR Helper)..."
if ! command -v yay &> /dev/null; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd /tmp
    rm -rf yay
fi

# 6. Flatpak + Flathub Completo
echo "ℹ️ Configurando Flathub..."
sudo pacman -S --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 7. Software Esencial
echo "ℹ️ Instalando utilidades esenciales..."
sudo pacman -S --noconfirm cmake curl btop htop inxi fuse2 exfatprogs hfsprogs vlc gimp gparted p7zip unrar zip unzip bzip2 xz

# 8. Multimedia Codecs
echo "ℹ️ Configurando codecs multimedia..."
sudo pacman -S --noconfirm ffmpeg gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav libdvdread libdvdnav lsdvd

# 9. Aceleración HW
echo "ℹ️ Configurando aceleración de hardware de video (Mesa)..."
sudo pacman -S --noconfirm libva-mesa-driver lib32-libva-mesa-driver || true

echo "✅ Sistema base configurado correctamente (Se recomienda reiniciar)"
