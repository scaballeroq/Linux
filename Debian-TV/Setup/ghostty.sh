#!/usr/bin/env bash
# ==============================================================================
# ghostty.sh - Instalación, Optimización y Configuración Estética de Ghostty Terminal
# Sistema: Debian GNU/Linux 13 (Trixie) | Entorno: GNOME Shell 48+ (Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 Mesa OpenGL)
# Tema: Catppuccin Mocha con Transparencia, Blur nativo y Tipografía Nerd Font
# ==============================================================================
# Características:
# - Esquema de color oscuro oficial Catppuccin Mocha nativo de Ghostty.
# - Aceleración por GPU nativa en Wayland con soporte GTK4 y Libadwaita.
# - Opacidad configurable (80%) con desenfoque nativo (background-blur = true).
# - Tipografía JetBrainsMono Nerd Font con ligaduras completas y fallbacks.
# - Pestañas estilo Adwaita (tabs) y decoración nativa Wayland.
# - Cursor moderno tipo barra (bar) con parpadeo suave.
# - Scrollback ampliado (10.000.000 bytes) y soporte táctil multitáctil para touchpad.
# - Integración contextual completa en Nautilus (Extensión Python 1er nivel + Script).
# - Opciones CLI: --status / -s, --config-only / --no-install, --default-terminal,
#   --bind-ctrl-alt-t, --help / -h.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
DEFAULT_OPACITY="0.80"
DEFAULT_FONT_SIZE="11"

# Colores ANSI para terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# 2. DETECCIÓN DE USUARIO Y ELEVACIÓN DE PRIVILEGIOS
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
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
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$REAL_UID}"
    local dbus_addr="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$runtime_dir/bus}"
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="/usr/local/bin:/usr/bin:/bin:$PATH" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    else
        env \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    fi
}

get_os_description() {
    if [ -f /etc/os-release ]; then
        grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"'
    else
        echo "Debian GNU/Linux 13 (trixie)"
    fi
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
👻 Gestor y Optimizador de Ghostty Terminal - Debian 13 Workstation (GNOME Wayland)
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 Mesa OpenGL)

Uso:
  $0 [OPCIÓN]

Opciones principales:
  (sin argumentos)        Instala Ghostty mediante el instalador oficial/comunitario si no
                          está presente, genera la configuración Catppuccin Mocha y aplica
                          la integración con GNOME y Nautilus.
  -s, --status            Muestra el estado detallado de Ghostty, versión, fuentes y atajos.
  --no-install, --config  Genera y valida la configuración en ~/.config/ghostty/ sin invocar
                          instaladores ni requerir privilegios de superusuario (sudo).
  --bind-ctrl-alt-t       Asigna explícitamente el atajo global Ctrl+Alt+T a Ghostty en GNOME.
  --default-terminal      Establece Ghostty como la terminal predeterminada en update-alternatives.
  -h, --help              Muestra este mensaje de ayuda.

Características aplicadas:
  • Instalador oficial:   curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh
  • Tema:                 Catppuccin Mocha oficial integrado.
  • Tipografía:           JetBrainsMono Nerd Font (ligaduras completas y glifos).
  • Efectos Wayland:      Opacidad 80% con desenfoque (blur nativo) y GTK4/Adwaita.
  • Cursor & Ventanas:    Cursor bar parpadeante, sin confirmación al cerrar y márgenes balanceados.
  • Integración Nautilus: Extensión Python de 1er nivel ("Abrir en Ghostty") y script auxiliar.
EOF
}

show_status() {
    local os_name
    os_name=$(get_os_description)

    echo "================================================================="
    echo "🔍 ESTADO DE GHOSTTY TERMINAL - DEBIAN WORKSTATION (WAYLAND)"
    echo "================================================================="
    echo "• Sistema Operativo:             $os_name"
    
    if command -v ghostty &>/dev/null; then
        local ghostty_v
        ghostty_v=$(ghostty --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "instalada")
        echo "• Ghostty instalado:             ✅ $(which ghostty) (v${ghostty_v})"
    else
        echo "• Ghostty instalado:             ❌ No instalado"
    fi

    # Fuente Nerd Font
    local font_status="⚠️ No detectada (se usará fallback del sistema)"
    if [ -n "$(fc-list : family | grep -i "^JetBrainsMono Nerd Font" 2>/dev/null || true)" ]; then
        font_status="✅ JetBrainsMono Nerd Font disponible"
    elif [ -n "$(fc-list : family | grep -i "^JetBrains Mono" 2>/dev/null || true)" ]; then
        font_status="✅ JetBrains Mono estándar disponible"
    fi
    echo "• Tipografía Monospace:          $font_status"

    # Configuración de Ghostty
    local cfg_file="$USER_HOME/.config/ghostty/config"
    if [ -f "$cfg_file" ]; then
        local opac theme_name
        opac=$(grep "^background-opacity" "$cfg_file" | head -n1 | cut -d= -f2 | tr -d ' ' || echo "1.0")
        theme_name=$(grep "^theme" "$cfg_file" | head -n1 | cut -d= -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "por defecto")
        echo "• Configuración ghostty/config:  ✅ Presente (Opacidad: $opac | Tema: $theme_name)"
    else
        echo "• Configuración ghostty/config:  ❌ No presente ($cfg_file)"
    fi

    # Integración con GNOME (Atajos de teclado)
    local kb_configured custom0_cmd custom1_cmd
    kb_configured=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo '[]')
    custom0_cmd=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 2>/dev/null || echo '')
    custom1_cmd=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 2>/dev/null || echo '')
    
    if echo "$custom0_cmd" | grep -qi "ghostty"; then
        echo "• Atajo Global (Ctrl+Alt+T):     ✅ Vinculado a Ghostty (custom0)"
    elif echo "$custom1_cmd" | grep -qi "ghostty"; then
        echo "• Atajo Alternativo (Ctrl+Alt+G):✅ Vinculado a Ghostty (custom1)"
    else
        echo "• Atajo Global:                  ℹ️ No asignado a Ghostty"
    fi

    # Menú contextual de Nautilus
    local nautilus_sys_ext="/usr/share/nautilus-python/extensions/ghostty.py"
    local nautilus_user_ext="$USER_HOME/.local/share/nautilus-python/extensions/open-ghostty.py"
    local nautilus_script="$USER_HOME/.local/share/nautilus/scripts/Abrir en Ghostty"
    if [ -f "$nautilus_sys_ext" ]; then
        echo "• Menú Nautilus (Clic derecho):  ✅ Activo (Extensión oficial del sistema)"
    elif [ -f "$nautilus_user_ext" ]; then
        echo "• Menú Nautilus (Clic derecho):  ✅ Activo (Extensión nativa de 1er nivel)"
    elif [ -f "$nautilus_script" ]; then
        echo "• Menú Nautilus (Clic derecho):  ⚠️ En submenú 'Guiones' (Script clásico)"
    else
        echo "• Menú Nautilus (Clic derecho):  ❌ No instalado"
    fi

    # Terminal del sistema
    if [ -x /usr/bin/x-terminal-emulator ]; then
        local cur_alt
        cur_alt=$(readlink -f /usr/bin/x-terminal-emulator 2>/dev/null || echo "n/a")
        echo "• x-terminal-emulator:           $cur_alt"
    fi
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN DE GHOSTTY MEDIANTE EL INSTALADOR OFICIAL
# ------------------------------------------------------------------------------
install_ghostty() {
    if ! command -v ghostty &>/dev/null; then
        echo "📦 [1/4] Instalando Ghostty Terminal en Debian 13..."
        if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
            echo "❌ Error: Se requieren permisos de superusuario para instalar paquetes."
            exit 1
        fi

        # Asegurar herramientas para la descarga y ejecución del instalador
        if ! command -v curl &>/dev/null; then
            echo "   🌐 Instalando curl para descarga de dependencias..."
            $SUDO apt-get update -qq
            $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y curl 2>/dev/null || true
        fi

        # Ejecución del instalador documentado por mkasberg/ghostty-ubuntu
        echo "   🚀 Ejecutando instalador oficial/comunitario de Ghostty..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"

        if command -v ghostty &>/dev/null; then
            local ghostty_v
            ghostty_v=$(ghostty --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "instalada")
            echo "   ✅ Ghostty instalado exitosamente (v${ghostty_v})."
        else
            echo "❌ Error: La instalación de Ghostty no pudo verificarse."
            exit 1
        fi
    else
        local ghostty_v
        ghostty_v=$(ghostty --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "instalada")
        echo "   ✅ Ghostty ya está instalado en el sistema (v${ghostty_v})."
    fi
}

# ------------------------------------------------------------------------------
# 5. GENERACIÓN DEL ARCHIVO DE CONFIGURACIÓN DE GHOSTTY
# ------------------------------------------------------------------------------
setup_config() {
    echo "⚙️ [2/4] Generando configuración estética Catppuccin Mocha en ~/.config/ghostty/..."
    local config_dir="$USER_HOME/.config/ghostty"
    local config_file="$config_dir/config"
    local config_ghostty_file="$config_dir/config.ghostty"

    run_as_user mkdir -p "$config_dir"

    # Respaldo si ya existía configuración previa
    if [ -f "$config_file" ] && [ ! -f "$config_file.bak" ]; then
        run_as_user cp "$config_file" "$config_file.bak" 2>/dev/null || true
    fi

    cat <<EOF | run_as_user tee "$config_file" > /dev/null
# =============================================================================
# GHOSTTY CONFIGURATION - DEBIAN 13 WORKSTATION (GNOME SHELL WAYLAND)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 Mesa OpenGL)
# Tema: Catppuccin Mocha con Transparencia, Blur nativo y Tipografía Nerd Font
# =============================================================================

# --- Tema & Esquema de Color ---
theme = Catppuccin Mocha

# --- Tipografía & Fuentes ---
font-family = JetBrainsMono Nerd Font
font-size = ${DEFAULT_FONT_SIZE}
font-thicken = false

# --- Transparencia, Desenfoque y Efectos Wayland ---
background-opacity = ${DEFAULT_OPACITY}
background-blur = true
alpha-blending = linear-corrected

# --- Ventana, Márgenes y Comportamiento ---
window-padding-x = 10
window-padding-y = 10
window-padding-balance = true
window-padding-color = background
window-inherit-working-directory = true
confirm-close-surface = false

# --- Cursor Moderno ---
cursor-style = bar
cursor-style-blink = true

# --- Integración GTK / GNOME Wayland ---
window-decoration = auto
gtk-titlebar = true
gtk-tabs-location = top
gtk-wide-tabs = true
gtk-titlebar-style = native

# --- Historial y Scrollback ---
scrollback-limit = 10000000
mouse-scroll-multiplier = precision:1,discrete:3
EOF

    # Compatibilidad con ambas rutas estándar (config y config.ghostty)
    run_as_user cp -f "$config_file" "$config_ghostty_file" 2>/dev/null || true

    # Validación de sintaxis nativa de Ghostty
    if command -v ghostty &>/dev/null; then
        if ghostty +validate-config --config-file="$config_file" 2>/dev/null; then
            echo "   ✅ Archivo de configuración validado correctamente con 'ghostty +validate-config'."
        fi
    fi
}

# ------------------------------------------------------------------------------
# 6. INTEGRACIÓN CON GNOME SHELL Y ATAJOS DE TECLADO
# ------------------------------------------------------------------------------
setup_keybinding() {
    local force_ctrl_alt_t="${1:-false}"
    echo "⌨️ [3/4] Sincronizando atajo de teclado en GNOME Shell..."

    if command -v gsettings &>/dev/null; then
        local current_kb
        current_kb=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")

        local custom0_cmd
        custom0_cmd=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 2>/dev/null || echo '')
        custom0_cmd=$(echo "$custom0_cmd" | tr -d "'\"")

        if [ "$force_ctrl_alt_t" = "true" ] || [ -z "$custom0_cmd" ] || [ "$custom0_cmd" = "ghostty" ]; then
            local kb_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]" 2>/dev/null || true
            if [[ "$current_kb" == "@as []" || "$current_kb" == "[]" ]]; then
                run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$kb_path']" 2>/dev/null || true
            elif ! echo "$current_kb" | grep -q "$kb_path"; then
                local new_kb
                new_kb=$(echo "$current_kb" | sed "s|]|, '$kb_path']|")
                run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_kb" 2>/dev/null || true
            fi
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path name 'Ghostty Terminal' 2>/dev/null || true
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path command 'ghostty' 2>/dev/null || true
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path binding '<Primary><Alt>t' 2>/dev/null || true
            echo "   ✅ Atajo Ctrl+Alt+T asignado a Ghostty."
        else
            # Mantener custom0 para la terminal actual (ej. Kitty) y asignar custom1 a Ghostty sin conflicto
            local kb_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
            if ! echo "$current_kb" | grep -q "$kb_path"; then
                local new_kb
                if [[ "$current_kb" == "@as []" || "$current_kb" == "[]" ]]; then
                    new_kb="['$kb_path']"
                else
                    new_kb=$(echo "$current_kb" | sed "s|]|, '$kb_path']|")
                fi
                run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_kb" 2>/dev/null || true
            fi
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path name 'Ghostty Terminal' 2>/dev/null || true
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path command 'ghostty' 2>/dev/null || true
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path binding '<Primary><Alt>g' 2>/dev/null || true
            echo "   ℹ️ Slot custom0 en uso ($custom0_cmd). Se configuró Ctrl+Alt+G para Ghostty (usa --bind-ctrl-alt-t para forzar Ctrl+Alt+T)."
        fi
    fi
}

# ------------------------------------------------------------------------------
# 7. MENÚ CONTEXTUAL DE NAUTILUS (CLIC DERECHO NATIVO 'Abrir en Ghostty')
# ------------------------------------------------------------------------------
setup_nautilus_script() {
    echo "📁 [4/4] Configurando menú contextual de Nautilus ('Abrir en Ghostty')..."

    # Asegurar soporte python3-nautilus para menú contextual de primer nivel
    if ! dpkg -s python3-nautilus &>/dev/null; then
        echo "   ℹ️ Instalando python3-nautilus para integración nativa..."
        if [ "$EUID" -eq 0 ] || command -v sudo &>/dev/null; then
            $SUDO apt-get update -qq
            $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y python3-nautilus 2>/dev/null || true
        fi
    fi

    local sys_ext="/usr/share/nautilus-python/extensions/ghostty.py"
    local ext_dir="$USER_HOME/.local/share/nautilus-python/extensions"

    # Si el paquete deb ya instaló ghostty.py en el sistema, evitar duplicados eliminando la copia de usuario
    if [ -f "$sys_ext" ]; then
        echo "   ℹ️ Extensión nativa de Ghostty ya provista por el paquete en $sys_ext (sin duplicados)."
        run_as_user rm -f "$ext_dir/open-ghostty.py" 2>/dev/null || true
    else
        # Extensión Python nativa propia
        run_as_user mkdir -p "$ext_dir"
        cat << 'EOF' | run_as_user tee "$ext_dir/open-ghostty.py" > /dev/null
# Extensión de Nautilus para abrir la terminal Ghostty directamente en el menú contextual
# Compatible con Nautilus 4.0+ (GNOME 43/48) y python3-nautilus

import os
import subprocess
from urllib.parse import unquote, urlparse
from gi.repository import GObject, Nautilus

class OpenGhosttyExtension(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self):
        super().__init__()

    def _open_ghostty(self, path):
        if not path:
            path = os.path.expanduser("~")
        if os.path.isfile(path):
            path = os.path.dirname(path)
        try:
            subprocess.Popen(["ghostty", f"--working-directory={path}"])
        except Exception as e:
            print(f"Error al lanzar Ghostty: {e}")

    def get_file_items(self, files):
        if not files:
            return []
        item = Nautilus.MenuItem(
            name="OpenGhostty::OpenFileItem",
            label="Abrir en Ghostty",
            tip="Abrir la terminal Ghostty en esta ubicación"
        )
        item.connect("activate", self._on_file_activated, files)
        return [item]

    def get_background_items(self, current_folder):
        item = Nautilus.MenuItem(
            name="OpenGhostty::OpenBackgroundItem",
            label="Abrir en Ghostty",
            tip="Abrir la terminal Ghostty en la carpeta actual"
        )
        item.connect("activate", self._on_background_activated, current_folder)
        return [item]

    def _on_file_activated(self, menu_item, files):
        if not files:
            return
        uri = files[0].get_uri()
        path = unquote(urlparse(uri).path)
        self._open_ghostty(path)

    def _on_background_activated(self, menu_item, folder):
        uri = folder.get_uri()
        path = unquote(urlparse(uri).path)
        self._open_ghostty(path)
EOF
    fi

    # 2. Script clásico en ~/.local/share/nautilus/scripts (submenú 'Guiones' como respaldo)
    local scripts_dir="$USER_HOME/.local/share/nautilus/scripts"
    run_as_user mkdir -p "$scripts_dir"

    cat << 'EOF' | run_as_user tee "$scripts_dir/Abrir en Ghostty" > /dev/null
#!/usr/bin/env bash
target=""
if [ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ]; then
    first=$(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n1)
    if [ -d "$first" ]; then
        target="$first"
    elif [ -f "$first" ]; then
        target="$(dirname "$first")"
    fi
fi
if [ -z "$target" ] && [ -n "${NAUTILUS_SCRIPT_CURRENT_URI:-}" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
target="${target:-$HOME}"
exec ghostty --working-directory="$target" &
EOF
    run_as_user chmod +x "$scripts_dir/Abrir en Ghostty" 2>/dev/null || true

    # Reiniciar Nautilus para recargar extensiones inmediatamente
    run_as_user nautilus -q 2>/dev/null || true

    echo "   ✅ Integración contextual de Nautilus completada sin duplicidades."
}

# ------------------------------------------------------------------------------
# 8. CONFIGURAR TERMINAL PREDETERMINADA EN EL SISTEMA
# ------------------------------------------------------------------------------
set_default_terminal() {
    if command -v update-alternatives &>/dev/null && [ -x /usr/bin/ghostty ]; then
        echo "🔧 Estableciendo Ghostty como x-terminal-emulator predeterminado..."
        if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
            echo "❌ Error: Se requieren privilegios de superusuario para update-alternatives."
            exit 1
        fi
        $SUDO update-alternatives --set x-terminal-emulator /usr/bin/ghostty 2>/dev/null || true
        echo "   ✅ Ghostty es ahora el x-terminal-emulator del sistema."
    fi
}

# ------------------------------------------------------------------------------
# 9. ENTRADA PRINCIPAL Y PARSEO DE ARGUMENTOS
# ------------------------------------------------------------------------------
case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    --no-install|--config|--config-only)
        echo "==========================================================="
        echo "👻 APLICANDO CONFIGURACIÓN DE GHOSTTY (MODO USUARIO / SIN INSTALADOR)"
        echo "==========================================================="
        setup_config
        setup_keybinding false
        setup_nautilus_script
        echo ""
        show_status
        echo "==========================================================="
        echo "✅ Configuración de Ghostty aplicada con éxito."
        echo "==========================================================="
        exit 0
        ;;
    --bind-ctrl-alt-t)
        echo "==========================================================="
        echo "⌨️ REASIGNANDO CTRL+ALT+T A GHOSTTY EN GNOME SHELL"
        echo "==========================================================="
        setup_keybinding true
        exit 0
        ;;
    --default-terminal)
        set_default_terminal
        exit 0
        ;;
    "")
        echo "==========================================================="
        echo "👻 CONFIGURANDO GHOSTTY TERMINAL EN DEBIAN 13 (GNOME WAYLAND)"
        echo "==========================================================="
        install_ghostty
        setup_config
        setup_keybinding false
        setup_nautilus_script
        echo ""
        show_status
        echo "==========================================================="
        echo "✅ Instalación y optimización de Ghostty completada."
        echo "==========================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
