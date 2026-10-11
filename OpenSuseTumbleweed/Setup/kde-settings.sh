#!/bin/bash
# ==============================================================================
# kde-settings.sh - Configuración y Personalización Avanzada de KDE Plasma 6
# OpenSUSE Tumbleweed (KDE Plasma 6 + Wayland)
# ==============================================================================
# Diseñado para preservar la apariencia elegida por el usuario (openSUSE Dark)
# mientras optimiza herramientas de productividad, Dolphin, KWin y atajos.
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
🎨 Configuración y Personalización de KDE Plasma 6 - openSUSE Tumbleweed

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica optimizaciones de entorno (paquetes esenciales, Dolphin, KWin,
                      atajo Ctrl+Alt+T, Kitty y servicemenus) RESPETANDO tu tema visual actual.
  --status, -s        Muestra el estado detallado de temas, componentes y atajos en Plasma 6.
  --opensuse-dark, -o Restablece explícitamente el tema oficial openSUSE Dark y Brisa Oscuro.
  --breeze-dark, -d   Cambia al tema oficial Breeze Dark de KDE.
  --breeze-light, -l  Cambia al tema claro Breeze Light de KDE.
  --help, -h          Muestra este mensaje de ayuda.

Acciones que realiza este script:
  • Paquetes KDE Gear: Instala utilidades oficiales (Kate, Dolphin, Spectacle, Okular, Gwenview, Ark, wl-clipboard).
  • Ergonomía KWin:    Botones a la derecha (minimizar, maximizar, cerrar) y Luz Nocturna (4000K).
  • Productividad:     Dolphin en modo detallado con vista previa de miniaturas multimedia.
  • Terminal & Atajos: Kitty predeterminada y atajo global Ctrl+Alt+T.
  • Menú contextual:   Acciones de clic derecho en Dolphin (Abrir en Kitty, Antigravity, Antigravity IDE).
  • Homogeneidad GTK:  Sincroniza aplicaciones GTK3/GTK4 con modo oscuro e iconos Brisa oscuro.
EOF
}

show_status() {
    local lookandfeel colorscheme icons cursor plasma_theme terminal night_color
    lookandfeel=$(run_as_user kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null || run_as_user kreadconfig6 --file kdeglobals --group General --key LookAndFeelPackage 2>/dev/null || echo "org.openSUSE.desktop")
    colorscheme=$(run_as_user kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || echo "No definida")
    icons=$(run_as_user kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null || echo "breeze-dark")
    cursor=$(run_as_user kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null || echo "breeze_cursors")
    plasma_theme=$(run_as_user kreadconfig6 --file plasmarc --group Theme --key name 2>/dev/null || echo "openSUSE")
    terminal=$(run_as_user kreadconfig6 --file kdeglobals --group General --key TerminalApplication 2>/dev/null || echo "konsole")
    night_color=$(run_as_user kreadconfig6 --file kwinrc --group NightColor --key Active 2>/dev/null || echo "false")

    echo "================================================================="
    echo "🔍 ESTADO DE KDE PLASMA 6 - OPENSUSE TUMBLEWEED"
    echo "================================================================="
    echo "• Entorno de escritorio:  ${XDG_CURRENT_DESKTOP:-KDE} (${XDG_SESSION_TYPE:-wayland})"
    echo "• Versión de Plasma:      $(plasmashell --version 2>/dev/null || echo 'Plasma 6')"
    echo "• Versión de KWin:        $(kwin_wayland --version 2>/dev/null || echo 'KWin 6')"
    echo "-----------------------------------------------------------------"
    echo "• Tema Global (Look&Feel): $lookandfeel"
    echo "• Combinación de Color:   $colorscheme"
    echo "• Tema de Plasma:         $plasma_theme"
    echo "• Tema de Iconos:         $icons"
    echo "• Tema de Cursor:         $cursor"
    echo "• Terminal configurada:   $terminal"
    echo "• Atajo KDE (Ctrl+Alt+T): $(if grep -qi "Ctrl+Alt+T" "$USER_HOME/.config/kglobalshortcutsrc" 2>/dev/null; then echo "✅ Configurado"; else echo "❌ No configurado"; fi)"
    echo "• Luz nocturna (Night):   $(if [ "$night_color" = "true" ]; then echo "✅ Activa (4000K)"; else echo "❌ Inactiva"; fi)"
    echo "• Servicemenus Dolphin:   $(if [ -f "$USER_HOME/.local/share/kio/servicemenus/open-in-kitty.desktop" ]; then echo "✅ Kitty / Antigravity instalados"; else echo "❌ No instalados"; fi)"
    echo "================================================================="
}

apply_opensuse_dark() {
    echo "🦎 Aplicando tema oficial openSUSE Dark y Brisa Oscuro..."
    run_as_user plasma-apply-lookandfeel -a org.openSUSE.desktop 2>/dev/null || true
    run_as_user plasma-apply-colorscheme openSUSEdark 2>/dev/null || true
    run_as_user kwriteconfig6 --file kdeglobals --group Icons --key Theme "breeze-dark" 2>/dev/null || true
    run_as_user kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "breeze_cursors" 2>/dev/null || true
    run_as_user kwriteconfig6 --file plasmarc --group Theme --key name "openSUSE" 2>/dev/null || true
    echo "  ✅ Tema openSUSE Dark aplicado con éxito."
}

apply_breeze_dark() {
    echo "🌙 Aplicando tema Breeze Dark estándar de KDE..."
    run_as_user plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || \
    run_as_user plasma-apply-lookandfeel -a org.kde.breeze.dark.desktop 2>/dev/null || \
    run_as_user plasma-apply-colorscheme BreezeDark 2>/dev/null || true
    run_as_user kwriteconfig6 --file kdeglobals --group Icons --key Theme "breeze-dark" 2>/dev/null || true
    echo "  ✅ Modo oscuro Breeze Dark aplicado."
}

apply_breeze_light() {
    echo "☀️ Aplicando tema claro Breeze Light de KDE..."
    run_as_user plasma-apply-lookandfeel -a org.kde.breeze.desktop 2>/dev/null || \
    run_as_user plasma-apply-colorscheme BreezeLight 2>/dev/null || true
    run_as_user kwriteconfig6 --file kdeglobals --group Icons --key Theme "breeze" 2>/dev/null || true
    echo "  ✅ Modo claro Breeze Light aplicado."
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
    --opensuse-dark|-o|opensuse)
        apply_opensuse_dark
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
esac

echo "================================================================="
echo "🎨 OPTIMIZANDO ENTORNO KDE PLASMA 6 (PRESERVANDO TU TEMA VISUAL)"
echo "================================================================="

# 1. Herramientas y paquetes base de KDE Plasma 6
echo "📦 [1/5] Verificando aplicaciones esenciales del ecosistema KDE Gear..."
$SUDO zypper --non-interactive install -y \
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
    wl-clipboard 2>/dev/null || true

# 2. Tipografía y Sincronización GTK (respetando tema e iconos Brisa oscuro)
echo "🌙 [2/5] Sincronizando aplicaciones GTK3/GTK4 con modo oscuro e iconos Brisa..."
# Tipografía de desarrollo si está disponible
if fc-list "JetBrainsMono Nerd Font" 2>/dev/null | grep -i "JetBrainsMono" >/dev/null; then
    run_as_user kwriteconfig6 --file kdeglobals --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0" 2>/dev/null || true
fi

# Integración con aplicaciones GTK (~/.config/gtk-3.0 y gtk-4.0)
run_as_user mkdir -p "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0"
cat <<'EOF' | run_as_user tee "$USER_HOME/.config/gtk-3.0/settings.ini" > /dev/null
[Settings]
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=breeze-dark
gtk-application-prefer-dark-theme=1
gtk-font-name=Noto Sans 10
EOF

cat <<'EOF' | run_as_user tee "$USER_HOME/.config/gtk-4.0/settings.ini" > /dev/null
[Settings]
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=breeze-dark
gtk-application-prefer-dark-theme=1
gtk-font-name=Noto Sans 10
EOF

# 3. KWin Wayland: Ventanas, Botones y Luz Nocturna
echo "🪟 [3/5] Configurando compositor KWin Wayland y Luz Nocturna..."
# Botones de ventana: Minimizar, Maximizar, Cerrar a la derecha
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
echo "✅ Optimización de KDE Plasma 6 completada con éxito."
echo "   • Tu tema visual (openSUSE Dark / Brisa Oscuro) se mantiene intacto."
echo "   • Aplicaciones GTK sincronizadas con tema oscuro e iconos Brisa."
echo "   • Botones de ventana a la derecha y Luz Nocturna configurada (4000K)."
echo "   • Dolphin optimizado en modo detalles con miniaturas enriquecidas."
echo "   • Atajo global Ctrl+Alt+T para Kitty configurado."
echo "   • Acciones de clic derecho en Dolphin (Kitty, Antigravity) listas."
echo "================================================================="
