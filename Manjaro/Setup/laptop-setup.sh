#!/bin/bash
# laptop-setup.sh - Optimización para portátiles de desarrollo en Manjaro Linux + GNOME

set -euo pipefail

echo "🚀 Iniciando optimización para portátil de desarrollo en Manjaro Linux + GNOME..."

# 1. Herramientas de Hardware y Conectividad
echo "ℹ️ Instalando servicios de energía, bluetooth y gráficos híbridos vía Pacman..."
sudo pacman -S --needed --noconfirm \
    power-profiles-daemon \
    switcheroo-control \
    bluez \
    bluez-utils \
    brightnessctl \
    pacman-mirrors

# Habilitar servicios clave de portátil
echo "ℹ️ Habilitando servicios systemd para portátil..."
sudo systemctl enable --now bluetooth.service || true
sudo systemctl enable --now power-profiles-daemon.service || true
sudo systemctl enable --now switcheroo-control.service || true

# 2. Extensiones de GNOME útiles para portátil
echo "ℹ️ Instalando extensiones recomendadas de GNOME para portátil..."
sudo pacman -S --needed --noconfirm \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine 2>/dev/null || true

# 3. Configuraciones de GSettings para Portátil (Touchpad, Pantalla y Energía)
if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
    echo "ℹ️ Aplicando configuraciones de Touchpad y pantalla para GNOME..."

    # Gestos y Touchpad
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true

    # Escalado Fraccional y Tasa de Refresco Variable (VRR)
    gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate']" 2>/dev/null || true

    # Comportamiento de energía en batería
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1200 2>/dev/null || true
    gsettings set org.gnome.desktop.privacy idle-delay 600 2>/dev/null || true
fi

echo "✅ Configuración de portátil aplicada correctamente en Manjaro."
echo "💡 Recuerda reiniciar la sesión para que todos los cambios de GNOME entren en vigor."
