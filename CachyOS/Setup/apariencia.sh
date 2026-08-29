#!/bin/bash
# ==============================================================================
# apariencia.sh - Gestor de Temas, Kvantum (Qt5/Qt6), Iconos y Homogeneizacion Visual
# Optimizado para CachyOS + KDE Plasma 6
# ==============================================================================
#
# Uso:
#   ./apariencia.sh                  -> Aplica tema nativo optimizado (BreezeDark + Papirus-Dark)
#   ./apariencia.sh --catppuccin     -> Aplica la suite completa Catppuccin Mocha (Kvantum, Colores, Iconos, GTK, Wallpaper)
#   ./apariencia.sh --nord           -> Aplica la suite completa Nordic / CachyOS-Nord (Kvantum, Colores, Iconos, GTK, Wallpaper)
#   ./apariencia.sh --dracula        -> Aplica la suite completa Dracula (Kvantum, Colores, Iconos, Cursors, GTK, Wallpaper)
#   ./apariencia.sh --orchis         -> Aplica la suite completa Orchis (Kvantum, Colores, Iconos, GTK, Wallpaper)
#   ./apariencia.sh --breeze         -> Aplica el estilo nativo KDE Plasma 6 Breeze (BreezeDark + Papirus-Dark)
#   ./apariencia.sh --dark, -d       -> Aplica tema oscuro predeterminado
#   ./apariencia.sh --light, -l      -> Aplica tema claro (BreezeLight + Papirus)
#   ./apariencia.sh --kvantum-theme <TEMA> -> Aplica un tema especifico de Kvantum
#   ./apariencia.sh --install-themes -> Instala todos los paquetes y activos de temas (Catppuccin, Nord, Dracula, Orchis)
#   ./apariencia.sh --status, -s     -> Muestra el diagnostico visual actual
#   ./apariencia.sh --list, -l       -> Muestra temas globales, esquemas, iconos y temas Kvantum disponibles
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
        run_as_user plasma-apply-wallpaperimage "$WP_PATH" &>/dev/null || true
        echo "🖼️ Fondo de pantalla aplicado: $(basename "$WP_PATH")"
    fi
}

# 1. Instalacion de paquetes esenciales para KDE Plasma 6 y Kvantum
install_base_packages() {
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
        return 0
    fi

    echo "📦 Instalando paquetes base de apariencia (${PKGS_TO_INSTALL[*]})..."
    $SUDO pacman -S --needed --noconfirm "${PKGS_TO_INSTALL[@]}" 2>/dev/null || true
}

# Descarga e instalacion de activos Catppuccin (Kvantum, LookAndFeel, ColorSchemes, Wallpapers)
install_catppuccin_assets() {
    echo "☕ Verificando activos de Catppuccin (Kvantum, Color-Schemes y Look&Feel)..."
    local KVANTUM_DIR="$USER_HOME/.config/Kvantum"
    local COLOR_DIR="$USER_HOME/.local/share/color-schemes"
    local LNF_DIR="$USER_HOME/.local/share/plasma/look-and-feel"
    local WP_DIR="$USER_HOME/.local/share/wallpapers/Catppuccin"

    run_as_user mkdir -p "$KVANTUM_DIR" "$COLOR_DIR" "$LNF_DIR" "$WP_DIR"

    if [ ! -d "$KVANTUM_DIR/catppuccin-mocha-blue" ]; then
        echo "⬇️ Descargando temas Kvantum de Catppuccin..."
        local TEMP_DIR="/tmp/catppuccin-kv-$$"
        rm -rf "$TEMP_DIR"
        if git clone --depth 1 https://github.com/catppuccin/kvantum.git "$TEMP_DIR" &>/dev/null; then
            run_as_user cp -r "$TEMP_DIR/themes/"* "$KVANTUM_DIR/" 2>/dev/null || true
            rm -rf "$TEMP_DIR"
        fi
    fi

    if [ ! -f "$COLOR_DIR/CatppuccinMochaBlue.colors" ]; then
        echo "⬇️ Descargando esquemas de color KDE de Catppuccin..."
        local TEMP_DIR="/tmp/catppuccin-kde-$$"
        rm -rf "$TEMP_DIR"
        if git clone --depth 1 https://github.com/catppuccin/kde.git "$TEMP_DIR" &>/dev/null; then
            run_as_user cp -r "$TEMP_DIR/generated/color-schemes/"*.colors "$COLOR_DIR/" 2>/dev/null || true
            run_as_user cp -r "$TEMP_DIR/Resources/LookAndFeel/"* "$LNF_DIR/" 2>/dev/null || true
            rm -rf "$TEMP_DIR"
        fi
    fi

    if [ ! -f "$WP_DIR/catppuccin-mocha.png" ]; then
        echo "⬇️ Descargando fondo de pantalla Catppuccin Mocha..."
        curl -sL "https://raw.githubusercontent.com/catppuccin/wallpapers/main/landscapes/evening-sky.png" -o "$WP_DIR/catppuccin-mocha.png" 2>/dev/null || true
    fi
}

# Instalador completo de todas las suites de temas
install_all_themes() {
    echo "================================================================="
    echo "🎨 INSTALANDO PAQUETES Y ACTIVOS PARA TODAS LAS SUITES DE TEMAS"
    echo "================================================================="
    install_base_packages

    local SUITE_PKGS=(
        # Nordic
        "kvantum-theme-nordic-git"
        "cachyos-nord-kde-theme-git"
        "nordic-theme-git"
        "colloid-nord-icon-theme-git"
        # Dracula
        "ant-dracula-kvantum-theme-git"
        "ant-dracula-kde-theme-git"
        "ant-dracula-theme-git"
        "dracula-icons-git"
        "dracula-cursors-git"
        # Orchis
        "kvantum-theme-orchis-git"
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
    echo "✅ Todas las suites de temas (Catppuccin, Nordic, Dracula, Orchis) estan instaladas."
}

# 2. Configuracion del motor Kvantum
configure_kvantum() {
    local THEME="$1"
    local KVANTUM_DIR="$USER_HOME/.config/Kvantum"
    local KVANTUM_FILE="$KVANTUM_DIR/kvantum.kvconfig"

    run_as_user mkdir -p "$KVANTUM_DIR"

    # Escribir configuracion limpia de Kvantum
    run_as_user tee "$KVANTUM_FILE" > /dev/null <<EOF
[General]
theme=$THEME
EOF

    set_kde_config "kdeglobals" "KDE" "widgetStyle" "kvantum"
    set_kde_config "kdeglobals" "General" "widgetStyle" "kvantum"
    echo "💠 Motor Kvantum configurado con el tema: $THEME"
}

# Sincronizacion general de apariencia
apply_core_appearance() {
    local LOOK_AND_FEEL="$1"
    local COLOR_SCHEME="$2"
    local ICON_THEME="$3"
    local GTK_THEME="$4"
    local CURSOR_THEME="$5"
    local WALLPAPER_PATH="$6"
    local PREFER_DARK="${7:-prefer-dark}"

    echo "🎨 Aplicando Look & Feel ($LOOK_AND_FEEL) y Esquema de Color ($COLOR_SCHEME)..."
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
        run_as_user flatpak override --user --filesystem=xdg-config/Kvantum:ro 2>/dev/null || true
        run_as_user flatpak override --user --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true
        run_as_user flatpak override --user --filesystem=xdg-config/gtk-4.0:ro 2>/dev/null || true
    fi

    set_kde_config "dolphinrc" "PreviewSettings" "Plugins" "audiothumbnail,directorythumbnail,djvuthumbnail,exrthumbnail,ffmpegthumbs,fontthumbnail,imagethumbnail,jpegthumbnail,kraimagethumbnail,svgthumbnail,textthumbnail,windowsexethumbnail"

    # Aplicar Wallpaper
    if [ -n "$WALLPAPER_PATH" ]; then
        set_wallpaper "$WALLPAPER_PATH"
    fi

    # Reconstruir cache de iconos y tipos MIME
    if command -v kbuildsycoca6 &>/dev/null; then
        run_as_user kbuildsycoca6 --noincremental &>/dev/null || true
    fi

    # Notificar a KWin
    if command -v dbus-send &>/dev/null; then
        run_as_user dbus-send --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi
}

# ==============================================================================
# SUITES COMPLETAS DE TEMAS
# ==============================================================================

# 1. Suite Catppuccin Mocha (Pastel Oscuro)
apply_theme_catppuccin() {
    echo "================================================================="
    echo "☕ APLICANDO SUITE COMPLETA: CATPPUCCIN MOCHA"
    echo "================================================================="
    [ "$NO_INSTALL" = false ] && {
        $SUDO pacman -S --needed --noconfirm catppuccin-cursors-mocha colloid-catppuccin-gtk-theme-git colloid-catppuccin-theme-git 2>/dev/null || true
        install_catppuccin_assets
    }

    configure_kvantum "catppuccin-mocha-blue"

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
        "Catppuccin-Mocha-Global" \
        "CatppuccinMochaBlue" \
        "$ICON_THEME" \
        "$GTK_THEME" \
        "$CURSOR_THEME" \
        "$WALLPAPER" \
        "prefer-dark"

    echo "✅ Suite Catppuccin Mocha aplicada con exito."
}

# 2. Suite Nordic / CachyOS-Nord (Artico Azulado)
apply_theme_nord() {
    echo "================================================================="
    echo "🌌 APLICANDO SUITE COMPLETA: NORD / NORDIC"
    echo "================================================================="
    [ "$NO_INSTALL" = false ] && {
        $SUDO pacman -S --needed --noconfirm kvantum-theme-nordic-git cachyos-nord-kde-theme-git nordic-theme-git colloid-nord-icon-theme-git 2>/dev/null || true
    }

    local KV_THEME="Nordic"
    [ -d "/usr/share/Kvantum/Nordic-Darker" ] && KV_THEME="Nordic-Darker"
    configure_kvantum "$KV_THEME"

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

    echo "✅ Suite Nordic aplicada con exito."
}

# 3. Suite Dracula (Contraste Neon Vampirico)
apply_theme_dracula() {
    echo "================================================================="
    echo "🧛 APLICANDO SUITE COMPLETA: DRACULA"
    echo "================================================================="
    [ "$NO_INSTALL" = false ] && {
        $SUDO pacman -S --needed --noconfirm ant-dracula-kvantum-theme-git ant-dracula-kde-theme-git ant-dracula-theme-git dracula-icons-git dracula-cursors-git 2>/dev/null || true
    }

    local KV_THEME="Ant-Dracula"
    [ ! -d "/usr/share/Kvantum/$KV_THEME" ] && [ -d "/usr/share/Kvantum/Dracula" ] && KV_THEME="Dracula"
    configure_kvantum "$KV_THEME"

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
        "Ant-Dracula" \
        "Dracula" \
        "$ICON_THEME" \
        "$GTK_THEME" \
        "$CURSOR_THEME" \
        "$WALLPAPER" \
        "prefer-dark"

    echo "✅ Suite Dracula aplicada con exito."
}

# 4. Suite Orchis (Material Design Moderno con Acentos)
apply_theme_orchis() {
    echo "================================================================="
    echo "🌿 APLICANDO SUITE COMPLETA: ORCHIS DARK"
    echo "================================================================="
    [ "$NO_INSTALL" = false ] && {
        $SUDO pacman -S --needed --noconfirm kvantum-theme-orchis-git orchis-theme tela-circle-icon-theme-all 2>/dev/null || true
    }

    local KV_THEME="Orchis-dark"
    [ ! -d "/usr/share/Kvantum/$KV_THEME" ] && [ -d "/usr/share/Kvantum/Orchis-teal-dark" ] && KV_THEME="Orchis-teal-dark"
    configure_kvantum "$KV_THEME"

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

    echo "✅ Suite Orchis Dark aplicada con exito."
}

# 5. Suite Nativa KDE Plasma 6 Breeze (Maxima Estabilidad y Rendimiento)
apply_theme_breeze() {
    echo "================================================================="
    echo "⚡ APLICANDO ESTILO NATIVO KDE PLASMA 6 (BREEZE)"
    echo "================================================================="
    set_kde_config "kdeglobals" "KDE" "widgetStyle" "Breeze"
    set_kde_config "kdeglobals" "General" "widgetStyle" "Breeze"

    local KVANTUM_DIR="$USER_HOME/.config/Kvantum"
    run_as_user mkdir -p "$KVANTUM_DIR"
    run_as_user tee "$KVANTUM_DIR/kvantum.kvconfig" > /dev/null <<EOF
[General]
theme=KvDark
EOF

    apply_core_appearance \
        "org.kde.breezedark.desktop" \
        "BreezeDark" \
        "Papirus-Dark" \
        "Breeze-Dark" \
        "breeze_cursors" \
        "/usr/share/wallpapers/cachyos-wallpapers/cachygalaxy99.jpg" \
        "prefer-dark"

    echo "✅ Estilo nativo Breeze aplicado (Kvantum desactivado, widgets nativos Qt6)."
}

# 6. Diagnostico visual
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

    local QT5_KVANTUM_STATUS="No instalado"
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

show_help() {
    cat <<EOF
🎨 Gestor de Apariencia y Suites de Temas - CachyOS (KDE Plasma 6)

Uso:
  $0 [OPCION]

Suites completas de temas (Kvantum + Colores + Iconos + GTK + Wallpapers):
  --catppuccin                  Aplica la suite Catppuccin Mocha completa.
  --nord, --nordic              Aplica la suite Nordic / CachyOS-Nord completa.
  --dracula                     Aplica la suite Dracula completa.
  --orchis                      Aplica la suite Orchis Dark completa.
  --breeze                      Aplica el estilo nativo limpio de KDE Plasma 6 (BreezeDark + Papirus).

Opciones avanzadas y gestion:
  --install-themes              Descarga e instala todos los paquetes y activos de las 4 suites.
  --kvantum-theme <TEMA>        Aplica un tema SVG especifico de Kvantum (ej. KvArcDark, KvAdaptaDark).
  --dark, -d                    Aplica tema oscuro predeterminado.
  --light, -l                   Aplica tema claro predeterminado.
  --status, -s                  Diagnostica el estado visual activo (Kvantum, Look&Feel, Iconos, GTK).
  --list, -l                    Lista todos los temas globales, esquemas, Kvantum e iconos instalados.
  --no-install                  Aplica la suite omitiendo la instalacion de paquetes pacman.
  --help, -h                    Muestra este mensaje de ayuda.
EOF
}

# ==============================================================================
# PROCESAMIENTO DE ARGUMENTOS
# ==============================================================================

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
        --install-themes)
            ACTION="install-themes"
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
        --kvantum|-k)
            ACTION="kvantum"
            ;;
        --kvantum-theme)
            ACTION="kvantum-theme"
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
    kvantum)
        configure_kvantum "KvDark"
        apply_core_appearance \
            "org.kde.breezedark.desktop" \
            "BreezeDark" \
            "Papirus-Dark" \
            "Breeze-Dark" \
            "breeze_cursors" \
            "" \
            "prefer-dark"
        ;;
    kvantum-theme)
        if [ -z "$ARG_THEME" ]; then
            echo "❌ Error: Debes especificar el nombre del tema Kvantum."
            echo "Uso: $0 --kvantum-theme <NOMBRE_TEMA> (ej. catppuccin-mocha-blue, Nordic, Ant-Dracula, Orchis-dark)"
            exit 1
        fi
        configure_kvantum "$ARG_THEME"
        apply_core_appearance \
            "" \
            "" \
            "Papirus-Dark" \
            "Breeze-Dark" \
            "breeze_cursors" \
            "" \
            "prefer-dark"
        ;;
    default)
        if [ "$NO_INSTALL" = true ]; then
            apply_theme_breeze
        else
            echo "================================================================="
            echo "🎨 CONFIGURADOR DE APARIENCIA - CACHYOS (KDE PLASMA 6)"
            echo "================================================================="
            install_base_packages
            apply_theme_breeze
        fi
        ;;
esac
