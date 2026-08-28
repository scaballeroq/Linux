#!/bin/bash
# apariencia.sh - Instalación de temas, iconos y homogeneización visual para Fedora 44 + KDE Plasma 6
#
# Uso:
#   ./apariencia.sh                  -> Instala paquetes y aplica tema oscuro recomendado (Breeze Dark + Papirus-Dark)
#   ./apariencia.sh --dark           -> Aplica tema global Breeze Dark e iconos Papirus-Dark
#   ./apariencia.sh --light          -> Aplica tema global Breeze Light e iconos Papirus
#   ./apariencia.sh --papirus        -> Aplica iconos Papirus-Dark
#   ./apariencia.sh --breeze-icons   -> Aplica iconos Breeze-Dark oficiales
#   ./apariencia.sh --status         -> Muestra el estado visual actual (KDE Plasma y GTK)
#   ./apariencia.sh --list           -> Muestra temas globales, esquemas de color e iconos disponibles
#   ./apariencia.sh --no-install     -> Aplica configuración visual omitiendo descarga de paquetes DNF5
#   ./apariencia.sh --help           -> Muestra la ayuda interactiva

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

show_help() {
    cat <<EOF
🎨 Gestor de Apariencia y Homogeneización Visual - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala paquetes y aplica el tema oscuro recomendado (Breeze Dark + Papirus-Dark).
  --dark, -d             Aplica tema global Breeze Dark e iconos Papirus-Dark.
  --light, -l            Aplica tema global Breeze Light e iconos Papirus (modo claro).
  --papirus              Aplica tema de iconos Papirus-Dark en KDE Plasma y GTK.
  --breeze-icons         Aplica tema de iconos Breeze-Dark en KDE Plasma y GTK.
  --status               Muestra el estado visual actual (Look & Feel, ColorScheme, Iconos, GTK).
  --list                 Lista temas globales, esquemas de color e iconos instalados.
  --no-install           Aplica los temas y configuraciones omitiendo la descarga de paquetes DNF5.
  --help, -h             Muestra este mensaje de ayuda.
EOF
}

# 1. Instalación de paquetes esenciales para KDE Plasma 6 y GTK
install_packages() {
    echo "📦 [1/4] Verificando e instalando paquetes de temas, iconos e integración GTK/Qt..."
    $SUDO dnf5 install -y \
        papirus-icon-theme \
        breeze-icon-theme \
        breeze-cursor-theme \
        breeze-gtk-gtk3 \
        breeze-gtk-gtk4 \
        breeze-gtk-common \
        kde-gtk-config \
        adwaita-icon-theme \
        xdg-desktop-portal-kde 2>/dev/null || true
    echo "✅ Paquetes de personalización e integración listos."
}

# 2. Listar temas e iconos disponibles
list_themes() {
    echo "================================================================="
    echo "🎨 TEMAS GLOBALES (LOOK AND FEEL) DISPONIBLES EN KDE PLASMA"
    echo "================================================================="
    if command -v plasma-apply-lookandfeel &>/dev/null; then
        plasma-apply-lookandfeel -l 2>/dev/null || true
    fi
    echo ""
    echo "================================================================="
    echo "🌈 ESQUEMAS DE COLOR DISPONIBLES EN KDE PLASMA"
    echo "================================================================="
    if command -v plasma-apply-colorscheme &>/dev/null; then
        plasma-apply-colorscheme -l 2>/dev/null || true
    fi
    echo ""
    echo "================================================================="
    echo "🖼️ TEMAS DE ICONOS INSTALADOS EN EL SISTEMA"
    echo "================================================================="
    ls -d /usr/share/icons/*/ "$USER_HOME/.local/share/icons/"*/ 2>/dev/null | xargs -n1 basename | sort -u | grep -vE 'default|hicolor|locolor' || true
    echo ""
}

# 3. Mostrar configuración activa actual
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO VISUAL ACTUAL (KDE PLASMA 6 & GTK INTEGRATION)"
    echo "================================================================="
    echo "• Tema de iconos KDE:      $(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null || echo 'Breeze')"
    echo "• Esquema de color KDE:    $(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || echo 'Desconocido')"
    echo "• Tema de cursor KDE:      $(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null || echo 'breeze_cursors')"
    if command -v gsettings &>/dev/null; then
        echo "• GTK Scheme (gsettings):  $(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
        echo "• GTK Theme (gsettings):   $(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'n/a')"
        echo "• GTK Icons (gsettings):   $(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'n/a')"
        echo "• GTK Cursor (gsettings):  $(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo 'n/a')"
    fi
    echo "================================================================="
}

# 4. Aplicar configuración de apariencia
apply_appearance() {
    local MODE="${1:-dark}"
    local ICON_THEME="${2:-Papirus-Dark}"

    local LOOK_AND_FEEL="org.kde.breezedark.desktop"
    local COLOR_SCHEME="BreezeDark"
    local GTK_THEME="Breeze-Dark"
    local PREFER_DARK="prefer-dark"
    local CURSOR_THEME="breeze_cursors"

    if [ "$MODE" = "light" ]; then
        LOOK_AND_FEEL="org.kde.breeze.desktop"
        COLOR_SCHEME="BreezeLight"
        GTK_THEME="Breeze"
        PREFER_DARK="default"
        [ "$ICON_THEME" = "Papirus-Dark" ] && ICON_THEME="Papirus"
    fi

    echo "🎨 [2/4] Aplicando Tema Global KDE Plasma ($LOOK_AND_FEEL) y Esquema ($COLOR_SCHEME)..."
    if command -v plasma-apply-lookandfeel &>/dev/null; then
        plasma-apply-lookandfeel -a "$LOOK_AND_FEEL" 2>/dev/null || true
    fi

    if command -v plasma-apply-colorscheme &>/dev/null; then
        plasma-apply-colorscheme "$COLOR_SCHEME" 2>/dev/null || true
    fi

    echo "🖼️ [3/4] Configurando tema de iconos ($ICON_THEME) y cursores ($CURSOR_THEME)..."
    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ICON_THEME" --notify 2>/dev/null || true
        kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$COLOR_SCHEME" --notify 2>/dev/null || true
        kwriteconfig6 --file kdeglobals --group KDE --key colorScheme "$COLOR_SCHEME" --notify 2>/dev/null || true
    fi

    if command -v plasma-apply-cursortheme &>/dev/null; then
        plasma-apply-cursortheme "$CURSOR_THEME" 2>/dev/null || true
    fi

    echo "🔗 [4/4] Sincronizando integración para aplicaciones GTK 3, GTK 4 y Flatpaks..."
    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file gtkrc-2.0 --group Settings --key gtk-theme-name "$GTK_THEME" 2>/dev/null || true
        kwriteconfig6 --file gtkrc-2.0 --group Settings --key gtk-icon-theme-name "$ICON_THEME" 2>/dev/null || true
    fi

    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface color-scheme "$PREFER_DARK" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
    fi

    # Notificar a los entornos para actualizar en caliente
    if command -v dbus-send &>/dev/null; then
        dbus-send --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi

    echo ""
    echo "✅ Apariencia para KDE Plasma 6 y sincronización GTK/Qt configurada correctamente."
    echo "💡 Modo aplicado: $COLOR_SCHEME | Iconos: $ICON_THEME | GTK Theme: $GTK_THEME"
}

# Procesar argumentos
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --list|-l|list)
        list_themes
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --light|light)
        install_packages
        apply_appearance "light" "Papirus"
        ;;
    --dark|dark)
        install_packages
        apply_appearance "dark" "Papirus-Dark"
        ;;
    --papirus)
        install_packages
        apply_appearance "dark" "Papirus-Dark"
        ;;
    --breeze-icons)
        install_packages
        apply_appearance "dark" "breeze-dark"
        ;;
    --no-install)
        apply_appearance "dark" "Papirus-Dark"
        ;;
    "")
        echo "================================================================="
        echo "🎨 CONFIGURADOR DE APARIENCIA - FEDORA 44 (KDE PLASMA 6)"
        echo "================================================================="
        install_packages
        apply_appearance "dark" "Papirus-Dark"
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
