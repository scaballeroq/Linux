#!/usr/bin/env bash
# ==============================================================================
# ptyxis.sh - Configuración Estética de Ptyxis (Terminal GNOME Container-Aware)
# Fedora Workstation (GNOME Shell Wayland)
# ==============================================================================
# Aplica tema oscuro, opacidad al 85% y ocultamiento de scrollbar para
# un diseño minimalista y moderno integrado con contenedores Podman.
# ==============================================================================

set -euo pipefail

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="/usr/local/bin:/usr/bin:/bin:$PATH" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
💻 Configuración Estética de Ptyxis - Fedora Workstation (GNOME)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica interfaz oscura, transparencia (0.85) y oculta la scrollbar.
  --status, -s        Muestra la configuración actual de Ptyxis en GSettings.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO ESTÉTICO DE PTYXIS - FEDORA WORKSTATION"
    echo "================================================================="
    echo "• Estilo de interfaz:     $(run_as_user gsettings get org.gnome.Ptyxis interface-style 2>/dev/null || echo 'n/a')"
    echo "• Política de scrollbar:  $(run_as_user gsettings get org.gnome.Ptyxis scrollbar-policy 2>/dev/null || echo 'n/a')"
    local profile_uuid
    profile_uuid=$(run_as_user gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || true)
    if [ -n "$profile_uuid" ]; then
        echo "• Perfil por defecto:     $profile_uuid"
        echo "• Opacidad de perfil:     $(run_as_user gsettings get "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${profile_uuid}/" opacity 2>/dev/null || echo 'n/a')"
    fi
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🎨 Aplicando configuración estética a Ptyxis (GNOME Terminal)"
echo "================================================================="

PROFILE_UUID=$(run_as_user gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || true)

if [ -n "$PROFILE_UUID" ]; then
    run_as_user gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${PROFILE_UUID}/" opacity 0.85 2>/dev/null || true
fi

run_as_user gsettings set org.gnome.Ptyxis interface-style 'dark' 2>/dev/null || true
run_as_user gsettings set org.gnome.Ptyxis scrollbar-policy 'never' 2>/dev/null || true

echo "✅ Configuración estética aplicada con éxito (oscuro, opacidad 85%, sin scrollbar)."
