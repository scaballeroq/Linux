#!/bin/bash
# post-install.sh - Optimización de DNF5, actualización, RPMFusion, Codecs y Flathub

set -e

echo "🚀 Iniciando configuración base de Fedora Workstation (KDE Optimized)..."

# 1. Optimización DNF5 (DNF5 ya es rápido por defecto, pero mantenemos paralelismo)
echo "ℹ️ Configurando DNF5..."
if [ -f /etc/dnf/dnf.conf ]; then
    if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
        echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
    fi
fi

# 2. Actualización Base
echo "ℹ️ Actualizando sistema con DNF5..."
sudo dnf5 update -y

# 3. RPMFusion
echo "ℹ️ Habilitando RPM Fusion..."
sudo dnf5 install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf5 install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data

# 4. System Upgrade
echo "ℹ️ Refrescando paquetes..."
sudo dnf5 upgrade --refresh -y

# 5. Flatpak + Flathub Completo
echo "ℹ️ Configurando Flathub..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 6. Software Esencial (Removido gnome-software, exfat-utils -> exfatprogs)
echo "ℹ️ Instalando utilidades esenciales..."
sudo dnf5 install -y @development-tools kernel-devel kernel-headers cmake curl btop htop inxi fuse-libs exfatprogs hfsplus-tools vlc gimp gparted p7zip p7zip-plugins unrar zip unzip bzip2 xz flatpak

# 7. Multimedia Codecs
echo "ℹ️ Configurando codecs multimedia..."
sudo dnf5 config-manager setopt fedora-cisco-openh264.enabled=1
sudo dnf5 swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf5 update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
sudo dnf5 install -y libdvdread libdvdnav lsdvd

# 8. Aceleración HW
echo "ℹ️ Configurando aceleración de hardware de video (Mesa)..."
sudo dnf5 install -y mesa-va-drivers-freeworld mesa-va-drivers-freeworld.i686 || true

echo "✅ Sistema base configurado correctamente (Se recomienda reiniciar)"
