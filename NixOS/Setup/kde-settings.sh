#!/usr/bin/env bash
# ==============================================================================
# kde-settings.sh - Configuración y Personalización Avanzada de KDE Plasma 6
# NixOS (KDE Plasma 6 + Wayland)
# ==============================================================================
# Preserva la apariencia elegante y optimiza Dolphin, KWin, atajos y productividad.
# ==============================================================================

set -euo pipefail

# Detectar usuario real
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
🎨 Configuración y Personalización de KDE Plasma 6 - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica optimizaciones de entorno (Dolphin, KWin, atajo Ctrl+Alt+T, Kitty y servicemenus).
  --status, -s        Muestra el estado detallado de temas, componentes y atajos en Plasma 6.
  --breeze-dark, -d   Cambia al tema oficial Breeze Dark de KDE.
  --breeze-light, -l  Cambia al tema claro Breeze Light de KDE.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE CONFIGURACIÓN DE KDE PLASMA 6 - NIXOS"
    echo "================================================================="
    echo "• Tema Global activo:       $(grep -i "lookAndFeelPackage=" "$USER_HOME/.config/kdeglobals" 2>/dev/null | cut -d= -f2 || echo "Por defecto")"
    echo "• Esquema de Colores:       $(grep -i "ColorScheme=" "$USER_HOME/.config/kdeglobals" 2>/dev/null | cut -d= -f2 || echo "Por defecto")"
    echo "• Tema de Iconos:           $(grep -i "Theme=" "$USER_HOME/.config/kdeglobals" 2>/dev/null | cut -d= -f2 || echo "Breeze")"
    echo "• Terminal Ctrl+Alt+T:      $(if grep -q "kitty" "$USER_HOME/.config/kglobalshortcutsrc" 2>/dev/null; then echo "✅ Configurado para Kitty"; else echo "❌ No configurado"; fi)"
    echo "• Servicemenus Dolphin:     $(if [ -f "$USER_HOME/.local/share/kio/servicemenus/open-in-kitty.desktop" ]; then echo "✅ Kitty activo"; else echo "❌ Kitty ausente"; fi) / $(if [ -f "$USER_HOME/.local/share/kio/servicemenus/open-in-antigravity.desktop" ]; then echo "✅ Antigravity activo"; else echo "❌ Antigravity ausente"; fi)"
    echo "• Luz Nocturna (KWin):      $(if grep -q "Active=true" "$USER_HOME/.config/kwinrc" 2>/dev/null; then echo "✅ Activa (4000K)"; else echo "ℹ️ Inactiva"; fi)"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --breeze-dark|-d|dark)
        run_as_user plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || true
        run_as_user plasma-apply-colorscheme BreezeDark 2>/dev/null || true
        echo "🌙 Tema Breeze Dark aplicado."
        exit 0
        ;;
    --breeze-light|-l|light)
        run_as_user plasma-apply-lookandfeel -a org.kde.breeze.desktop 2>/dev/null || true
        run_as_user plasma-apply-colorscheme BreezeLight 2>/dev/null || true
        echo "☀️ Tema Breeze Light aplicado."
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🚀 CONFIGURANDO Y PERSONALIZANDO KDE PLASMA 6 (NIXOS)"
echo "================================================================="

# 1. Configurar KWin botones y renderizado
echo "ℹ️ [1/5] Optimizando comportamiento de ventanas KWin en Wayland..."
run_as_user kwriteconfig6 --file "$USER_HOME/.config/kwinrc" --group "org.kde.kdecoration2" --key "ButtonsOnRight" "IAX" 2>/dev/null || true
run_as_user kwriteconfig6 --file "$USER_HOME/.config/kwinrc" --group "Windows" --key "DelayFocus" "false" 2>/dev/null || true

# 2. Configurar Luz Nocturna (Night Color a 4000K)
echo "ℹ️ [2/5] Configurando Luz Nocturna (Night Color)..."
run_as_user kwriteconfig6 --file "$USER_HOME/.config/kwinrc" --group "NightColor" --key "Active" "true" 2>/dev/null || true
run_as_user kwriteconfig6 --file "$USER_HOME/.config/kwinrc" --group "NightColor" --key "Mode" "Location" 2>/dev/null || true
run_as_user kwriteconfig6 --file "$USER_HOME/.config/kwinrc" --group "NightColor" --key "NightTemperature" "4000" 2>/dev/null || true

# 3. Dolphin mejoras y vista de archivos
echo "ℹ️ [3/5] Configurando preferencias de Dolphin..."
run_as_user kwriteconfig6 --file "$USER_HOME/.config/dolphinrc" --group "General" --key "ShowFullPath" "true" 2>/dev/null || true
run_as_user kwriteconfig6 --file "$USER_HOME/.config/dolphinrc" --group "General" --key "RememberOpenedTabs" "true" 2>/dev/null || true
run_as_user kwriteconfig6 --file "$USER_HOME/.config/dolphinrc" --group "PreviewSettings" --key "Plugins" "audiothumbnail,directorythumbnail,djvuthumbnail,exrthumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraviewprovider,mobithumbnail,opendocumentthumbnail,pdfthumbnail,svgthumbnail,textthumbnail,videothumbnail" 2>/dev/null || true

# 4. Servicemenus de Dolphin (Kitty y Google Antigravity)
echo "ℹ️ [4/5] Instalando acciones de menú contextual (servicemenus) en Dolphin..."
mkdir -p "$USER_HOME/.local/share/kio/servicemenus"

cat << 'EOF' > "$USER_HOME/.local/share/kio/servicemenus/open-in-kitty.desktop"
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=openInKitty;
X-KDE-Priority=TopLevel
Icon=kitty

[Desktop Action openInKitty]
Name=Abrir en Kitty
Name[en]=Open in Kitty
Icon=kitty
Exec=kitty --directory "%f"
EOF

cat << 'EOF' > "$USER_HOME/.local/share/kio/servicemenus/open-in-antigravity.desktop"
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=openInAntigravity;
X-KDE-Priority=TopLevel
Icon=antigravity

[Desktop Action openInAntigravity]
Name=Abrir en Antigravity
Name[en]=Open in Antigravity
Icon=antigravity
Exec=antigravity "%f"
EOF

chown -R "$REAL_USER:" "$USER_HOME/.local/share/kio/servicemenus" 2>/dev/null || true

# 5. Atajo de teclado global Ctrl+Alt+T para Kitty
echo "ℹ️ [5/5] Registrando atajo Ctrl+Alt+T para terminal Kitty..."
run_as_user kwriteconfig6 --file "$USER_HOME/.config/kglobalshortcutsrc" --group "kitty.desktop" --key "_launch" "Ctrl+Alt+T,Ctrl+Alt+T,Lanzar kitty" 2>/dev/null || true

echo "================================================================="
echo "✅ Preferencias de KDE Plasma 6 aplicadas correctamente."
echo "================================================================="
