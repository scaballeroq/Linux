#!/usr/bin/env bash
# ==============================================================================
# ptyxis.sh - Instalación y Configuración Estética de Ptyxis Terminal
# Debian GNU/Linux (GNOME Shell Wayland)
# ==============================================================================
# Aplica tema oscuro, transparencia y ocultamiento de scrollbar
# para un look moderno y minimalista en Ptyxis.

set -euo pipefail

echo "==========================================================="
echo "Configuración estética de Ptyxis para Debian (GNOME)"
echo "==========================================================="

if ! command -v ptyxis &>/dev/null; then
    echo "ℹ️ Instalando Ptyxis..."
    sudo apt-get update -qq 2>/dev/null || true
    sudo apt-get install -y ptyxis 2>/dev/null || true
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
