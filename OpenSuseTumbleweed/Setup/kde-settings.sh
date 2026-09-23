#!/bin/bash
# ==============================================================================
# kde-settings.sh - Configuración y Personalización Avanzada de KDE Plasma 6
# OpenSUSE Tumbleweed (KDE Plasma 6 + Wayland)
# ==============================================================================
# Optimizado para desarrollo de software, modo oscuro, Dolphin y estación de trabajo.
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
  (sin argumentos)    Aplica la configuración completa (Modo oscuro, fuentes, KWin, Dolphin, atajos y servicemenus).
  --dark, -d          Aplica el tema oscuro Breeze Dark.
  --light, -l         Aplica el tema claro Breeze Light.
  --status, -s        Muestra el estado actual de la sesión Plasma 6 y configuración.
  --help, -h          Muestra este mensaje de ayuda.

Configuraciones aplicadas:
  • Apariencia:       Breeze Dark global, iconos Papirus-Dark / Breeze-Dark, JetBrainsMono Nerd Font.
  • KWin Wayland:     Botones completos (minimizar, maximizar, cerrar a la derecha), Luz nocturna (4000K).
  • Dolphin:          Modo de visualización detallada, integración KIO para menús contextuales.
  • Terminal Kitty:   Terminal predeterminada, atajo global Ctrl+Alt+T, acción "Abrir en Kitty".
  • IDEs:             Menús contextuales en Dolphin para Antigravity y Antigravity IDE.
  • Integración GTK:  Temas oscuros para aplicaciones GTK3 y GTK4.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE KDE PLASMA 6 - OPENSUSE TUMBLEWEED"
    echo "================================================================="
    echo "• Entorno de escritorio:  ${XDG_CURRENT_DESKTOP:-Desconocido} (${XDG_SESSION_TYPE:-Desconocido})"
    echo "• Versión de Plasma:      $(plasmashell --version 2>/dev/null || echo 'No detectado')"
    echo "• Versión de KWin:        $(kwin_wayland --version 2>/dev/null || echo 'No detectado')"
    echo "-----------------------------------------------------------------"
    echo "• Tema Look & Feel:       $(kreadconfig6 --file kdeglobals --group General --key LookAndFeelPackage 2>/dev/null || echo 'Breeze')"
    echo "• Combinación de color:   $(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || echo 'No definida')"
    echo "• Tema de iconos:         $(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null || echo 'Breeze')"
    echo "• Terminal configurada:   $(kreadconfig6 --file kdeglobals --group General --key TerminalApplication 2>/dev/null || echo 'konsole')"
    echo "• Luz nocturna (KWin):    $(kreadconfig6 --file kwinrc --group NightColor --key Active 2>/dev/null || echo 'false')"
    echo "================================================================="
}

apply_dark() {
    echo "🌙 Aplicando tema oscuro completo en KDE Plasma 6 (Breeze Dark)..."
    run_as_user plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || \
    run_as_user plasma-apply-lookandfeel -a org.kde.breeze.dark.desktop 2>/dev/null || \
    run_as_user plasma-apply-colorscheme BreezeDark 2>/dev/null || true
    run_as_user kwriteconfig6 --file kdeglobals --group Icons --key Theme "Papirus-Dark" 2>/dev/null || true
    echo "  ✅ Modo oscuro aplicado."
}

apply_light() {
    echo "☀️ Aplicando tema claro en KDE Plasma 6 (Breeze Light)..."
    run_as_user plasma-apply-lookandfeel -a org.kde.breeze.desktop 2>/dev/null || \
    run_as_user plasma-apply-colorscheme BreezeLight 2>/dev/null || true
    run_as_user kwriteconfig6 --file kdeglobals --group Icons --key Theme "Papirus" 2>/dev/null || true
    echo "  ✅ Modo claro aplicado."
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
    --dark|-d|dark)
        apply_dark
        exit 0
        ;;
    --light|-l|light)
        apply_light
        exit 0
        ;;
esac

echo "================================================================="
echo "🎨 CONFIGURANDO ENTORNO KDE PLASMA 6 EN OPENSUSE TUMBLEWEED"
echo "================================================================="

# 1. Herramientas y paquetes base de KDE Plasma 6
echo "📦 [1/6] Verificando paquetes esenciales de KDE Plasma 6..."
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
    papirus-icon-theme \
    wl-clipboard 2>/dev/null || true

# 2. Apariencia, Tema Oscuro Global y Tipografía
echo "🌙 [2/6] Configurando tema oscuro global, iconos y tipografía..."
apply_dark

# Tipografía para programación (JetBrainsMono Nerd Font)
run_as_user kwriteconfig6 --file kdeglobals --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0" 2>/dev/null || true

# Integración con aplicaciones GTK (~/.config/gtk-3.0 y gtk-4.0)
run_as_user mkdir -p "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0"
cat <<'EOF' | run_as_user tee "$USER_HOME/.config/gtk-3.0/settings.ini" > /dev/null
[Settings]
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
gtk-font-name=Noto Sans 10
EOF

cat <<'EOF' | run_as_user tee "$USER_HOME/.config/gtk-4.0/settings.ini" > /dev/null
[Settings]
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
gtk-font-name=Noto Sans 10
EOF

# 3. KWin Wayland: Ventanas, Botones y Luz Nocturna
echo "🪟 [3/6] Configurando compositor KWin Wayland y Luz Nocturna..."
# Botones de ventana: Minimizar, Maximizar, Cerrar a la derecha
run_as_user kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnRight" "IAX" 2>/dev/null || true

# Luz nocturna (Night Color) a 4000K para reducir fatiga visual
run_as_user kwriteconfig6 --file kwinrc --group NightColor --key Active true 2>/dev/null || true
run_as_user kwriteconfig6 --file kwinrc --group NightColor --key NightTemperature 4000 2>/dev/null || true
run_as_user qdbus org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive true 2>/dev/null || true

# Reconfigurar KWin
run_as_user qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

# 4. Dolphin (Gestor de Archivos de KDE)
echo "📂 [4/6] Optimizando Dolphin para desarrollo y productividad..."
run_as_user kwriteconfig6 --file dolphinrc --group "General" --key "ViewMode" 1 2>/dev/null || true
run_as_user kwriteconfig6 --file dolphinrc --group "PreviewSettings" --key "Plugins" "audiothumbnail,comicbookthumbnail,djvuthumbnail,dvrthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraimagethumbnail,svgthumbnail,videothumbnail" 2>/dev/null || true

# 5. Terminal Kitty e Integración con Atajos de KDE Plasma 6
echo "🐱 [5/6] Configurando Kitty como terminal predeterminada y atajos..."
run_as_user kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty" 2>/dev/null || true
run_as_user kwriteconfig6 --file kdeglobals --group General --key TerminalService "kitty.desktop" 2>/dev/null || true

# Atajo global Ctrl+Alt+T para Kitty Terminal en KDE
run_as_user kwriteconfig6 --file kglobalshortcutsrc --group "services" --group "kitty.desktop" --key "_launch" "Ctrl+Alt+T,none,Kitty Terminal" 2>/dev/null || true

# 6. Menús Contextuales KIO de Dolphin (Servicemenus)
echo "🔗 [6/6] Creando acciones de menú contextual en Dolphin (KIO Servicemenus)..."
SERVICEMENUS_DIR="$USER_HOME/.local/share/kio/servicemenus"
run_as_user mkdir -p "$SERVICEMENUS_DIR"

# 6.1. Abrir en Kitty
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
Icon=kitty
Exec=kitty --directory "%f"
EOF

# 6.2. Abrir con Antigravity
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
Icon=antigravity
Exec=antigravity "%f"
EOF

# 6.3. Abrir con Antigravity IDE
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
Icon=antigravity-ide
Exec=antigravity-ide "%f"
EOF

# Permisos de ejecución para los archivos desktop de usuario
run_as_user chmod +x "$SERVICEMENUS_DIR"/*.desktop 2>/dev/null || true

echo "================================================================="
echo "✅ Configuración de KDE Plasma 6 completada con éxito."
echo "   - Tema oscuro Breeze Dark y Papirus-Dark aplicado."
echo "   - Tipografía: JetBrainsMono Nerd Font."
echo "   - Botones completos (minimizar, maximizar, cerrar)."
echo "   - Luz nocturna activa a 4000K."
echo "   - Dolphin configurado en modo detalles con menús contextuales."
echo "   - Terminal Kitty configurada con atajo Ctrl+Alt+T."
echo "================================================================="
