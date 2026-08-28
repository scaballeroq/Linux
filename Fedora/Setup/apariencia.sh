#!/bin/bash
# apariencia.sh - Instalación de temas, iconos, Kvantum (SVG) y homogeneización visual para Fedora 44 + KDE Plasma 6
#
# Uso:
#   ./apariencia.sh                  -> Instala paquetes y aplica tema oscuro con Kvantum (KvFlatDark + Papirus-Dark)
#   ./apariencia.sh --dark           -> Aplica tema global Breeze Dark, Kvantum KvFlatDark e iconos Papirus-Dark
#   ./apariencia.sh --light          -> Aplica tema global Breeze Light, Kvantum KvFlatLight e iconos Papirus
#   ./apariencia.sh --kvantum-theme  -> Aplica un tema específico de Kvantum (ej. KvMojaveDark, KvArcDark, MateriaDark)
#   ./apariencia.sh --breeze-widgets -> Aplica widgets nativos de KDE Plasma (Breeze) en lugar de Kvantum
#   ./apariencia.sh --papirus        -> Aplica iconos Papirus-Dark
#   ./apariencia.sh --breeze-icons   -> Aplica iconos Breeze-Dark oficiales
#   ./apariencia.sh --status         -> Muestra el estado visual actual (KDE Plasma, Kvantum y GTK)
#   ./apariencia.sh --list           -> Muestra temas globales, esquemas de color, iconos y temas Kvantum
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

# Ejecutar comandos de configuración en el contexto del usuario real
run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
🎨 Gestor de Apariencia y Homogeneización Visual - Fedora 44 (KDE Plasma 6 + Kvantum)

Uso:
  $0 [OPCIÓN]

Opciones principales:
  (sin argumentos)              Instala paquetes y aplica tema oscuro con Kvantum (KvFlatDark + Papirus-Dark).
  --dark, -d                    Aplica tema oscuro con Kvantum (KvFlatDark + BreezeDark + Papirus-Dark).
  --light, -l                   Aplica tema claro con Kvantum (KvFlatLight + BreezeLight + Papirus).
  --kvantum, -k                 Activa Kvantum como motor de widgets (tema por defecto: KvFlatDark).
  --kvantum-theme <TEMA>        Activa Kvantum y aplica un tema SVG específico (ej. KvMojaveDark, MateriaDark).
  --breeze-widgets, --breeze    Restablece el estilo de widgets nativo de KDE (Breeze) sin Kvantum.
  --papirus                     Aplica tema de iconos Papirus-Dark en KDE Plasma y GTK.
  --breeze-icons                Aplica tema de iconos Breeze-Dark en KDE Plasma y GTK.
  --status, -s                  Muestra el estado visual actual (Look & Feel, Kvantum, ColorScheme, Iconos, GTK).
  --list                        Lista temas globales, esquemas de color, iconos y temas Kvantum disponibles.
  --no-install                  Aplica los temas y configuraciones omitiendo la descarga de paquetes DNF5.
  --help, -h                    Muestra este mensaje de ayuda.

Temas populares de Kvantum incluidos:
  KvFlatDark, KvFlatLight, KvBreezeDark, KvBreeze, KvMojaveDark, KvArcDark, MateriaDark, KvGnomeDark
EOF
}

# 1. Instalación de paquetes esenciales para KDE Plasma 6, Kvantum (Qt5/Qt6) y GTK
install_packages() {
    echo "📦 [1/4] Verificando e instalando Kvantum, temas, iconos e integración GTK/Qt..."
    $SUDO dnf5 install -y \
        kvantum \
        kvantum-qt5 \
        arc-kde-kvantum \
        materia-kde-kvantum \
        papirus-icon-theme \
        breeze-icon-theme \
        breeze-cursor-theme \
        breeze-gtk-gtk3 \
        breeze-gtk-gtk4 \
        breeze-gtk-common \
        kde-gtk-config \
        adwaita-icon-theme \
        xdg-desktop-portal-kde 2>/dev/null || true
    echo "✅ Paquetes de Kvantum, personalización e integración listos."
}

# Configuración del motor Kvantum y su tema activo
configure_kvantum() {
    local KVANTUM_THEME="${1:-KvFlatDark}"
    local KVANTUM_DIR="$USER_HOME/.config/Kvantum"
    local KVANTUM_FILE="$KVANTUM_DIR/kvantum.kvconfig"

    mkdir -p "$KVANTUM_DIR"

    # Escribir configuración de Kvantum
    cat > "$KVANTUM_FILE" <<EOF
[General]
theme=$KVANTUM_THEME
EOF

    # Asegurar permisos correctos si se ejecuta como sudo
    chown -R "$REAL_USER":"$REAL_USER" "$KVANTUM_DIR" 2>/dev/null || true

    # Si kvantummanager está disponible en la sesión gráfica, sincronizarlo
    if command -v kvantummanager &>/dev/null; then
        run_as_user kvantummanager --set "$KVANTUM_THEME" &>/dev/null || true
    fi

    echo "💠 Motor Kvantum configurado con el tema SVG: $KVANTUM_THEME"
}

# 2. Listar temas e iconos disponibles
list_themes() {
    echo "================================================================="
    echo "🎨 TEMAS GLOBALES (LOOK AND FEEL) DISPONIBLES EN KDE PLASMA"
    echo "================================================================="
    if command -v plasma-apply-lookandfeel &>/dev/null; then
        run_as_user plasma-apply-lookandfeel -l 2>/dev/null || true
    fi
    echo ""
    echo "================================================================="
    echo "🌈 ESQUEMAS DE COLOR DISPONIBLES EN KDE PLASMA"
    echo "================================================================="
    if command -v plasma-apply-colorscheme &>/dev/null; then
        run_as_user plasma-apply-colorscheme -l 2>/dev/null || true
    fi
    echo ""
    echo "================================================================="
    echo "💠 TEMAS SVG DE KVANTUM DISPONIBLES (QT5 / QT6)"
    echo "================================================================="
    {
        ls -d /usr/share/Kvantum/*/ "$USER_HOME/.config/Kvantum/"*/ 2>/dev/null | xargs -n1 basename | sort -u | grep -vE '^\.' || true
    }
    echo ""
    echo "================================================================="
    echo "🖼️ TEMAS DE ICONOS INSTALADOS EN EL SISTEMA"
    echo "================================================================="
    ls -d /usr/share/icons/*/ "$USER_HOME/.local/share/icons/"*/ 2>/dev/null | xargs -n1 basename | sort -u | grep -vE 'default|hicolor|locolor' || true
    echo ""
}

# 3. Mostrar configuración activa actual
show_status() {
    local KVANTUM_THEME="Inactivo / No configurado"
    if [ -f "$USER_HOME/.config/Kvantum/kvantum.kvconfig" ]; then
        KVANTUM_THEME=$(grep -E '^theme=' "$USER_HOME/.config/Kvantum/kvantum.kvconfig" 2>/dev/null | cut -d= -f2 || echo "Desconocido")
    fi

    echo "================================================================="
    echo "🔍 ESTADO VISUAL ACTUAL (KDE PLASMA 6, KVANTUM & GTK)"
    echo "================================================================="
    echo "• Motor de Widgets KDE:   $(run_as_user kreadconfig6 --file kdeglobals --group KDE --key widgetStyle 2>/dev/null || echo 'Breeze')"
    echo "• Tema Kvantum Activo:    $KVANTUM_THEME"
    echo "• Tema de iconos KDE:     $(run_as_user kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null || echo 'Breeze')"
    echo "• Esquema de color KDE:   $(run_as_user kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || echo 'Desconocido')"
    echo "• Tema de cursor KDE:     $(run_as_user kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null || echo 'breeze_cursors')"
    if command -v gsettings &>/dev/null; then
        echo "• GTK Scheme (gsettings): $(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
        echo "• GTK Theme (gsettings):  $(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'n/a')"
        echo "• GTK Icons (gsettings):  $(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'n/a')"
        echo "• GTK Cursor (gsettings): $(run_as_user gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo 'n/a')"
    fi
    echo "================================================================="
}

# 4. Aplicar configuración de apariencia
apply_appearance() {
    local MODE="${1:-dark}"
    local ICON_THEME="${2:-Papirus-Dark}"
    local WIDGET_STYLE="${3:-kvantum}"
    local KVANTUM_THEME="${4:-KvFlatDark}"

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
        [ "$KVANTUM_THEME" = "KvFlatDark" ] && KVANTUM_THEME="KvFlatLight"
    fi

    echo "🎨 [2/4] Aplicando Tema Global KDE Plasma ($LOOK_AND_FEEL) y Esquema ($COLOR_SCHEME)..."
    if command -v plasma-apply-lookandfeel &>/dev/null; then
        run_as_user plasma-apply-lookandfeel -a "$LOOK_AND_FEEL" 2>/dev/null || true
    fi

    if command -v plasma-apply-colorscheme &>/dev/null; then
        run_as_user plasma-apply-colorscheme "$COLOR_SCHEME" 2>/dev/null || true
    fi

    # Configuración del motor de widgets (Kvantum o Breeze)
    if [ "$WIDGET_STYLE" = "kvantum" ]; then
        configure_kvantum "$KVANTUM_THEME"
        if command -v kwriteconfig6 &>/dev/null; then
            run_as_user kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "kvantum" 2>/dev/null || true
        fi
    else
        if command -v kwriteconfig6 &>/dev/null; then
            run_as_user kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "Breeze" 2>/dev/null || true
        fi
        echo "💠 Motor de widgets establecido a: Breeze (Nativo KDE)"
    fi

    echo "🖼️ [3/4] Configurando tema de iconos ($ICON_THEME) y cursores ($CURSOR_THEME)..."
    if command -v kwriteconfig6 &>/dev/null; then
        run_as_user kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ICON_THEME" --notify 2>/dev/null || true
        run_as_user kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$COLOR_SCHEME" --notify 2>/dev/null || true
        run_as_user kwriteconfig6 --file kdeglobals --group KDE --key colorScheme "$COLOR_SCHEME" --notify 2>/dev/null || true
    fi

    if command -v plasma-apply-cursortheme &>/dev/null; then
        run_as_user plasma-apply-cursortheme "$CURSOR_THEME" 2>/dev/null || true
    fi

    echo "🔗 [4/4] Sincronizando integración para aplicaciones GTK 3, GTK 4 y Flatpaks..."
    if command -v kwriteconfig6 &>/dev/null; then
        run_as_user kwriteconfig6 --file gtkrc-2.0 --group Settings --key gtk-theme-name "$GTK_THEME" 2>/dev/null || true
        run_as_user kwriteconfig6 --file gtkrc-2.0 --group Settings --key gtk-icon-theme-name "$ICON_THEME" 2>/dev/null || true
    fi

    if command -v gsettings &>/dev/null; then
        run_as_user gsettings set org.gnome.desktop.interface color-scheme "$PREFER_DARK" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
    fi

    # Notificar al compositor KWin para refrescar decoración y efectos visuales
    if command -v dbus-send &>/dev/null; then
        run_as_user dbus-send --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi

    echo ""
    echo "✅ Apariencia para KDE Plasma 6 y sincronización GTK/Qt configurada correctamente."
    echo "💡 Motor Widgets: $WIDGET_STYLE (Kvantum: $KVANTUM_THEME) | Modo: $COLOR_SCHEME | Iconos: $ICON_THEME | GTK: $GTK_THEME"
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
        apply_appearance "light" "Papirus" "kvantum" "KvFlatLight"
        ;;
    --dark|dark)
        install_packages
        apply_appearance "dark" "Papirus-Dark" "kvantum" "KvFlatDark"
        ;;
    --kvantum|-k)
        install_packages
        apply_appearance "dark" "Papirus-Dark" "kvantum" "KvFlatDark"
        ;;
    --kvantum-light)
        install_packages
        apply_appearance "light" "Papirus" "kvantum" "KvFlatLight"
        ;;
    --kvantum-theme)
        THEME_NAME="${2:-}"
        if [ -z "$THEME_NAME" ]; then
            echo "❌ Error: Debes especificar el nombre del tema Kvantum."
            echo "Uso: $0 --kvantum-theme <NOMBRE_TEMA> (ej. KvMojaveDark, MateriaDark, KvArcDark)"
            exit 1
        fi
        install_packages
        apply_appearance "dark" "Papirus-Dark" "kvantum" "$THEME_NAME"
        ;;
    --breeze-widgets|--breeze)
        install_packages
        apply_appearance "dark" "Papirus-Dark" "Breeze" "none"
        ;;
    --papirus)
        install_packages
        apply_appearance "dark" "Papirus-Dark" "kvantum" "KvFlatDark"
        ;;
    --breeze-icons)
        install_packages
        apply_appearance "dark" "breeze-dark" "kvantum" "KvFlatDark"
        ;;
    --no-install)
        apply_appearance "dark" "Papirus-Dark" "kvantum" "KvFlatDark"
        ;;
    "")
        echo "================================================================="
        echo "🎨 CONFIGURADOR DE APARIENCIA - FEDORA 44 (KDE PLASMA 6 + KVANTUM)"
        echo "================================================================="
        install_packages
        apply_appearance "dark" "Papirus-Dark" "kvantum" "KvFlatDark"
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac

