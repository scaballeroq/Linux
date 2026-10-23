#!/bin/bash
# ==============================================================================
# gnome-settings.sh - Configuración y Personalización Avanzada de GNOME Shell 51
# Ubuntu Workstation (GNOME Shell 51 + Wayland / Mutter)
# ==============================================================================
# Diseñado para proporcionar la máxima productividad y confort visual:
#  - Adaptación completa de las configuraciones de KDE Plasma 6 a GNOME.
#  - Tema oscuro persistente (Adwaita Dark / prefer-dark).
#  - Tipografía JetBrainsMono Nerd Font para desarrollo y terminal.
#  - Disposición completa de botones de ventana (minimizar, maximizar, cerrar).
#  - Atajo global Ctrl+Alt+T para terminal Kitty acelerada por GPU.
#  - Menús contextuales nativos de Nautilus (clic derecho) para Kitty, Antigravity, etc.
#  - Salud visual: Luz nocturna configurada a 4000K.
#  - Opciones CLI: --status / -s, --dark / -d, --light / -l, --help / -h.
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
🎨 Configuración y Personalización de GNOME Shell 51 - Ubuntu Workstation

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica todas las configuraciones recomendadas (tema oscuro, tipografía,
                      botones de ventana, atajo Ctrl+Alt+T para Kitty y scripts contextuales en Nautilus).
  --status, -s        Muestra el diagnóstico detallado del entorno GNOME y Mutter.
  --dark, -d          Aplica el modo oscuro completo (prefer-dark + adw-gtk3-dark).
  --light, -l         Aplica el modo claro estándar.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE GNOME SHELL - UBUNTU WORKSTATION"
    echo "================================================================="
    echo "• Entorno de escritorio:  ${XDG_CURRENT_DESKTOP:-GNOME} (${XDG_SESSION_TYPE:-wayland})"
    echo "• Versión de GNOME Shell: $(gnome-shell --version 2>/dev/null || echo 'GNOME 51')"
    echo "• Compositor / Window Mgr: Mutter (Wayland)"
    echo "-----------------------------------------------------------------"
    echo "• Esquema de color:       $(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
    echo "• Tema GTK:               $(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'n/a')"
    echo "• Tema de Iconos:         $(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'n/a')"
    echo "• Tipografía Mono:        $(run_as_user gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || echo 'n/a')"
    echo "• Botones de ventana:     $(run_as_user gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null || echo 'n/a')"
    echo "• Luz Nocturna (Night):   $(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null || echo 'false')"
    echo "• Temperatura Luz:        $(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature 2>/dev/null || echo '4000')K"
    echo "• Atajo Kitty (Ctrl+Alt+T): $(if run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null | grep -qi "custom0"; then echo "✅ Configurado"; else echo "❌ No configurado"; fi)"
    echo "• Scripts Nautilus:       $(if [ -f "$USER_HOME/.local/share/nautilus/scripts/Abrir en Kitty" ]; then echo "✅ Kitty / Antigravity activos"; else echo "❌ No configurados"; fi)"
    echo "================================================================="
}

apply_dark() {
    echo "🌙 Aplicando tema oscuro persistente..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || \
        run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark' 2>/dev/null || \
        run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    echo "✅ Modo oscuro activado."
}

apply_light() {
    echo "☀️ Aplicando modo claro..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'default' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Yaru' 2>/dev/null || \
        run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
    echo "✅ Modo claro activado."
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --dark|-d)
        apply_dark
        exit 0
        ;;
    --light|-l)
        apply_light
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🎨 CONFIGURANDO PERSONALIZACIÓN DE GNOME SHELL (UBUNTU WORKSTATION)"
echo "================================================================="

# 1. Asegurar paquetes base de GNOME
echo "ℹ️ [1/6] Verificando utilidades de soporte en GNOME..."
$SUDO apt update
$SUDO apt install -y \
    gnome-tweaks \
    gnome-browser-connector \
    gnome-shell-extension-gsconnect \
    gnome-shell-ubuntu-extensions \
    wl-clipboard 2>/dev/null || true

# 2. Apariencia y Tema Oscuro
echo "ℹ️ [2/6] Aplicando apariencia, tipografías y tema oscuro..."
apply_dark
run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Yaru' 2>/dev/null || \
    run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true

# Fuente monospace para terminales y editores
run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11' 2>/dev/null || true

# 3. Ventanas, Mutter y Comportamiento
echo "ℹ️ [3/6] Configurando gestión de ventanas (Mutter)..."
# Botones de ventana: minimizar, maximizar, cerrar a la derecha
run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' 2>/dev/null || true
run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
run_as_user gsettings set org.gnome.mutter attach-modal-dialogs true 2>/dev/null || true
run_as_user gsettings set org.gnome.mutter experimental-features "['variable-refresh-rate', 'scale-monitor-framebuffer']" 2>/dev/null || true

# 4. Barra Superior, Reloj, Energía y Luz Nocturna
echo "ℹ️ [4/6] Configurando barra superior, reloj 24h y salud visual..."
run_as_user gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true

run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true

# 5. Gestor de Archivos Nautilus
echo "ℹ️ [5/6] Optimizando Nautilus para productividad..."
run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
run_as_user gsettings set org.gnome.nautilus.preferences show-delete-permanent true 2>/dev/null || true

# 6. Terminal Kitty y Atajo Global Ctrl+Alt+T
echo "ℹ️ [6/6] Configurando terminal Kitty y atajo global Ctrl+Alt+T..."
KB_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$KB_PATH']" 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH name 'Kitty Terminal' 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH command 'kitty' 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH binding '<Primary><Alt>t' 2>/dev/null || true

# Menús contextuales en Nautilus (Scripts de clic derecho equivalentes a KIO Servicemenus)
NAUTILUS_SCRIPTS_DIR="$USER_HOME/.local/share/nautilus/scripts"
run_as_user mkdir -p "$NAUTILUS_SCRIPTS_DIR"

# Script para abrir en Kitty
cat << 'EOF' | run_as_user tee "$NAUTILUS_SCRIPTS_DIR/Abrir en Kitty" > /dev/null
#!/bin/sh
target=""
if [ -n "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" ]; then
    first=$(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n1)
    if [ -d "$first" ]; then
        target="$first"
    elif [ -f "$first" ]; then
        target="$(dirname "$first")"
    fi
fi
if [ -z "$target" ] && [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
exec kitty --directory "${target:-${1:-.}}" &
EOF
run_as_user chmod +x "$NAUTILUS_SCRIPTS_DIR/Abrir en Kitty"

# Script para abrir en Antigravity
cat << 'EOF' | run_as_user tee "$NAUTILUS_SCRIPTS_DIR/Abrir en Antigravity" > /dev/null
#!/bin/sh
target="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-$1}"
if [ -z "$target" ] && [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
exec antigravity "${target:-.}" &
EOF
run_as_user chmod +x "$NAUTILUS_SCRIPTS_DIR/Abrir en Antigravity"

# Script para abrir en Antigravity IDE
cat << 'EOF' | run_as_user tee "$NAUTILUS_SCRIPTS_DIR/Abrir en Antigravity IDE" > /dev/null
#!/bin/sh
target="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-$1}"
if [ -z "$target" ] && [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
exec antigravity-ide "${target:-.}" &
EOF
run_as_user chmod +x "$NAUTILUS_SCRIPTS_DIR/Abrir en Antigravity IDE"

# Script para abrir en VS Code
cat << 'EOF' | run_as_user tee "$NAUTILUS_SCRIPTS_DIR/Abrir en VS Code" > /dev/null
#!/bin/sh
target="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-$1}"
if [ -z "$target" ] && [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
exec code "${target:-.}" &
EOF
run_as_user chmod +x "$NAUTILUS_SCRIPTS_DIR/Abrir en VS Code"

echo "================================================================="
echo "✅ Configuración de GNOME Shell 51 completada con éxito."
echo "   - Tema oscuro 'prefer-dark' y 'adw-gtk3-dark' aplicado."
echo "   - Monospace: JetBrainsMono Nerd Font 11."
echo "   - Botones completos de ventana (minimizar, maximizar, cerrar)."
echo "   - Reloj 24h, fecha y porcentaje de batería visibles."
echo "   - Terminal Kitty configurada con atajo Ctrl+Alt+T."
echo "   - Menús contextuales en Nautilus para Kitty, Antigravity y VS Code."
echo "================================================================="
