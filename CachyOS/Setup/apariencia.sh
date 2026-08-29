#!/bin/bash
# ==============================================================================
# apariencia.sh - Gestor de Apariencia y Temas NATIVOS para CachyOS + KDE Plasma 6
# 100% Nativo (Breeze Qt6 + Kirigami + Esquemas de Color + Iconos + GTK Sync)
# ==============================================================================
#
# Uso:
#   ./apariencia.sh                  -> Aplica tema nativo optimizado (BreezeDark + Papirus-Dark)
#   ./apariencia.sh --catppuccin     -> Aplica la suite nativa Catppuccin Mocha (Colores, Iconos, GTK, Wallpaper)
#   ./apariencia.sh --nord           -> Aplica la suite nativa Nordic / CachyOS-Nord (Colores, Iconos, GTK, Wallpaper)
#   ./apariencia.sh --dracula        -> Aplica la suite nativa Dracula (Colores, Iconos, Cursors, GTK, Wallpaper)
#   ./apariencia.sh --orchis         -> Aplica la suite nativa Orchis (Colores, Iconos, GTK, Wallpaper)
#   ./apariencia.sh --breeze         -> Aplica el estilo nativo estándar KDE Plasma 6 (BreezeDark + Papirus-Dark)
#   ./apariencia.sh --dark, -d       -> Aplica tema oscuro nativo predeterminado
#   ./apariencia.sh --light, -l      -> Aplica tema claro nativo (BreezeLight + Papirus)
#   ./apariencia.sh --install-themes -> Instala todos los paquetes y activos de temas nativos
#   ./apariencia.sh --status, -s     -> Muestra el diagnostico visual actual
#   ./apariencia.sh --list, -l       -> Muestra temas globales, esquemas de color e iconos instalados
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

# Helper para aplicar fondo de pantalla en KDE Plasma 6
set_wallpaper() {
    local WP_PATH="$1"
    if [ -f "$WP_PATH" ] && command -v plasma-apply-wallpaperimage &>/dev/null; then
        timeout 5s run_as_user plasma-apply-wallpaperimage "$WP_PATH" &>/dev/null || true
        echo "🖼️ Fondo de pantalla aplicado: $(basename "$WP_PATH")"
    fi
}

# 1. Instalacion de paquetes esenciales para KDE Plasma 6 (100% nativo)
install_base_packages() {
    local PKGS_TO_INSTALL=()
    local ESSENTIAL_PKGS=(
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
        "qqc2-breeze-style"
        "adwaita-icon-theme"
        "xdg-desktop-portal-kde"
        "xdg-desktop-portal-gtk"
    )

    for pkg in "${ESSENTIAL_PKGS[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            PKGS_TO_INSTALL+=("$pkg")
        fi
    done

    if [ ${#PKGS_TO_INSTALL[@]} -eq 0 ]; then
        return 0
    fi

    echo "📦 Instalando paquetes base de apariencia nativa (${PKGS_TO_INSTALL[*]})..."
    $SUDO pacman -S --needed --noconfirm "${PKGS_TO_INSTALL[@]}" 2>/dev/null || true
}

# Descarga e instalacion de esquemas de color y activos nativos Catppuccin
install_catppuccin_assets() {
    local COLOR_DIR="$USER_HOME/.local/share/color-schemes"
    local LNF_DIR="$USER_HOME/.local/share/plasma/look-and-feel"
    local WP_DIR="$USER_HOME/.local/share/wallpapers/Catppuccin"

    run_as_user mkdir -p "$COLOR_DIR" "$LNF_DIR" "$WP_DIR"

    if [ ! -f "$COLOR_DIR/CatppuccinMochaBlue.colors" ]; then
        echo "⬇️ Descargando esquemas de color nativos de Catppuccin..."
        local TEMP_DIR="/tmp/catppuccin-kde-$$"
        rm -rf "$TEMP_DIR"
        if git clone --depth 1 https://github.com/catppuccin/kde.git "$TEMP_DIR" &>/dev/null; then
            run_as_user cp -r "$TEMP_DIR/generated/color-schemes/"*.colors "$COLOR_DIR/" 2>/dev/null || true
            run_as_user cp -r "$TEMP_DIR/Resources/LookAndFeel/"* "$LNF_DIR/" 2>/dev/null || true
            rm -rf "$TEMP_DIR"
        fi
    fi

    if [ ! -f "$WP_DIR/catppuccin-mocha.png" ]; then
        echo "⬇️ Descargando fondo de pantalla Catppuccin Mocha 4K..."
        curl -sL "https://raw.githubusercontent.com/catppuccin/wallpapers/main/landscapes/evening-sky.png" -o "$WP_DIR/catppuccin-mocha.png" 2>/dev/null || true
    fi
}

# Instalador completo de todas las suites de temas nativos
install_all_themes() {
    echo "================================================================="
    echo "🎨 INSTALANDO PAQUETES Y ACTIVOS DE TEMAS NATIVOS (KDE PLASMA 6)"
    echo "================================================================="
    install_base_packages

    local SUITE_PKGS=(
        # Nordic
        "cachyos-nord-kde-theme-git"
        "nordic-theme-git"
        "colloid-nord-icon-theme-git"
        # Dracula
        "ant-dracula-kde-theme-git"
        "ant-dracula-theme-git"
        "dracula-icons-git"
        "dracula-cursors-git"
        # Orchis
        "orchis-theme"
        "tela-circle-icon-theme-all"
        # Catppuccin
        "catppuccin-cursors-mocha"
        "colloid-catppuccin-gtk-theme-git"
        "colloid-catppuccin-theme-git"
    )

    local NEEDED=()
    for pkg in "${SUITE_PKGS[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            NEEDED+=("$pkg")
        fi
    done

    if [ ${#NEEDED[@]} -gt 0 ]; then
        echo "📦 Instalando paquetes de temas comunitarios (${#NEEDED[@]} paquetes)..."
        $SUDO pacman -S --needed --noconfirm "${NEEDED[@]}" 2>/dev/null || true
    fi

    install_catppuccin_assets
    echo "✅ Todas las suites de temas nativos (Catppuccin, Nordic, Dracula, Orchis) estan instaladas."
}

# Sincronizacion centralizada de apariencia nativa
apply_core_appearance() {
    local LOOK_AND_FEEL="$1"
    local COLOR_SCHEME="$2"
    local ICON_THEME="$3"
    local GTK_THEME="$4"
    local CURSOR_THEME="$5"
    local WALLPAPER_PATH="$6"
    local PREFER_DARK="${7:-prefer-dark}"

    # Forzar siempre motor de widgets nativo Breeze (Qt6)
    set_kde_config "kdeglobals" "KDE" "widgetStyle" "Breeze"
    set_kde_config "kdeglobals" "General" "widgetStyle" "Breeze"

    echo "🎨 Aplicando Esquema de Color ($COLOR_SCHEME) y Look & Feel ($LOOK_AND_FEEL)..."
    if [ -n "$LOOK_AND_FEEL" ] && command -v plasma-apply-lookandfeel &>/dev/null; then
        timeout 5s run_as_user plasma-apply-lookandfeel -a "$LOOK_AND_FEEL" 2>/dev/null || true
    fi

    if [ -n "$COLOR_SCHEME" ] && command -v plasma-apply-colorscheme &>/dev/null; then
        timeout 5s run_as_user plasma-apply-colorscheme "$COLOR_SCHEME" 2>/dev/null || true
    fi

    set_kde_config "kdeglobals" "Icons" "Theme" "$ICON_THEME"
    set_kde_config "kdeglobals" "General" "ColorScheme" "$COLOR_SCHEME"
    set_kde_config "kdeglobals" "KDE" "colorScheme" "$COLOR_SCHEME"

    if [ -n "$CURSOR_THEME" ] && command -v plasma-apply-cursortheme &>/dev/null; then
        timeout 5s run_as_user plasma-apply-cursortheme "$CURSOR_THEME" 2>/dev/null || true
    fi
    [ -n "$CURSOR_THEME" ] && set_kde_config "kcminputrc" "Mouse" "cursorTheme" "$CURSOR_THEME"

    echo "🔗 Sincronizando integracion GTK 2/3/4, Flatpaks y Portales..."
    set_kde_config "gtkrc-2.0" "Settings" "gtk-theme-name" "$GTK_THEME"
    set_kde_config "gtkrc-2.0" "Settings" "gtk-icon-theme-name" "$ICON_THEME"

    for gtk_ver in "gtk-3.0" "gtk-4.0"; do
        local GTK_DIR="$USER_HOME/.config/$gtk_ver"
        run_as_user mkdir -p "$GTK_DIR"
        run_as_user tee "$GTK_DIR/settings.ini" > /dev/null <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-application-prefer-dark-theme=$([ "$PREFER_DARK" = "prefer-dark" ] && echo "1" || echo "0")
EOF
    done

    if command -v gsettings &>/dev/null; then
        run_as_user gsettings set org.gnome.desktop.interface color-scheme "$PREFER_DARK" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
    fi

    if command -v flatpak &>/dev/null; then
        run_as_user flatpak override --user --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true
        run_as_user flatpak override --user --filesystem=xdg-config/gtk-4.0:ro 2>/dev/null || true
    fi

    set_kde_config "dolphinrc" "PreviewSettings" "Plugins" "audiothumbnail,directorythumbnail,djvuthumbnail,exrthumbnail,ffmpegthumbs,fontthumbnail,imagethumbnail,jpegthumbnail,kraimagethumbnail,svgthumbnail,textthumbnail,windowsexethumbnail"

    # Aplicar Fondo de pantalla
    if [ -n "$WALLPAPER_PATH" ]; then
        set_wallpaper "$WALLPAPER_PATH"
    fi

    # Reconstruir cache de iconos y tipos MIME
    if command -v kbuildsycoca6 &>/dev/null; then
        run_as_user kbuildsycoca6 --noincremental &>/dev/null || true
    fi

    # Notificar a KWin para actualizar sombras y decoraciones
    if command -v dbus-send &>/dev/null; then
        run_as_user dbus-send --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi
}

# ==============================================================================
# SUITES DE TEMAS NATIVOS
# ==============================================================================

# 1. Suite Catppuccin Mocha (Pastel Oscuro Nativo)
apply_theme_catppuccin() {
    echo "================================================================="
    echo "☕ APLICANDO SUITE NATIVA: CATPPUCCIN MOCHA (KDE PLASMA 6)"
    echo "================================================================="
    [ "$NO_INSTALL" = false ] && {
        $SUDO pacman -S --needed --noconfirm catppuccin-cursors-mocha colloid-catppuccin-gtk-theme-git colloid-catppuccin-theme-git 2>/dev/null || true
        install_catppuccin_assets
    }

    local ICON_THEME="Colloid-Catppuccin-Dark"
    [ ! -d "/usr/share/icons/$ICON_THEME" ] && ICON_THEME="Papirus-Dark"

    local CURSOR_THEME="Catppuccin-Mocha-Dark-Cursors"
    [ ! -d "/usr/share/icons/$CURSOR_THEME" ] && CURSOR_THEME="catppuccin-cursors-mocha"
    [ ! -d "/usr/share/icons/$CURSOR_THEME" ] && CURSOR_THEME="breeze_cursors"

    local GTK_THEME="Colloid-Catppuccin-Mocha-Dark"
    [ ! -d "/usr/share/themes/$GTK_THEME" ] && GTK_THEME="Breeze-Dark"

    local WALLPAPER="$USER_HOME/.local/share/wallpapers/Catppuccin/catppuccin-mocha.png"
    [ ! -f "$WALLPAPER" ] && WALLPAPER="/usr/share/wallpapers/cachyos-wallpapers/cachygalaxy99.jpg"

    apply_core_appearance \
        "org.kde.breezedark.desktop" \
        "CatppuccinMochaBlue" \
        "$ICON_THEME" \
        "$GTK_THEME" \
        "$CURSOR_THEME" \
        "$WALLPAPER" \
        "prefer-dark"

    echo "✅ Suite Catppuccin Mocha (Nativa KDE 6) aplicada con exito."
}

# 2. Suite Nordic / CachyOS-Nord (Artico Azulado Nativo)
apply_theme_nord() {
    echo "================================================================="
    echo "🌌 APLICANDO SUITE NATIVA: NORD / NORDIC (KDE PLASMA 6)"
    echo "================================================================="
    [ "$NO_INSTALL" = false ] && {
        $SUDO pacman -S --needed --noconfirm cachyos-nord-kde-theme-git nordic-theme-git colloid-nord-icon-theme-git 2>/dev/null || true
    }

    local ICON_THEME="Colloid-Nord-Dark"
    [ ! -d "/usr/share/icons/$ICON_THEME" ] && ICON_THEME="tela-circle-icon-theme-nord"
    [ ! -d "/usr/share/icons/$ICON_THEME" ] && ICON_THEME="Papirus-Dark"

    local GTK_THEME="Nordic-Darker"
    [ ! -d "/usr/share/themes/$GTK_THEME" ] && GTK_THEME="Nordic"
    [ ! -d "/usr/share/themes/$GTK_THEME" ] && GTK_THEME="Breeze-Dark"

    local WALLPAPER="/usr/share/wallpapers/cachyos-wallpapers/north.png"
    [ ! -f "$WALLPAPER" ] && WALLPAPER="/usr/share/wallpapers/cachyos-wallpapers/cachygalaxy99.jpg"

    apply_core_appearance \
        "CachyOS-Nord" \
        "CachyOSNord" \
        "$ICON_THEME" \
        "$GTK_THEME" \
        "breeze_cursors" \
        "$WALLPAPER" \
        "prefer-dark"

    echo "✅ Suite Nordic (Nativa KDE 6) aplicada con exito."
}

# 3. Suite Dracula (Contraste Neon Vampirico Nativo)
apply_theme_dracula() {
    echo "================================================================="
    echo "🧛 APLICANDO SUITE NATIVA: DRACULA (KDE PLASMA 6)"
    echo "================================================================="
    [ "$NO_INSTALL" = false ] && {
        $SUDO pacman -S --needed --noconfirm ant-dracula-kde-theme-git ant-dracula-theme-git dracula-icons-git dracula-cursors-git 2>/dev/null || true
    }

    local ICON_THEME="Dracula"
    [ ! -d "/usr/share/icons/$ICON_THEME" ] && ICON_THEME="colloid-dracula-theme-git"
    [ ! -d "/usr/share/icons/$ICON_THEME" ] && ICON_THEME="Papirus-Dark"

    local CURSOR_THEME="Dracula-cursors"
    [ ! -d "/usr/share/icons/$CURSOR_THEME" ] && CURSOR_THEME="breeze_cursors"

    local GTK_THEME="Ant-Dracula"
    [ ! -d "/usr/share/themes/$GTK_THEME" ] && GTK_THEME="Dracula"
    [ ! -d "/usr/share/themes/$GTK_THEME" ] && GTK_THEME="Breeze-Dark"

    local WALLPAPER="/usr/share/wallpapers/cachyos-wallpapers/Dracula.png"
    [ ! -f "$WALLPAPER" ] && WALLPAPER="/usr/share/wallpapers/cachyos-wallpapers/cachygalaxy99.jpg"

    apply_core_appearance \
        "org.kde.breezedark.desktop" \
        "BreezeDark" \
        "$ICON_THEME" \
        "$GTK_THEME" \
        "$CURSOR_THEME" \
        "$WALLPAPER" \
        "prefer-dark"

    echo "✅ Suite Dracula (Nativa KDE 6) aplicada con exito."
}

# 4. Suite Orchis (Material Design Moderno con Acentos)
apply_theme_orchis() {
    echo "================================================================="
    echo "🌿 APLICANDO SUITE NATIVA: ORCHIS DARK (KDE PLASMA 6)"
    echo "================================================================="
    [ "$NO_INSTALL" = false ] && {
        $SUDO pacman -S --needed --noconfirm orchis-theme tela-circle-icon-theme-all 2>/dev/null || true
    }

    local ICON_THEME="Tela-circle-dark"
    [ ! -d "/usr/share/icons/$ICON_THEME" ] && ICON_THEME="Tela-circle"
    [ ! -d "/usr/share/icons/$ICON_THEME" ] && ICON_THEME="Papirus-Dark"

    local GTK_THEME="Orchis-Dark"
    [ ! -d "/usr/share/themes/$GTK_THEME" ] && GTK_THEME="Orchis-Teal-Dark"
    [ ! -d "/usr/share/themes/$GTK_THEME" ] && GTK_THEME="Breeze-Dark"

    local WALLPAPER="/usr/share/wallpapers/cachyos-wallpapers/CachyOS_GreenSpace.png"
    [ ! -f "$WALLPAPER" ] && WALLPAPER="/usr/share/wallpapers/cachyos-wallpapers/Cachy_Topography1.jpg"

    apply_core_appearance \
        "org.kde.breezedark.desktop" \
        "BreezeDark" \
        "$ICON_THEME" \
        "$GTK_THEME" \
        "breeze_cursors" \
        "$WALLPAPER" \
        "prefer-dark"

    echo "✅ Suite Orchis Dark (Nativa KDE 6) aplicada con exito."
}

# 5. Suite Nativa KDE Plasma 6 Breeze (Predeterminada)
apply_theme_breeze() {
    echo "================================================================="
    echo "⚡ APLICANDO ESTILO NATIVO KDE PLASMA 6 (BREEZE)"
    echo "================================================================="
    apply_core_appearance \
        "org.kde.breezedark.desktop" \
        "BreezeDark" \
        "Papirus-Dark" \
        "Breeze-Dark" \
        "breeze_cursors" \
        "/usr/share/wallpapers/cachyos-wallpapers/cachygalaxy99.jpg" \
        "prefer-dark"

    echo "✅ Estilo nativo Breeze Dark aplicado (Widgets nativos Qt6/Kirigami)."
}

# 6. Diagnostico visual
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO VISUAL ACTUAL (KDE PLASMA 6 NATIVO & GTK)"
    echo "================================================================="
    echo "• Motor de Widgets KDE:   $(run_as_user kreadconfig6 --file kdeglobals --group KDE --key widgetStyle 2>/dev/null || echo 'Breeze')"
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

# 7. Listar temas disponibles
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
    echo "🖼️ TEMAS DE ICONOS INSTALADOS EN EL SISTEMA"
    echo "================================================================="
    ls -d /usr/share/icons/*/ "$USER_HOME/.local/share/icons/"*/ 2>/dev/null | xargs -n1 basename | sort -u | grep -vE 'default|hicolor|locolor' || true
    echo ""
}

show_help() {
    cat <<EOF
🎨 Gestor de Apariencia y Suites de Temas NATIVOS - CachyOS (KDE Plasma 6)

Uso:
  $0 [OPCION]

Suites completas de temas NATIVOS (Breeze Qt6 + Colores + Iconos + GTK + Wallpapers):
  --catppuccin                  Aplica la suite Catppuccin Mocha nativa.
  --nord, --nordic              Aplica la suite Nordic / CachyOS-Nord nativa.
  --dracula                     Aplica la suite Dracula nativa.
  --orchis                      Aplica la suite Orchis Dark nativa.
  --breeze                      Aplica el estilo nativo estándar de KDE Plasma 6 (BreezeDark + Papirus).

Opciones avanzadas y gestion:
  --install-themes              Descarga e instala todos los paquetes y activos de las suites nativas.
  --uninstall-kvantum           Desinstala Kvantum y todos sus paquetes de temas del sistema.
  --dark, -d                    Aplica tema oscuro nativo predeterminado.
  --light, -l                   Aplica tema claro nativo (BreezeLight + Papirus).
  --status, -s                  Diagnostica el estado visual activo (Widgets, Look&Feel, Iconos, GTK).
  --list, -l                    Lista todos los temas globales, esquemas e iconos instalados.
  --no-install                  Aplica la suite omitiendo la instalacion de paquetes pacman.
  --help, -h                    Muestra este mensaje de ayuda.
EOF
}

# ==============================================================================
# PROCESAMIENTO DE ARGUMENTOS
# ==============================================================================

NO_INSTALL=false
ACTION=""

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
        --install-themes)
            ACTION="install-themes"
            ;;
        --uninstall-kvantum)
            ACTION="uninstall-kvantum"
            ;;
        --catppuccin)
            ACTION="catppuccin"
            ;;
        --nord|--nordic)
            ACTION="nord"
            ;;
        --dracula)
            ACTION="dracula"
            ;;
        --orchis)
            ACTION="orchis"
            ;;
        --breeze|--breeze-widgets)
            ACTION="breeze"
            ;;
        --dark|dark)
            ACTION="breeze"
            ;;
        --light|light)
            ACTION="light"
            ;;
        *)
            echo "❌ Opcion no reconocida: $arg"
            show_help
            exit 1
            ;;
    esac
done

case "${ACTION:-default}" in
    uninstall-kvantum)
        echo "🗑️ Desinstalando Kvantum y paquetes asociados de CachyOS..."
        $SUDO pacman -Rns --noconfirm ant-dracula-kvantum-theme-git kvantum kvantum-qt5 kvantum-theme-materia kvantum-theme-nordic-git kvantum-theme-orchis-git 2>/dev/null || \
        $SUDO pacman -R --noconfirm kvantum kvantum-qt5 2>/dev/null || true
        rm -rf "$USER_HOME/.config/Kvantum"
        echo "✅ Kvantum y sus paquetes de temas han sido desinstalados."
        exit 0
        ;;
    install-themes)
        install_all_themes
        ;;
    catppuccin)
        apply_theme_catppuccin
        ;;
    nord)
        apply_theme_nord
        ;;
    dracula)
        apply_theme_dracula
        ;;
    orchis)
        apply_theme_orchis
        ;;
    breeze)
        apply_theme_breeze
        ;;
    light)
        apply_core_appearance \
            "org.kde.breeze.desktop" \
            "BreezeLight" \
            "Papirus" \
            "Breeze" \
            "breeze_cursors" \
            "/usr/share/wallpapers/cachyos-wallpapers/paper.png" \
            "default"
        ;;
    default)
        if [ "$NO_INSTALL" = true ]; then
            apply_theme_breeze
        else
            echo "================================================================="
            echo "🎨 CONFIGURADOR DE APARIENCIA NATIVA - CACHYOS (KDE PLASMA 6)"
            echo "================================================================="
            install_base_packages
            apply_theme_breeze
        fi
        ;;
esac
