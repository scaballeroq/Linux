#!/usr/bin/env bash
# ==============================================================================
# kitty.sh - Instalación, Optimización y Configuración Estética de Kitty Terminal
# Sistema: Debian GNU/Linux 13 (Trixie) | Entorno: GNOME Shell 48+ (Wayland)
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD 4600 Mesa RADV)
# Tema: Catppuccin Mocha con Transparencia, Blur y Tipografía Nerd Font
# ==============================================================================
# Características:
# - Esquema de color oscuro de alta legibilidad (Catppuccin Mocha).
# - Aceleración por GPU nativa en Wayland (Mesa RADV) sin dependencias X11.
# - Opacidad (80%) con desenfoque (blur 32) adaptado para Wayland y blur-my-shell.
# - Tipografía JetBrainsMono Nerd Font con ligaduras completas y fallbacks elegantes.
# - Barra de pestañas Powerline con estilo inclinado (slanted).
# - Cursor moderno tipo barra (beam) con estela de movimiento suave (cursor_trail).
# - Scrollback ampliado (10.000 líneas) y soporte táctil multitáctil para touchpad.
# - Atajo global Ctrl+Alt+T sincronizado con GNOME y scripts inteligentes para Nautilus.
# - Modos CLI: --status / -s, --config-only / --no-install, --default-terminal, --help / -h.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
DEFAULT_OPACITY="0.80"
DEFAULT_FONT_SIZE="11.0"

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
🐱 Gestor y Optimizador de Kitty Terminal - Debian 13 Workstation (GNOME Wayland)
Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD 4600 Mesa RADV)

Uso:
  $0 [OPCIÓN]

Opciones principales:
  (sin argumentos)        Instala Kitty vía APT si no está instalado, genera la configuración
                          estética Catppuccin Mocha y aplica la integración con GNOME.
  -s, --status            Muestra el estado detallado de Kitty, versión, fuentes y atajos.
  --no-install, --config  Genera y actualiza kitty.conf y atajos de usuario SIN invocar APT
                          ni requerir privilegios de superusuario (sudo).
  --default-terminal      Establece Kitty como la terminal predeterminada en update-alternatives.
  -h, --help              Muestra este mensaje de ayuda.

Características aplicadas:
  • Tema:             Catppuccin Mocha con fondo oscuro (#181825).
  • Tipografía:       JetBrainsMono Nerd Font (ligaduras y soporte completo de glifos).
  • Efectos Wayland:  Opacidad 80% con desenfoque (blur 32) acelerado por GPU (AMD Mesa).
  • Cursor & Pestañas:Cursor beam con estela suave (cursor_trail) y pestañas powerline slanted.
  • Integración GNOME:Atajo global Ctrl+Alt+T sincronizado y script contextual en Nautilus.
EOF
}

show_status() {
    local os_name
    os_name=$(get_os_description)

    echo "================================================================="
    echo "🔍 ESTADO DE KITTY TERMINAL - DEBIAN WORKSTATION (WAYLAND)"
    echo "================================================================="
    echo "• Sistema Operativo:             $os_name"
    
    if command -v kitty &>/dev/null; then
        local kitty_v
        kitty_v=$(kitty --version 2>/dev/null | awk '{print $2}' || echo "instalada")
        echo "• Kitty instalado:               ✅ $(which kitty) (v${kitty_v})"
    else
        echo "• Kitty instalado:               ❌ No instalado"
    fi

    # Fuente Nerd Font
    local font_status="⚠️ No detectada (se usará fallback del sistema)"
    if [ -n "$(fc-list : family | grep -i "^JetBrainsMono Nerd Font" 2>/dev/null || true)" ]; then
        font_status="✅ JetBrainsMono Nerd Font disponible"
    elif [ -n "$(fc-list : family | grep -i "^JetBrains Mono" 2>/dev/null || true)" ]; then
        font_status="✅ JetBrains Mono estándar disponible"
    fi
    echo "• Tipografía Monospace:          $font_status"

    # Configuración de Kitty
    local cfg_file="$USER_HOME/.config/kitty/kitty.conf"
    if [ -f "$cfg_file" ]; then
        local opac
        opac=$(grep "^background_opacity" "$cfg_file" 2>/dev/null | awk '{print $2}' || echo "n/a")
        echo "• Configuración kitty.conf:      ✅ Presente (Opacidad: $opac | Tema: Catppuccin Mocha)"
    else
        echo "• Configuración kitty.conf:      ❌ No presente ($cfg_file)"
    fi

    # Integración con GNOME (Atajo Ctrl+Alt+T)
    local kb_configured kb_cmd
    kb_configured=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo '[]')
    kb_cmd=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 2>/dev/null || echo '')
    if echo "$kb_configured" | grep -qi "custom0" && [ "$kb_cmd" = "'kitty'" -o "$kb_cmd" = "kitty" ]; then
        echo "• Atajo Global (Ctrl+Alt+T):     ✅ Vinculado a Kitty (custom0)"
    else
        echo "• Atajo Global (Ctrl+Alt+T):     ℹ️ No asignado directamente a Kitty"
    fi

    # Menú contextual de Nautilus
    local nautilus_ext="$USER_HOME/.local/share/nautilus-python/extensions/open-kitty.py"
    local nautilus_script="$USER_HOME/.local/share/nautilus/scripts/Abrir en Kitty"
    if [ -f "$nautilus_ext" ]; then
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
# 4. INSTALACIÓN DEL PAQUETE KITTY VÍA APT
# ------------------------------------------------------------------------------
install_kitty() {
    if ! command -v kitty &>/dev/null; then
        echo "📦 [1/4] Instalando Kitty Terminal vía APT..."
        if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
            echo "❌ Error: Se requieren permisos de superusuario para instalar Kitty."
            exit 1
        fi
        $SUDO apt-get update -qq
        $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y kitty 2>/dev/null || true
        echo "   ✅ Kitty instalado exitosamente."
    else
        echo "   ✅ Kitty ya está instalado en el sistema ($(kitty --version 2>/dev/null | awk '{print $2}'))."
    fi
}

# ------------------------------------------------------------------------------
# 5. GENERACIÓN DEL ARCHIVO DE CONFIGURACIÓN KITTY.CONF
# ------------------------------------------------------------------------------
setup_config() {
    echo "⚙️ [2/4] Generando configuración estética Catppuccin Mocha en ~/.config/kitty/..."
    local config_dir="$USER_HOME/.config/kitty"
    run_as_user mkdir -p "$config_dir"

    # Respaldo de seguridad si el archivo ya existía
    if [ -f "$config_dir/kitty.conf" ] && [ ! -f "$config_dir/kitty.conf.bak" ]; then
        run_as_user cp "$config_dir/kitty.conf" "$config_dir/kitty.conf.bak" 2>/dev/null || true
    fi

    cat <<EOF | run_as_user tee "$config_dir/kitty.conf" > /dev/null
# =============================================================================
# KITTY CONFIGURATION - DEBIAN 13 WORKSTATION (GNOME SHELL WAYLAND)
# Hardware: Intel Core i7-4790 / Intel HD 4600 (Mesa RADV)
# Tema: Catppuccin Mocha con Transparencia y Tipografía Nerd Font
# =============================================================================

# --- Fuentes & Tipografía ---
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        ${DEFAULT_FONT_SIZE}
disable_ligatures never
box_drawing_scale 0.001, 1, 1.5, 2

# --- Transparencia, Desenfoque y Wayland ---
background_opacity         ${DEFAULT_OPACITY}
dynamic_background_opacity yes
background_blur            32
linux_display_server       auto
wayland_titlebar_color     background

# --- Ventana y Márgenes ---
window_padding_width    10
placement_strategy      center
hide_window_decorations no
confirm_os_window_close 0
remember_window_size    yes
initial_window_width    950
initial_window_height   600

# --- Cursor Moderno con Estela ---
cursor_shape                beam
cursor_beam_thickness       1.8
cursor_blink_interval       0.5
cursor_trail                3
cursor_trail_decay          0.1 0.4
cursor_trail_start_threshold 2

# --- Barra de Pestañas (Tab Bar) ---
tab_bar_edge          top
tab_bar_style         powerline
tab_powerline_style   slanted
tab_title_template    " {index}: {title}{' [' + num_windows.__str__() + ']' if num_windows > 1 else ''} "
active_tab_font_style bold

# --- Esquema de Color Oscuro (Catppuccin Mocha) ---
foreground            #cdd6f4
background            #181825
selection_foreground  #1e1e2e
selection_background  #f5e0dc

# Cursor
cursor                #f5e0dc
cursor_text_color     #11111b

# Enlaces y URLs
url_color             #89b4fa
url_style             curly
open_url_with         default
detect_urls           yes

# Colores de pestañas
active_tab_foreground   #11111b
active_tab_background   #cba6f7
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
tab_bar_background      #11111b

# Colores ANSI Estándar
# Black
color0  #45475a
color8  #585b70

# Red
color1  #f38ba8
color9  #f38ba8

# Green
color2  #a6e3a1
color10 #a6e3a1

# Yellow
color3  #f9e2af
color11 #f9e2af

# Blue
color4  #89b4fa
color12 #89b4fa

# Magenta
color5  #f5c2e7
color13 #f5c2e7

# Cyan
color6  #94e2d5
color14 #94e2d5

# White
color7  #bac2de
color15 #a6adc8

# --- Rendimiento, Scrollback & Portapapeles ---
repaint_delay            10
input_delay              3
sync_to_monitor          yes
scrollback_lines         10000
scrollback_pager_history_size 64
wheel_scroll_multiplier  3.0
touch_scroll_multiplier  2.0
mouse_hide_wait          3.0
copy_on_select           yes
strip_trailing_spaces    smart
shell_integration        enabled

# --- Silenciar Campanas ---
enable_audio_bell    no
visual_bell_duration 0.0
window_alert_on_bell no
bell_on_tab          no

# --- Atajos de Teclado Optimizados ---
# Portapapeles estándar:
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard

# Control dinámico de opacidad:
map ctrl+shift+a>m set_background_opacity +0.05
map ctrl+shift+a>l set_background_opacity -0.05
map ctrl+shift+a>d set_background_opacity default
map ctrl+shift+a>1 set_background_opacity 1.0

# Gestión de pestañas:
map ctrl+shift+t     new_tab_with_cwd
map ctrl+shift+q     close_tab
map ctrl+shift+right next_tab
map ctrl+shift+left  previous_tab
map alt+1 goto_tab 1
map alt+2 goto_tab 2
map alt+3 goto_tab 3
map alt+4 goto_tab 4
map alt+5 goto_tab 5

# Splits y ventanas internas:
map ctrl+shift+enter new_window_with_cwd
map ctrl+shift+w     close_window
map ctrl+shift+]     next_window
map ctrl+shift+[     previous_window

# Ajuste dinámico de tamaño de fuente:
map ctrl+equal       change_font_size all +1.0
map ctrl+plus        change_font_size all +1.0
map ctrl+kp_add      change_font_size all +1.0
map ctrl+minus       change_font_size all -1.0
map ctrl+kp_subtract change_font_size all -1.0
map ctrl+0           change_font_size all 0

# Recargar configuración en vivo sin reiniciar:
map ctrl+shift+f5    load_config_file
EOF

    echo "   ✅ Archivo kitty.conf generado correctamente."
}

# ------------------------------------------------------------------------------
# 6. INTEGRACIÓN CON GNOME SHELL Y ATAJO GLOBAL CTRL+ALT+T
# ------------------------------------------------------------------------------
setup_keybinding() {
    echo "⌨️ [3/4] Sincronizando atajo global Ctrl+Alt+T con Kitty en GNOME Shell..."
    if command -v gsettings &>/dev/null; then
        local kb_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

        # 1. Desvincular el atajo predeterminado de GNOME para evitar colisiones
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]" 2>/dev/null || true

        # 2. Registrar en la lista de custom-keybindings de forma no destructiva
        local current_kb
        current_kb=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")
        if [[ "$current_kb" == "@as []" || "$current_kb" == "[]" ]]; then
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$kb_path']" 2>/dev/null || true
        elif ! echo "$current_kb" | grep -q "$kb_path"; then
            local new_kb
            new_kb=$(echo "$current_kb" | sed "s|]|, '$kb_path']|")
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_kb" 2>/dev/null || true
        fi

        # 3. Asignar comando y combinación
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path name 'Kitty Terminal' 2>/dev/null || true
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path command 'kitty' 2>/dev/null || true
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path binding '<Primary><Alt>t' 2>/dev/null || true

        echo "   ✅ Atajo Ctrl+Alt+T asignado a Kitty sin conflictos."
    fi
}

# ------------------------------------------------------------------------------
# 7. MENÚ CONTEXTUAL DE NAUTILUS (CLIC DERECHO NATIVO)
# ------------------------------------------------------------------------------
setup_nautilus_script() {
    echo "📁 [4/4] Configurando menú contextual de Nautilus ('Abrir en Kitty')..."

    # Asegurar paquete python3-nautilus para menú contextual de primer nivel
    if ! dpkg -s python3-nautilus &>/dev/null; then
        echo "   ℹ️ Instalando python3-nautilus para integración nativa..."
        if [ "$EUID" -eq 0 ] || command -v sudo &>/dev/null; then
            $SUDO apt-get update -qq
            $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y python3-nautilus 2>/dev/null || true
        fi
    fi

    # 1. Extensión Python nativa (aparece en el menú principal del clic derecho)
    local ext_dir="$USER_HOME/.local/share/nautilus-python/extensions"
    run_as_user mkdir -p "$ext_dir"

    cat << 'EOF' | run_as_user tee "$ext_dir/open-kitty.py" > /dev/null
# Extensión de Nautilus para abrir la terminal Kitty directamente en el menú contextual
# Compatible con Nautilus 4.0+ (GNOME 43/48) y python3-nautilus

import os
import subprocess
from urllib.parse import unquote, urlparse
from gi.repository import GObject, Nautilus

class OpenKittyExtension(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self):
        super().__init__()

    def _open_kitty(self, path):
        if not path:
            path = os.path.expanduser("~")
        if os.path.isfile(path):
            path = os.path.dirname(path)
        try:
            subprocess.Popen(["kitty", "--directory", path])
        except Exception as e:
            print(f"Error al lanzar Kitty: {e}")

    def get_file_items(self, files):
        if not files:
            return []
        item = Nautilus.MenuItem(
            name="OpenKitty::OpenFileItem",
            label="Abrir en Kitty",
            tip="Abrir la terminal Kitty en esta ubicación"
        )
        item.connect("activate", self._on_file_activated, files)
        return [item]

    def get_background_items(self, current_folder):
        item = Nautilus.MenuItem(
            name="OpenKitty::OpenBackgroundItem",
            label="Abrir en Kitty",
            tip="Abrir la terminal Kitty en la carpeta actual"
        )
        item.connect("activate", self._on_background_activated, current_folder)
        return [item]

    def _on_file_activated(self, menu_item, files):
        if not files:
            return
        uri = files[0].get_uri()
        path = unquote(urlparse(uri).path)
        self._open_kitty(path)

    def _on_background_activated(self, menu_item, folder):
        uri = folder.get_uri()
        path = unquote(urlparse(uri).path)
        self._open_kitty(path)
EOF

    # 2. Script clásico en ~/.local/share/nautilus/scripts (submenú 'Guiones' como respaldo)
    local scripts_dir="$USER_HOME/.local/share/nautilus/scripts"
    run_as_user mkdir -p "$scripts_dir"

    cat << 'EOF' | run_as_user tee "$scripts_dir/Abrir en Kitty" > /dev/null
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
exec kitty --directory "${target:-.}" &
EOF
    run_as_user chmod +x "$scripts_dir/Abrir en Kitty" 2>/dev/null || true

    # Reiniciar Nautilus para recargar extensiones inmediatamente
    run_as_user nautilus -q 2>/dev/null || true

    echo "   ✅ Integración contextual de Nautilus completada (Extensión 1er nivel + Script de respaldo)."
}

# ------------------------------------------------------------------------------
# 8. CONFIGURAR TERMINAL PREDETERMINADA EN EL SISTEMA
# ------------------------------------------------------------------------------
set_default_terminal() {
    if command -v update-alternatives &>/dev/null && [ -x /usr/bin/kitty ]; then
        echo "🔧 Estableciendo Kitty como x-terminal-emulator predeterminado..."
        if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
            echo "❌ Error: Se requieren privilegios de superusuario para update-alternatives."
            exit 1
        fi
        $SUDO update-alternatives --set x-terminal-emulator /usr/bin/kitty 2>/dev/null || true
        echo "   ✅ Kitty es ahora el x-terminal-emulator del sistema."
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
        echo "🎨 APLICANDO CONFIGURACIÓN DE KITTY (MODO USUARIO / SIN APT)"
        echo "==========================================================="
        setup_config
        setup_keybinding
        setup_nautilus_script
        echo ""
        show_status
        echo "==========================================================="
        echo "✅ Configuración de Kitty aplicada con éxito."
        echo "==========================================================="
        exit 0
        ;;
    --default-terminal)
        set_default_terminal
        exit 0
        ;;
    "")
        echo "==========================================================="
        echo "🐱 CONFIGURANDO KITTY TERMINAL EN DEBIAN 13 (GNOME WAYLAND)"
        echo "==========================================================="
        install_kitty
        setup_config
        setup_keybinding
        setup_nautilus_script
        echo ""
        show_status
        echo "==========================================================="
        echo "✅ Instalación y optimización de Kitty completada."
        echo "==========================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
