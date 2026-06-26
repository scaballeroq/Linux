#!/bin/bash
# gnome-settings.sh - Personalización de GNOME 46+

set -e

echo "🎨 Configurando GNOME..."

if [ "$XDG_CURRENT_DESKTOP" != "GNOME" ] && [ "$DESKTOP_SESSION" != "gnome" ]; then
    echo "⚠️ Este script está diseñado para GNOME. Saltando configuración..."
    exit 0
fi

# Extensiones y herramientas
sudo pacman -S --noconfirm gnome-tweaks gnome-extensions-app

# Apariencia
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
gsettings set org.gnome.desktop.interface document-font-name 'JetBrainsMono Nerd Font 11'

# Night Light
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500

# Reloj y batería
gsettings set org.gnome.desktop.interface clock-format '24h'
gsettings set org.gnome.desktop.interface show-battery-percentage true

# Ventanas
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'

# Energía (no suspender cuando está conectado)
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

# Teclado
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']"

# Nautilus
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gsettings set org.gnome.nautilus.preferences show-delete-permanent true

# Terminal predeterminada
gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty'

echo "✅ Configuración de GNOME completada"
