#!/bin/bash
# ==============================================================================
# apariencia.sh - Instalacion de temas, iconos, Kvantum (Qt5/Qt6) y sincronizacion visual para CachyOS + KDE Plasma 6
# ==============================================================================
#
# Uso:
#   ./apariencia.sh                  -> Instala paquetes (Kvantum Qt5/Qt6, temas) y aplica tema oscuro optimizado (KvDark + Papirus-Dark)
#   ./apariencia.sh --dark, -d       -> Aplica tema oscuro con Kvantum (KvDark + BreezeDark + Papirus-Dark)
#   ./apariencia.sh --light, -l      -> Aplica tema claro con Kvantum (KvFlatLight + BreezeLight + Papirus)
#   ./apariencia.sh --kvantum-theme <TEMA> -> Aplica un tema SVG especifico de Kvantum (ej. KvArcDark, KvAdaptaDark, KvMojave, MateriaDark)
#   ./apariencia.sh --breeze-widgets -> Restablece el estilo nativo de widgets de KDE Plasma 6 (Breeze) sin Kvantum
#   ./apariencia.sh --papirus        -> Aplica iconos Papirus-Dark en KDE Plasma y GTK
#   ./apariencia.sh --breeze-icons   -> Aplica iconos Breeze-Dark oficiales
#   ./apariencia.sh --status, -s     -> Diagnostica el estado visual (Kvantum Qt5/Qt6, temas, esquemas y GTK)
#   ./apariencia.sh --list, -l       -> Muestra temas globales, esquemas de color, iconos y temas Kvantum disponibles
#   ./apariencia.sh --no-install     -> Aplica la configuracion visual omitiendo la descarga de paquetes
#   ./apariencia.sh --help, -h       -> Muestra la ayuda interactiva
#
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no esta disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecucion con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

# Ejecutar comandos de configuracion en el contexto del usuario real
run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# Helper para escribir configuraciones de KDE Plasma de manera segura
set_kde_config() {
    local file="$1"
    local group="$2"
    local key="$3"
    local val="$4"

    if command -v kwriteconfig6 &>/dev/null; then
        run_as_user kwriteconfig6 --file "$file" --group "$group" --key "$key" "$val"
    elif command -v kwriteconfig5 &>/dev/null; then
        run_as_user kwriteconfig5 --file "$file" --group "$group" --key "$key" "$val"
    else
        local target="$USER_HOME/.config/$file"
        run_as_user mkdir -p "$(dirname "$target")"
        if [ ! -f "$target" ]; then
            run_as_user touch "$target"
        fi
        if grep -q "^\[$group\]" "$target" 2>/dev/null; then
            if grep -A 100 "^\[$group\]" "$target" | grep -q "^$key="; then
                sed -i "/^\[$group\]/,/^\[/ s|^$key=.*|$key=$val|" "$target"
            else
                sed -i "/^\[$group\]/a $key=$val" "$target"
            fi
        else
            printf "\n[%s]\n%s=%s\n" "$group" "$key" "$val" >> "$target"
        fi
    fi
}

show_help() {
    cat <<EOF
🎨 Gestor de Apariencia y Homogeneizacion Visual - CachyOS (KDE Plasma 6 + Kvantum)

Uso:
  $0 [OPCION]

Opciones principales:
  (sin argumentos)              Instala paquetes (Kvantum Qt5/Qt6, temas) y aplica tema oscuro optimizado (KvDark + Papirus-Dark).
  --dark, -d                    Aplica tema oscuro con Kvantum (KvDark + BreezeDark + Papirus-Dark).
  --light, -l                   Aplica tema claro con Kvantum (KvFlatLight + BreezeLight + Papirus).
  --kvantum, -k                 Activa Kvantum como motor de widgets (tema por defecto: KvDark).
  --kvantum-theme <TEMA>        Activa Kvantum y aplica un tema SVG especifico (ej. KvArcDark, KvAdaptaDark, KvMojave, MateriaDark).
  --breeze-widgets, --breeze    Restablece el estilo de widgets nativo de KDE Plasma 6 (Breeze) sin Kvantum.
  --papirus                     Aplica tema de iconos Papirus-Dark en KDE Plasma y GTK.
  --breeze-icons                Aplica tema de iconos Breeze-Dark oficiales.
  --status, -s                  Diagnostica el estado visual (Kvantum Qt5/Qt6, Look & Feel, ColorScheme, Iconos, GTK).
  --list, -l                    Lista temas globales, esquemas de color, iconos y temas Kvantum disponibles.
  --no-install                  Aplica los temas y configuraciones omitiendo la descarga de paquetes.
  --help, -h                    Muestra este mensaje de ayuda.

Temas populares de Kvantum incluidos:
  KvDark, KvArcDark, KvAdaptaDark, KvSimplicityDark, KvGnomeDark, KvMojave, KvFlatLight, MateriaDark
EOF
}

# 1. Instalacion de paquetes esenciales para KDE Plasma 6, Kvantum (Qt5 y Qt6), Miniaturas Dolphin y GTK
install_packages() {
    local PKGS_TO_INSTALL=()
    local ESSENTIAL_PKGS=(
        "kvantum"
        "kvantum-qt5"
        "papirus-icon-theme"
        "breeze-icons"
        "breeze-gtk"
        "kde-gtk-config"
        "ffmpegthumbs"
        "kdegraphics-thumbnailers"
        "kimageformats"
        "qt6-imageformats"
        "qt5-wayland"
        "qt6-wayland"
        "qqc2-desktop-style"
        "adwaita-icon-theme"
    )

    for pkg in "${ESSENTIAL_PKGS[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            PKGS_TO_INSTALL+=("$pkg")
        fi
    done

    if [ ${#PKGS_TO_INSTALL[@]} -eq 0 ]; then
        echo "✅ [1/4] Paquetes de apariencia (Kvantum Qt5/Qt6, temas, miniaturas) ya se encuentran instalados."
        return 0
    fi

    echo "📦 [1/4] Instalando paquetes faltantes (${PKGS_TO_INSTALL[*]} los cuales requieren permisos)..."
    $SUDO pacman -S --needed --noconfirm "${PKGS_TO_INSTALL[@]}" 2>/dev/null || true
    echo "✅ Paquetes de apariencia listos."
}

# 2. Configuracion del motor Kvantum y su tema activo con validacion
configure_kvantum() {
    local REQUESTED_THEME="${1:-KvDark}"
    local KVANTUM_DIR="$USER_HOME/.config/Kvantum"
    local KVANTUM_FILE="$KVANTUM_DIR/kvantum.kvconfig"
    local CHOSEN_THEME="$REQUESTED_THEME"

    run_as_user mkdir -p "$KVANTUM_DIR"

    # Verificar si el tema solicitado existe en /usr/share/Kvantum o ~/.config/Kvantum
    if [ ! -d "/usr/share/Kvantum/$CHOSEN_THEME" ] && [ ! -d "$KVANTUM_DIR/$CHOSEN_THEME" ]; then
        echo "⚠️ El tema Kvantum '$REQUESTED_THEME' no se encontro instalado en el sistema."
        if [ -d "/usr/share/Kvantum/KvDark" ]; then
            CHOSEN_THEME="KvDark"
            echo "ℹ️ Aplicando tema de respaldo predeterminado: $CHOSEN_THEME"
        elif [ -d "/usr/share/Kvantum/KvArcDark" ]; then
            CHOSEN_THEME="KvArcDark"
            echo "ℹ️ Aplicando tema de respaldo predeterminado: $CHOSEN_THEME"
        fi
    fi

    # Escribir configuracion limpia de Kvantum en el contexto del usuario
    run_as_user tee "$KVANTUM_FILE" > /dev/null <<EOF
[General]
theme=$CHOSEN_THEME
EOF

    # Si kvantummanager esta disponible en la sesion grafica, sincronizarlo
    if command -v kvantummanager &>/dev/null; then
        run_as_user kvantummanager --set "$CHOSEN_THEME" &>/dev/null || true
    fi

    echo "💠 Motor Kvantum configurado con el tema SVG: $CHOSEN_THEME"
}

# 3. Listar temas e iconos disponibles
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
    local KVANTUM_PATHS=()
    [ -d "/usr/share/Kvantum" ] && KVANTUM_PATHS+=("/usr/share/Kvantum"/*/)
    [ -d "$USER_HOME/.config/Kvantum" ] && KVANTUM_PATHS+=("$USER_HOME/.config/Kvantum"/*/)
    if [ ${#KVANTUM_PATHS[@]} -gt 0 ]; then
        printf "%s\n" "${KVANTUM_PATHS[@]}" 2>/dev/null | xargs -n1 basename 2>/dev/null | sort -u | grep -vE '^\.|\*$' || echo "No se encontraron temas instalados"
    else
        echo "No se encontraron temas instalados"
    fi
    echo ""
    echo "================================================================="
    echo "🖼️ TEMAS DE ICONOS INSTALADOS EN EL SISTEMA"
    echo "================================================================="
    ls -d /usr/share/icons/*/ "$USER_HOME/.local/share/icons/"*/ 2>/dev/null | xargs -n1 basename | sort -u | grep -vE 'default|hicolor|locolor' || true
    echo ""
}

# 4. Mostrar diagnostico y configuracion activa actual
show_status() {
    local KVANTUM_THEME="Inactivo / No configurado"
    if [ -f "$USER_HOME/.config/Kvantum/kvantum.kvconfig" ]; then
        local READ_THEME
        READ_THEME=$(grep -E '^theme=' "$USER_HOME/.config/Kvantum/kvantum.kvconfig" 2>/dev/null | cut -d= -f2 || true)
        if [ -n "$READ_THEME" ]; then
            KVANTUM_THEME="$READ_THEME"
            if [ ! -d "/usr/share/Kvantum/$READ_THEME" ] && [ ! -d "$USER_HOME/.config/Kvantum/$READ_THEME" ]; then
                KVANTUM_THEME="$READ_THEME (⚠️ Tema no encontrado en disco)"
            fi
        fi
    fi

    local QT5_KVANTUM_STATUS="No instalado (⚠️ Las apps Qt5 pueden verse rotas/desalineadas)"
    if pacman -Q kvantum-qt5 &>/dev/null || [ -f "/usr/lib/qt/plugins/styles/libkvantum.so" ]; then
        QT5_KVANTUM_STATUS="Instalado (Soporte Qt5 activo)"
    fi

    local QT6_KVANTUM_STATUS="No instalado"
    if pacman -Q kvantum &>/dev/null || [ -f "/usr/lib/qt6/plugins/styles/libkvantum.so" ]; then
        QT6_KVANTUM_STATUS="Instalado (Soporte Qt6 activo)"
    fi

    echo "================================================================="
    echo "🔍 ESTADO VISUAL ACTUAL (KDE PLASMA 6, KVANTUM & GTK)"
    echo "================================================================="
    echo "• Motor de Widgets KDE:   $(run_as_user kreadconfig6 --file kdeglobals --group KDE --key widgetStyle 2>/dev/null || echo 'Breeze')"
    echo "• Tema Kvantum Activo:    $KVANTUM_THEME"
    echo "• Plugin Kvantum Qt6:     $QT6_KVANTUM_STATUS"
    echo "• Plugin Kvantum Qt5:     $QT5_KVANTUM_STATUS"
    echo "-----------------------------------------------------------------"
    echo "• Tema Global Look&Feel:  $(run_as_user kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null || echo 'Breeze')"
    echo "• Esquema de color KDE:   $(run_as_user kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || echo 'Desconocido')"
    echo "• Tema de iconos KDE:     $(run_as_user kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null || echo 'Breeze')"
    echo "• Tema de cursor KDE:     $(run_as_user kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null || echo 'breeze_cursors')"
    if command -v gsettings &>/dev/null; then
        echo "-----------------------------------------------------------------"
        echo "• GTK Color Scheme (GNOME): $(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
        echo "• GTK Theme:                $(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'n/a')"
        echo "• GTK Icons:                $(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'n/a')"
        echo "• GTK Cursor:               $(run_as_user gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo 'n/a')"
    fi
    echo "================================================================="
}

# 5. Aplicar configuracion completa de apariencia
apply_appearance() {
    local MODE="${1:-dark}"
    local ICON_THEME="${2:-Papirus-Dark}"
    local WIDGET_STYLE="${3:-kvantum}"
    local KVANTUM_THEME="${4:-KvDark}"

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
        [ "$KVANTUM_THEME" = "KvDark" ] && KVANTUM_THEME="KvFlatLight"
    fi

    echo "🎨 [2/4] Aplicando Tema Global KDE Plasma ($LOOK_AND_FEEL) y Esquema ($COLOR_SCHEME)..."
    if command -v plasma-apply-lookandfeel &>/dev/null; then
        run_as_user plasma-apply-lookandfeel -a "$LOOK_AND_FEEL" 2>/dev/null || true
    fi

    if command -v plasma-apply-colorscheme &>/dev/null; then
        run_as_user plasma-apply-colorscheme "$COLOR_SCHEME" 2>/dev/null || true
    fi

    # Configuracion del motor de widgets (Kvantum o Breeze) para Qt5 y Qt6
    if [ "$WIDGET_STYLE" = "kvantum" ]; then
        configure_kvantum "$KVANTUM_THEME"
        set_kde_config "kdeglobals" "KDE" "widgetStyle" "kvantum"
        set_kde_config "kdeglobals" "General" "widgetStyle" "kvantum"
    else
        set_kde_config "kdeglobals" "KDE" "widgetStyle" "Breeze"
        set_kde_config "kdeglobals" "General" "widgetStyle" "Breeze"
        echo "💠 Motor de widgets establecido a: Breeze (Nativo KDE Plasma 6)"
    fi

    echo "🖼️ [3/4] Configurando tema de iconos ($ICON_THEME) y cursores ($CURSOR_THEME)..."
    set_kde_config "kdeglobals" "Icons" "Theme" "$ICON_THEME"
    set_kde_config "kdeglobals" "General" "ColorScheme" "$COLOR_SCHEME"
    set_kde_config "kdeglobals" "KDE" "colorScheme" "$COLOR_SCHEME"

    if command -v plasma-apply-cursortheme &>/dev/null; then
        run_as_user plasma-apply-cursortheme "$CURSOR_THEME" 2>/dev/null || true
    fi

    echo "🔗 [4/4] Sincronizando integracion para aplicaciones GTK 2, GTK 3, GTK 4, Flatpaks y Portales..."
    set_kde_config "gtkrc-2.0" "Settings" "gtk-theme-name" "$GTK_THEME"
    set_kde_config "gtkrc-2.0" "Settings" "gtk-icon-theme-name" "$ICON_THEME"

    # Escribir directamente en configuraciones de GTK3 y GTK4
    for gtk_ver in "gtk-3.0" "gtk-4.0"; do
        local GTK_DIR="$USER_HOME/.config/$gtk_ver"
        run_as_user mkdir -p "$GTK_DIR"
        run_as_user tee "$GTK_DIR/settings.ini" > /dev/null <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-application-prefer-dark-theme=$([ "$MODE" = "dark" ] && echo "1" || echo "0")
EOF
    done

    if command -v gsettings &>/dev/null; then
        run_as_user gsettings set org.gnome.desktop.interface color-scheme "$PREFER_DARK" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
    fi

    # Configurar permisos de Flatpak para temas y Kvantum si flatpak esta instalado
    if command -v flatpak &>/dev/null; then
        run_as_user flatpak override --user --filesystem=xdg-config/Kvantum:ro 2>/dev/null || true
        run_as_user flatpak override --user --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true
        run_as_user flatpak override --user --filesystem=xdg-config/gtk-4.0:ro 2>/dev/null || true
    fi

    # Configurar plugins de vistas previas y miniaturas en Dolphin
    set_kde_config "dolphinrc" "PreviewSettings" "Plugins" "audiothumbnail,directorythumbnail,djvuthumbnail,exrthumbnail,ffmpegthumbs,fontthumbnail,imagethumbnail,jpegthumbnail,kraimagethumbnail,svgthumbnail,textthumbnail,windowsexethumbnail"

    # Reconstruir cache de iconos y servicios de KDE Plasma para evitar iconos faltantes (?)
    if command -v kbuildsycoca6 &>/dev/null; then
        run_as_user kbuildsycoca6 --noincremental &>/dev/null || true
    fi

    # Notificar al compositor KWin para refrescar decoracion y efectos visuales
    if command -v dbus-send &>/dev/null; then
        run_as_user dbus-send --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi

    echo ""
    echo "================================================================="
    echo "✅ Apariencia para KDE Plasma 6 y sincronizacion GTK/Qt aplicada con exito."
    echo "💡 Motor Widgets: $WIDGET_STYLE $([ "$WIDGET_STYLE" = "kvantum" ] && echo "(Tema: $KVANTUM_THEME)" || echo "") | Modo: $COLOR_SCHEME | Iconos: $ICON_THEME | GTK: $GTK_THEME"
    echo "================================================================="
}

NO_INSTALL=false
ACTION=""
ARG_THEME=""

for arg in "$@"; do
    case "$arg" in
        --no-install)
            NO_INSTALL=true
            ;;
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
            ACTION="light"
            ;;
        --dark|dark)
            ACTION="dark"
            ;;
        --kvantum|-k)
            ACTION="kvantum"
            ;;
        --kvantum-theme)
            ACTION="kvantum-theme"
            ;;
        --breeze-widgets|--breeze)
            ACTION="breeze"
            ;;
        --papirus)
            ACTION="papirus"
            ;;
        --breeze-icons)
            ACTION="breeze-icons"
            ;;
        *)
            if [ "$ACTION" = "kvantum-theme" ] && [ -z "$ARG_THEME" ]; then
                ARG_THEME="$arg"
            elif [ -z "$ACTION" ]; then
                echo "❌ Opcion no reconocida: $arg"
                show_help
                exit 1
            fi
            ;;
    esac
done

case "${ACTION:-default}" in
    light)
        [ "$NO_INSTALL" = false ] && install_packages
        apply_appearance "light" "Papirus" "kvantum" "KvFlatLight"
        ;;
    dark)
        [ "$NO_INSTALL" = false ] && install_packages
        apply_appearance "dark" "Papirus-Dark" "kvantum" "KvDark"
        ;;
    kvantum)
        [ "$NO_INSTALL" = false ] && install_packages
        apply_appearance "dark" "Papirus-Dark" "kvantum" "KvDark"
        ;;
    kvantum-theme)
        if [ -z "$ARG_THEME" ]; then
            echo "❌ Error: Debes especificar el nombre del tema Kvantum."
            echo "Uso: $0 --kvantum-theme <NOMBRE_TEMA> (ej. KvDark, KvArcDark, KvAdaptaDark, KvMojave, MateriaDark)"
            exit 1
        fi
        [ "$NO_INSTALL" = false ] && install_packages
        apply_appearance "dark" "Papirus-Dark" "kvantum" "$ARG_THEME"
        ;;
    breeze)
        [ "$NO_INSTALL" = false ] && install_packages
        apply_appearance "dark" "Papirus-Dark" "Breeze" "none"
        ;;
    papirus)
        [ "$NO_INSTALL" = false ] && install_packages
        apply_appearance "dark" "Papirus-Dark" "kvantum" "KvDark"
        ;;
    breeze-icons)
        [ "$NO_INSTALL" = false ] && install_packages
        apply_appearance "dark" "breeze-dark" "kvantum" "KvDark"
        ;;
    default)
        if [ "$NO_INSTALL" = true ]; then
            apply_appearance "dark" "Papirus-Dark" "kvantum" "KvDark"
        else
            echo "================================================================="
            echo "🎨 CONFIGURADOR DE APARIENCIA - CACHYOS (KDE PLASMA 6 + KVANTUM)"
            echo "================================================================="
            install_packages
            apply_appearance "dark" "Papirus-Dark" "kvantum" "KvDark"
        fi
        ;;
esac
