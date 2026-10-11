#!/bin/bash
# ==============================================================================
# gnome-settings.sh - Configuración y Personalización Avanzada de GNOME para Fedora 44
# Optimizado para desarrollo de software, modo oscuro y estación de trabajo
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🎨 CONFIGURANDO ENTORNO GNOME EN FEDORA 44 WORKSTATION (MODO OSCURO)"
echo "================================================================="

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

# 1. Herramientas esenciales de personalización de GNOME
echo "📦 [1/6] Verificando herramientas de personalización en Fedora 44..."
$SUDO dnf5 install -y \
    gnome-tweaks \
    adw-gtk3-theme \
    gnome-browser-connector 2>/dev/null || true

# 2. Apariencia y Tema Oscuro Global
echo "🌙 [2/6] Aplicando tema oscuro persistente y tipografía para desarrollo..."
run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || \
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true

# Tipografía para desarrollo (Nerd Fonts para terminal y código)
run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11' 2>/dev/null || true

# 3. Ventanas, Comportamiento y Renderizado (Mutter)
echo "🪟 [3/6] Configurando gestión de ventanas y Mutter (VRR y escalado)..."
# Botones de ventana completos: minimizar, maximizar, cerrar a la derecha
run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' 2>/dev/null || true

# Centrar nuevas ventanas automáticamente
run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
run_as_user gsettings set org.gnome.mutter attach-modal-dialogs true 2>/dev/null || true

# Características experimentales de Mutter para multi-pantalla y monitores con refresco variable (VRR)
run_as_user gsettings set org.gnome.mutter experimental-features "['variable-refresh-rate', 'scale-monitor-framebuffer']" 2>/dev/null || true

# 4. Barra Superior, Reloj, Energía y Luz Nocturna
echo "⏱️ [4/6] Configurando barra superior, reloj 24h y salud visual..."
run_as_user gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true

# Luz Nocturna a 4000K para reducir fatiga visual
run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000 2>/dev/null || true

# Energía: Portátil de desarrollo no suspende conectado a la red eléctrica
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true

# 5. Gestor de Archivos Nautilus
echo "📂 [5/6] Optimizando Nautilus para productividad y desarrollo..."
run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
run_as_user gsettings set org.gnome.nautilus.preferences show-delete-permanent true 2>/dev/null || true

# 6. Terminal Kitty e Integración con Atajos
echo "🐱 [6/6] Estableciendo Kitty como terminal predeterminada y configurando atajos..."
run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec-arg "" 2>/dev/null || true

# Atajo global Ctrl+Alt+T para Kitty en GNOME
KB_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$KB_PATH']" 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH name 'Kitty Terminal' 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH command 'kitty' 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH binding '<Primary><Alt>t' 2>/dev/null || true

# Script nativo de Nautilus para abrir Kitty con clic derecho
NAUTILUS_SCRIPTS_DIR="$USER_HOME/.local/share/nautilus/scripts"
run_as_user mkdir -p "$NAUTILUS_SCRIPTS_DIR"

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
run_as_user chmod +x "$NAUTILUS_SCRIPTS_DIR/Abrir en Kitty" 2>/dev/null || true

echo "================================================================="
echo "✅ Configuración de GNOME completada con éxito en Fedora 44."
echo "   - Tema oscuro 'prefer-dark' y 'adw-gtk3-dark' aplicado."
echo "   - Monospace: JetBrainsMono Nerd Font 11."
echo "   - Botones completos (minimizar, maximizar, cerrar)."
echo "   - Reloj 24h, fecha y porcentaje de batería visibles."
echo "   - Terminal Kitty configurada con atajo Ctrl+Alt+T."
echo "   - Script contextual en Nautilus para abrir Kitty."
echo "================================================================="
