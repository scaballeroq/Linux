#!/bin/bash
# =============================================================================
# apariencia.sh - Temas, Iconos y Estética para Kubuntu (KDE Plasma 6)
# =============================================================================
# - Instala paquetes de iconos y cursores (Papirus, Breeze, Fondos Kubuntu)
# - Aplica el tema global Kubuntu Dark (org.kubuntudark.desktop)
# - Configura tema de iconos y cursores mediante kwriteconfig6
# =============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

set_kconfig() {
    local file="$1"
    local group="$2"
    local key="$3"
    local value="$4"

    if command -v kwriteconfig6 &>/dev/null; then
        run_as_user kwriteconfig6 --file "$file" --group "$group" --key "$key" "$value" 2>/dev/null || true
    elif command -v kwriteconfig5 &>/dev/null; then
        run_as_user kwriteconfig5 --file "$file" --group "$group" --key "$key" "$value" 2>/dev/null || true
    fi
}

show_help() {
    cat <<EOF
Personalizador de Apariencia - Kubuntu (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala paquetes de temas/iconos y aplica Kubuntu Dark + Papirus/Breeze.
  --status, -s           Muestra el tema global, paquete de iconos y cursor activo.
  --papirus              Aplica tema de iconos Papirus-Dark.
  --breeze               Aplica tema de iconos Breeze-Dark.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE APARIENCIA - KUBUNTU (KDE PLASMA 6)"
    echo "================================================================="
    echo "Usuario:                       $REAL_USER"
    echo "Tema Global (Look & Feel):     $(if command -v kreadconfig6 &>/dev/null; then run_as_user kreadconfig6 --file kdeglobals --group General --key lookAndFeelPackage 2>/dev/null || echo 'org.kubuntudark.desktop'; else echo 'n/a'; fi)"
    echo "Tema de Iconos:                $(if command -v kreadconfig6 &>/dev/null; then run_as_user kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null || echo 'breeze-dark'; else echo 'n/a'; fi)"
    echo "Tema de Cursor:                $(if command -v kreadconfig6 &>/dev/null; then run_as_user kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null || echo 'breeze_cursors'; else echo 'n/a'; fi)"
    echo "Tamaño de Cursor:              $(if command -v kreadconfig6 &>/dev/null; then run_as_user kreadconfig6 --file kcminputrc --group Mouse --key cursorSize 2>/dev/null || echo '24'; else echo 'n/a'; fi)"
    echo "================================================================="
}

install_packages() {
    echo "ℹ️ [1/3] Instalando paquetes de temas, iconos y fondos..."
    $SUDO apt update
    $SUDO apt install -y \
        papirus-icon-theme \
        breeze-icon-theme \
        breeze-cursor-theme \
        kubuntu-wallpapers \
        plasma-workspace-wallpapers \
        2>/dev/null || true
    echo "✅ Paquetes de temas instalados."
}

apply_appearance() {
    local ICON_THEME="${1:-Papirus-Dark}"
    echo "ℹ️ [2/3] Aplicando tema global Kubuntu Dark..."

    if command -v lookandfeeltool &> /dev/null; then
        run_as_user lookandfeeltool -a org.kubuntudark.desktop 2>/dev/null || \
        run_as_user lookandfeeltool -a org.kde.breezedark.desktop 2>/dev/null || true
    fi

    echo "ℹ️ [3/3] Configurando tema de iconos ($ICON_THEME) y cursor (breeze_cursors)..."
    set_kconfig "kdeglobals" "Icons" "Theme" "$ICON_THEME"
    set_kconfig "kcminputrc" "Mouse" "cursorTheme" "breeze_cursors"
    set_kconfig "kcminputrc" "Mouse" "cursorSize" "24"

    # Recargar KWin y Plasma
    if command -v qdbus6 &>/dev/null; then
        run_as_user qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    fi

    echo ""
    echo "================================================================="
    echo "✅ Apariencia de Kubuntu configurada correctamente."
    echo "================================================================="
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --papirus)
        install_packages
        apply_appearance "Papirus-Dark"
        ;;
    --breeze)
        install_packages
        apply_appearance "breeze-dark"
        ;;
    "")
        echo "================================================================="
        echo "CONFIGURANDO TEMAS E ICONOS - KUBUNTU"
        echo "================================================================="
        install_packages
        apply_appearance "Papirus-Dark"
        show_status
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
