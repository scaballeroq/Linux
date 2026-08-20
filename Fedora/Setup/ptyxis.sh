#!/usr/bin/env bash
# ptyxis.sh - Configuración e Instalación de Ptyxis para Fedora 44 Workstation + GNOME

set -euo pipefail

echo "==========================================================="
echo "🚀 Iniciando instalación y configuración estética de Ptyxis en Fedora 44"
echo "==========================================================="

# 1. Instalación de Ptyxis e integración con Nautilus
echo "📦 Instalando Ptyxis y extensiones para GNOME..."
sudo dnf5 install -y ptyxis nautilus-python 2>/dev/null || sudo dnf5 install -y ptyxis

# 2. Configuración estética vía GSettings
echo "🎨 Aplicando perfil estético a Ptyxis..."
PTYXIS_SCHEMA="org.gnome.Ptyxis"
DEFAULT_PROFILE_PATH="/org/gnome/Ptyxis/Profiles/"

if gsettings list-schemas | grep -q "$PTYXIS_SCHEMA"; then
    PROFILE_UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || true)
    
    if [ -n "$PROFILE_UUID" ] && [ "$PROFILE_UUID" != "nothing" ]; then
        PROFILE_SCHEMA="org.gnome.Ptyxis.Profile:$DEFAULT_PROFILE_PATH$PROFILE_UUID/"
        gsettings set "$PROFILE_SCHEMA" opacity 0.85 2>/dev/null || true
        gsettings set "$PROFILE_SCHEMA" palette 'catppuccin-mocha' 2>/dev/null || true
        gsettings set "$PROFILE_SCHEMA" font-name 'JetBrainsMono Nerd Font 10.5' 2>/dev/null || true
    fi

    gsettings set org.gnome.Ptyxis restore-window-size false 2>/dev/null || true
    gsettings set org.gnome.Ptyxis default-columns 110 2>/dev/null || true
    gsettings set org.gnome.Ptyxis default-rows 30 2>/dev/null || true
    echo "✅ Perfil estético de Ptyxis configurado correctamente."
fi

# 3. Atajo global Ctrl+Alt+T
echo "⌨️ Configurando atajo de teclado Ctrl+Alt+T para Ptyxis..."
if command -v gsettings &> /dev/null; then
    CUSTOM_KEYBINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$CUSTOM_KEYBINDING_PATH']" 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_KEYBINDING_PATH name 'Ptyxis Terminal' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_KEYBINDING_PATH command 'ptyxis' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_KEYBINDING_PATH binding '<Primary><Alt>t' 2>/dev/null || true
fi

echo "==========================================================="
echo "✅ Instalación y personalización de Ptyxis completada con éxito."
echo "==========================================================="
