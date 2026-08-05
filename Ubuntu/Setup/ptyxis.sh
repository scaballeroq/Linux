#!/usr/bin/env bash
#
# Configuración estética de Ptyxis
# 
# Aplica tema oscuro, transparencia y ocultamiento de scrollbar
# para un look moderno y minimalista en Ptyxis.
# Ptyxis ya viene instalado por defecto en Ubuntu 26.04.

set -euo pipefail

echo "==========================================================="
echo "Aplicando configuración estética a Ptyxis"
echo "==========================================================="

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
