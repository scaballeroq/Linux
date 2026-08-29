#!/bin/bash
# ptyxis.sh - Configuración estética de Ptyxis para CachyOS

set -euo pipefail

echo "==========================================================="
echo "Aplicando configuración estética a Ptyxis"
echo "==========================================================="

if ! command -v ptyxis &>/dev/null; then
    echo "ℹ️ Instalando Ptyxis terminal..."
    sudo pacman -S --needed --noconfirm ptyxis
fi

# Obtener el UUID del perfil por defecto
PROFILE_UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || true)

if [ -n "$PROFILE_UUID" ]; then
    # Configurar opacidad al 85% (ligeramente transparente)
    gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${PROFILE_UUID}/" opacity 0.85 || true
fi

# Forzar interfaz oscura para un look más moderno
gsettings set org.gnome.Ptyxis interface-style 'dark' || true

# Ocultar la barra de desplazamiento para un diseño más limpio y minimalista
gsettings set org.gnome.Ptyxis scrollbar-policy 'never' || true

echo "==========================================================="
echo "¡Configuración estética aplicada con éxito!"
echo "Ptyxis ahora tiene un look moderno (oscuro y transparente)."
echo "==========================================================="
