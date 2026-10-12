#!/usr/bin/env bash
# ==============================================================================
# kde-settings.sh - Configuración, Personalización y Estética de KDE Plasma 6
# Sistema: Fedora 44 Workstation (KDE Plasma 6 / Wayland)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Radeon Vega 7 / Btrfs)
# ==============================================================================
# Características:
# 1. Aplicaciones esenciales de KDE Gear con DNF5 (Dolphin, Kate, Spectacle, etc.).
# 2. Ergonomía KWin Wayland: Botones a la derecha (IAX) y Luz Nocturna (4000K).
# 3. Optimización de Dolphin: Modo vista detallada y miniaturas multimedia ricas.
# 4. Integración de Kitty Terminal: Terminal por defecto, atajo Ctrl+Alt+T y
#    menús contextuales KIO en Dolphin (Kitty, Antigravity, Antigravity IDE).
# 5. Homogeneización visual completa: Sincronización GTK3/GTK4 con tema oscuro.
# 6. Gestión de temas y estética: Breeze Dark, Breeze Light, Kvantum (SVG) y
#    iconos Papirus-Dark / Breeze-Dark oficiales.
# 7. Diagnóstico exhaustivo del entorno Plasma 6 (--status).
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
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

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
🎨 Configuración, Personalización y Estética de KDE Plasma 6 - Fedora 44

Uso:
  $0 [OPCIÓN]

Opciones principales:
  (sin argumentos)       Aplica optimizaciones de entorno (paquetes KDE Gear, Dolphin, KWin,
                         atajo Ctrl+Alt+T, Kitty y servicemenus) RESPETANDO tu tema visual actual.
  --status, -s           Muestra el estado detallado de temas, componentes y atajos en Plasma 6.
  --breeze-dark, -d      Cambia al tema oficial Breeze Dark de KDE con iconos y esquemas oscuros.
  --breeze-light, -l     Cambia al tema oficial Breeze Light de KDE.
  --kvantum              Configura Kvantum como motor de widgets Qt.
  --kvantum-theme <TEMA> Aplica un tema específico de Kvantum (ej. KvFlatDark, KvArcDark).
  --breeze-widgets       Restaura el estilo nativo de widgets Breeze (desactiva Kvantum).
  --papirus              Aplica el tema de iconos Papirus-Dark.
  --breeze-icons         Aplica el tema de iconos oficial Breeze-Dark.
  --list                 Muestra los temas globales, esquemas de color, iconos y temas Kvantum.
  --help, -h             Muestra este mensaje de ayuda.

Acciones de optimización base:
  • Paquetes KDE Gear:   Instala utilidades oficiales con DNF5 (Kate, Dolphin, Spectacle, Okular,
                         Gwenview, Ark, Partition Manager, ffmpegthumbs, wl-clipboard).
  • Ergonomía KWin:      Botones a la derecha (minimizar, maximizar, cerrar) y Luz Nocturna (4000K).
  • Productividad:       Dolphin en modo detallado con miniaturas multimedia completas.
  • Terminal & Atajos:   Kitty predeterminada y atajo global Ctrl+Alt+T.
  • Menú contextual:     Acciones de clic derecho en Dolphin (Abrir en Kitty, Antigravity, Antigravity IDE).
  • Homogeneidad GTK:    Sincroniza aplicaciones GTK3/GTK4 con modo oscuro y fuentes.
EOF
}

show_status() {
    local lookandfeel colorscheme plasma_theme icons cursor widget_style gtk_theme night_color
    lookandfeel=$(run_as_user kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null || echo "Desconocido")
    colorscheme=$(run_as_user kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || echo "Desconocido")
    plasma_theme=$(run_as_user kreadconfig6 --file plasmarc --group Theme --key name 2>/dev/null || echo "Breeze")
    icons=$(run_as_user kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null || echo "breeze-dark")
    cursor=$(run_as_user kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null || echo "breeze_cursors")
    widget_style=$(run_as_user kreadconfig6 --file kdeglobals --group KDE --key widgetStyle 2>/dev/null || echo "Breeze")
    gtk_theme=$(grep -s "gtk-theme-name" "$USER_HOME/.config/gtk-3.0/settings.ini" 2>/dev/null | cut -d= -f2 || echo "Breeze-Dark")
    night_color=$(run_as_user kreadconfig6 --file kwinrc --group NightColor --key Active 2>/dev/null || echo "false")

    echo "================================================================="
    echo "🔍 ESTADO DE KDE PLASMA 6 - FEDORA 44"
    echo "================================================================="
    echo "• Entorno de escritorio:  ${XDG_CURRENT_DESKTOP:-KDE} (${XDG_SESSION_TYPE:-wayland})"
    echo "• Versión de Plasma:      $(plasmashell --version 2>/dev/null || echo 'Plasma 6')"
    echo "• Versión de KWin:        $(kwin_wayland --version 2>/dev/null || echo 'KWin 6')"
    echo "-----------------------------------------------------------------"
    echo "• Tema Global:            $lookandfeel"
    echo "• Combinación de Color:   $colorscheme"
    echo "• Tema de Plasma:         $plasma_theme"
    echo "• Tema de Iconos:         $icons"
    echo "• Cursor del Ratón:       $cursor"
    echo "• Estilo de Widgets:      $widget_style"
    echo "• Tema GTK3 / GTK4:       $gtk_theme"
    echo "-----------------------------------------------------------------"
    echo "• Terminal por Defecto:   $(run_as_user kreadconfig6 --file kdeglobals --group General --key TerminalApplication 2>/dev/null || echo 'No configurada')"
    echo "• Atajo Ctrl+Alt+T:       $(run_as_user kreadconfig6 --file kglobalshortcutsrc --group services --group kitty.desktop --key _launch 2>/dev/null || echo 'No configurado')"
    echo "• Botones de Ventana:     $(run_as_user kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight 2>/dev/null || echo 'IAX')"
    echo "• Luz nocturna (Night):   $(if [ "$night_color" = "true" ]; then echo "✅ Activa (4000K)"; else echo "❌ Inactiva"; fi)"
    echo "• Servicemenus Dolphin:   $(if [ -f "$USER_HOME/.local/share/kio/servicemenus/open-in-kitty.desktop" ]; then echo "✅ Kitty / Antigravity instalados"; else echo "❌ No instalados"; fi)"
    echo "================================================================="
}

apply_breeze_dark() {
    echo "🌙 Aplicando tema Breeze Dark estándar de KDE..."
    run_as_user plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || \
    run_as_user plasma-apply-lookandfeel -a org.kde.breeze.dark.desktop 2>/dev/null || \
    run_as_user plasma-apply-colorscheme BreezeDark 2>/dev/null || true
    run_as_user kwriteconfig6 --file kdeglobals --group Icons --key Theme "breeze-dark" 2>/dev/null || true
    run_as_user kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "breeze_cursors" 2>/dev/null || true
    sync_gtk "Breeze-Dark" "breeze-dark" "1"
    echo "  ✅ Modo oscuro Breeze Dark aplicado."
}

apply_breeze_light() {
    echo "☀️ Aplicando tema claro Breeze Light de KDE..."
    run_as_user plasma-apply-lookandfeel -a org.kde.breeze.desktop 2>/dev/null || \
    run_as_user plasma-apply-colorscheme BreezeLight 2>/dev/null || true
    run_as_user kwriteconfig6 --file kdeglobals --group Icons --key Theme "breeze" 2>/dev/null || true
    run_as_user kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "breeze_cursors" 2>/dev/null || true
    sync_gtk "Breeze" "breeze" "0"
    echo "  ✅ Modo claro Breeze Light aplicado."
}

apply_kvantum() {
    echo "🔮 Configurando motor de estilos Kvantum..."
    if ! rpm -q kvantum >/dev/null 2>&1; then
        $SUDO dnf5 install -y kvantum kvantum-qt5 kvantum-qt6 2>/dev/null || $SUDO dnf5 install -y kvantum 2>/dev/null || true
    fi
    run_as_user kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "kvantum" 2>/dev/null || true
    echo "  ✅ Estilo de widgets Kvantum aplicado."
}

apply_kvantum_theme() {
    local theme="${1:-KvFlatDark}"
    apply_kvantum
    echo "🔮 Aplicando tema Kvantum '$theme'..."
    run_as_user mkdir -p "$USER_HOME/.config/Kvantum"
    cat <<EOF | run_as_user tee "$USER_HOME/.config/Kvantum/kvantum.kvconfig" > /dev/null
[General]
theme=$theme
EOF
    echo "  ✅ Tema de Kvantum '$theme' configurado en kvantum.kvconfig."
}

apply_breeze_widgets() {
    echo "💨 Restableciendo estilo nativo de widgets Breeze..."
    run_as_user kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "Breeze" 2>/dev/null || true
    echo "  ✅ Widgets de KDE Breeze restaurados."
}

apply_papirus_icons() {
    echo "🎨 Configurando tema de iconos Papirus-Dark..."
    if ! rpm -q papirus-icon-theme >/dev/null 2>&1; then
        $SUDO dnf5 install -y papirus-icon-theme 2>/dev/null || true
    fi
    run_as_user kwriteconfig6 --file kdeglobals --group Icons --key Theme "Papirus-Dark" 2>/dev/null || true
    echo "  ✅ Iconos Papirus-Dark aplicados."
}

apply_breeze_icons() {
    echo "🎨 Configurando tema de iconos Breeze-Dark..."
    run_as_user kwriteconfig6 --file kdeglobals --group Icons --key Theme "breeze-dark" 2>/dev/null || true
    echo "  ✅ Iconos Breeze-Dark aplicados."
}

sync_gtk() {
    local theme="${1:-Breeze-Dark}"
    local icon_theme="${2:-breeze-dark}"
    local dark_mode="${3:-1}"

    run_as_user mkdir -p "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0"
    cat <<EOF | run_as_user tee "$USER_HOME/.config/gtk-3.0/settings.ini" > /dev/null
[Settings]
gtk-theme-name=$theme
gtk-icon-theme-name=$icon_theme
gtk-application-prefer-dark-theme=$dark_mode
gtk-font-name=Noto Sans 10
EOF

    cat <<EOF | run_as_user tee "$USER_HOME/.config/gtk-4.0/settings.ini" > /dev/null
[Settings]
gtk-theme-name=$theme
gtk-icon-theme-name=$icon_theme
gtk-application-prefer-dark-theme=$dark_mode
gtk-font-name=Noto Sans 10
EOF
}

list_themes() {
    echo "================================================================="
    echo "🎨 TEMAS Y ELEMENTOS VISUALES DISPONIBLES EN EL SISTEMA"
    echo "================================================================="
    echo "📦 Temas Globales (Look & Feel):"
    plasma-apply-lookandfeel --list 2>/dev/null || echo "  (Utiliza Ajustes del Sistema)"
    echo ""
    echo "🌈 Esquemas de Color:"
    plasma-apply-colorscheme --list 2>/dev/null || echo "  (Utiliza Ajustes del Sistema)"
    echo ""
    echo "📁 Temas de Iconos:"
    find /usr/share/icons ~/.local/share/icons -maxdepth 1 -type d 2>/dev/null | sed 's|.*/||' | sort -u | grep -v '^icons$' | head -n 15 | sed 's/^/  ✓ /'
    echo ""
    echo "🔮 Temas Kvantum instalados:"
    if [ -d "/usr/share/Kvantum" ] || [ -d "$USER_HOME/.config/Kvantum" ]; then
        find /usr/share/Kvantum "$USER_HOME/.config/Kvantum" -maxdepth 1 -type d 2>/dev/null | sed 's|.*/||' | sort -u | grep -v 'Kvantum' | head -n 10 | sed 's/^/  ✓ /' || echo "  (Ninguno)"
    else
        echo "  (Kvantum no instalado)"
    fi
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# PARSEO DE ARGUMENTOS
# ------------------------------------------------------------------------------
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --list|-l|list)
        list_themes
        exit 0
        ;;
    --breeze-dark|--dark|-d|dark)
        apply_breeze_dark
        exit 0
        ;;
    --breeze-light|--light|-l|light)
        apply_breeze_light
        exit 0
        ;;
    --kvantum|kvantum)
        apply_kvantum
        exit 0
        ;;
    --kvantum-theme)
        shift || true
        apply_kvantum_theme "${1:-KvFlatDark}"
        exit 0
        ;;
    --breeze-widgets)
        apply_breeze_widgets
        exit 0
        ;;
    --papirus|--papirus-icons)
        apply_papirus_icons
        exit 0
        ;;
    --breeze-icons)
        apply_breeze_icons
        exit 0
        ;;
    "")
        # Ejecución por defecto: Optimización del entorno
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac

echo "================================================================="
echo "🎨 OPTIMIZANDO ENTORNO KDE PLASMA 6 - FEDORA 44"
echo "================================================================="

# 1. Herramientas y paquetes base de KDE Plasma 6
echo "📦 [1/5] Verificando aplicaciones esenciales del ecosistema KDE Gear con DNF5..."
$SUDO dnf5 install -y \
    dolphin \
    kate \
    spectacle \
    kcalc \
    ark \
    gwenview \
    okular \
    plasma-systemmonitor \
    partitionmanager \
    kinfocenter \
    kio-extras \
    dolphin-plugins \
    ffmpegthumbs \
    wl-clipboard \
    kvantum \
    papirus-icon-theme 2>/dev/null || true

# 2. Tipografía y Sincronización GTK
echo "🌙 [2/5] Sincronizando tipografía y compatibilidad GTK3/GTK4..."
if fc-list "JetBrainsMono Nerd Font" 2>/dev/null | grep -i "JetBrainsMono" >/dev/null; then
    run_as_user kwriteconfig6 --file kdeglobals --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0" 2>/dev/null || true
fi

# Integración con aplicaciones GTK (~/.config/gtk-3.0 y gtk-4.0)
sync_gtk "Breeze-Dark" "breeze-dark" "1"

# 3. KWin Wayland: Ventanas, Botones y Luz Nocturna
echo "🪟 [3/5] Configurando compositor KWin Wayland y Luz Nocturna..."
# Botones de ventana: Minimizar, Maximizar, Cerrar a la derecha (IAX)
run_as_user kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnRight" "IAX" 2>/dev/null || true

# Luz nocturna (Night Color) a 4000K para reducir fatiga visual
run_as_user kwriteconfig6 --file kwinrc --group NightColor --key Active true 2>/dev/null || true
run_as_user kwriteconfig6 --file kwinrc --group NightColor --key NightTemperature 4000 2>/dev/null || true
run_as_user qdbus6 org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive true 2>/dev/null || \
run_as_user qdbus org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive true 2>/dev/null || true

# Reconfigurar KWin
run_as_user qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || \
run_as_user qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

# 4. Dolphin (Gestor de Archivos de KDE)
echo "📂 [4/5] Optimizando Dolphin para desarrollo y productividad..."
# Modo vista detallada (lista con detalles)
run_as_user kwriteconfig6 --file dolphinrc --group "General" --key "ViewMode" 1 2>/dev/null || true
# Habilitar vista previa de miniaturas para todo tipo de archivos
run_as_user kwriteconfig6 --file dolphinrc --group "PreviewSettings" --key "Plugins" "audiothumbnail,comicbookthumbnail,djvuthumbnail,dvrthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraimagethumbnail,svgthumbnail,videothumbnail" 2>/dev/null || true

# 5. Terminal Kitty y Menús Contextuales KIO de Dolphin
echo "🔗 [5/5] Configurando atajos de terminal y menús contextuales en Dolphin..."
run_as_user kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty" 2>/dev/null || true
run_as_user kwriteconfig6 --file kdeglobals --group General --key TerminalService "kitty.desktop" 2>/dev/null || true
run_as_user kwriteconfig6 --file kglobalshortcutsrc --group "services" --group "kitty.desktop" --key "_launch" "Ctrl+Alt+T,none,Kitty Terminal" 2>/dev/null || true

SERVICEMENUS_DIR="$USER_HOME/.local/share/kio/servicemenus"
run_as_user mkdir -p "$SERVICEMENUS_DIR"

# 5.1. Abrir en Kitty
cat <<'EOF' | run_as_user tee "$SERVICEMENUS_DIR/open-in-kitty.desktop" > /dev/null
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=inode/directory;
Actions=openInKitty;
X-KDE-Priority=TopLevel

[Desktop Action openInKitty]
Name=Abrir en Kitty
Name[es]=Abrir en Kitty
Name[en]=Open in Kitty
Icon=kitty
Exec=kitty --directory "%f"
EOF

# 5.2. Abrir con Antigravity
cat <<'EOF' | run_as_user tee "$SERVICEMENUS_DIR/open-in-antigravity.desktop" > /dev/null
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=inode/directory;
Actions=openInAntigravity;
X-KDE-Priority=TopLevel

[Desktop Action openInAntigravity]
Name=Abrir con Antigravity
Name[es]=Abrir con Antigravity
Name[en]=Open in Antigravity
Icon=antigravity
Exec=antigravity "%f"
EOF

# 5.3. Abrir con Antigravity IDE
cat <<'EOF' | run_as_user tee "$SERVICEMENUS_DIR/open-in-antigravity-ide.desktop" > /dev/null
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=inode/directory;
Actions=openInAntigravityIde;
X-KDE-Priority=TopLevel

[Desktop Action openInAntigravityIde]
Name=Abrir con Antigravity IDE
Name[es]=Abrir con Antigravity IDE
Name[en]=Open in Antigravity IDE
Icon=antigravity-ide
Exec=antigravity-ide "%f"
EOF

run_as_user chmod +x "$SERVICEMENUS_DIR"/*.desktop 2>/dev/null || true

echo "================================================================="
echo "✅ Optimización de KDE Plasma 6 en Fedora 44 completada con éxito."
echo "   • Tu tema visual se mantiene intacto."
echo "   • Aplicaciones GTK sincronizadas con modo oscuro."
echo "   • Botones de ventana a la derecha y Luz Nocturna configurada (4000K)."
echo "   • Dolphin optimizado en modo detalles con miniaturas enriquecidas."
echo "   • Atajo global Ctrl+Alt+T para Kitty configurado."
echo "   • Acciones de clic derecho en Dolphin (Kitty, Antigravity) listas."
echo "================================================================="
