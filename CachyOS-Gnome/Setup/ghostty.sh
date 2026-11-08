#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  ghostty.sh - Instalación y Configuración de Ghostty en CachyOS Workstation
#  Catppuccin Mocha + Wayland + Atajo GNOME + Menú Contextual Nautilus (Python)
# ==============================================================================

BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

if [[ $EUID -eq 0 ]]; then
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
else
    REAL_USER="${USER:-$(whoami)}"
fi
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
REAL_UID=$(id -u "$REAL_USER")

run_as_user() {
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        local dbus_bus="/run/user/${REAL_UID}/bus"
        if [[ -S "$dbus_bus" ]]; then
            sudo -u "$REAL_USER" \
                DBUS_SESSION_BUS_ADDRESS="unix:path=$dbus_bus" \
                XDG_RUNTIME_DIR="/run/user/${REAL_UID}" \
                "$@"
        else
            sudo -u "$REAL_USER" \
                XDG_RUNTIME_DIR="/run/user/${REAL_UID}" \
                "$@"
        fi
    else
        "$@"
    fi
}

GHOSTTY_CONF_DIR="$USER_HOME/.config/ghostty"
GHOSTTY_CONF_FILE="$GHOSTTY_CONF_DIR/config"
NAUTILUS_EXT_DIR="$USER_HOME/.local/share/nautilus-python/extensions"
NAUTILUS_EXT_FILE="$NAUTILUS_EXT_DIR/open-ghostty.py"
NAUTILUS_SCRIPT_DIR="$USER_HOME/.local/share/nautilus/scripts"

OPACITY="0.85"
DO_INSTALL=true
BIND_KEY=false
SET_DEFAULT_TERM=false
ACTION="run"

show_help() {
    cat << EOF
${BOLD}👻 Instalador y Configurador de Ghostty - CachyOS Workstation (GNOME Wayland)${NC}

Instala Ghostty mediante Pacman / Paru, aplica el
tema ${BOLD}Catppuccin Mocha${NC}, JetBrainsMono Nerd Font, opacidad (${OPACITY}), desenfoque Wayland,
integración en el menú contextual de Nautilus mediante ${BOLD}nautilus-python${NC} y gestión
segura del atajo de teclado global Ctrl+Alt+T en GNOME.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)       Instala Ghostty y aplica toda la configuración estética
  --no-install, --config Solo genera la configuración y extensión de Nautilus sin usar DNF5
  --opacity <0.1-1.0>    Define la opacidad del fondo (por defecto: 0.85)
  --bind-ctrl-alt-t      Asigna de forma segura el atajo global Ctrl+Alt+T en GNOME a Ghostty
  --default-terminal     Establece Ghostty como terminal por defecto en GNOME y asigna Ctrl+Alt+T
  -s, --status           Muestra el estado actual de Ghostty, configuración y Nautilus
  -h, --help             Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  👻 ${BOLD}ESTADO DE GHOSTTY TERMINAL - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if command -v ghostty &>/dev/null; then
        local g_ver
        g_ver=$(ghostty --version 2>/dev/null | head -n1 || echo "Instalado")
        echo -e "  • Binario Ghostty:           ${GREEN}Instalado (${g_ver})${NC}"
    else
        echo -e "  • Binario Ghostty:           ${RED}No instalado${NC}"
    fi

    if [[ -f "$GHOSTTY_CONF_FILE" ]]; then
        local cur_op
        cur_op=$(grep -E '^[[:space:]]*background-opacity' "$GHOSTTY_CONF_FILE" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ' || echo "N/A")
        echo -e "  • Configuración:             ${GREEN}${GHOSTTY_CONF_FILE}${NC} (opacidad: ${BOLD}${cur_op}${NC})"
    else
        echo -e "  • Configuración:             ${YELLOW}No configurada${NC}"
    fi

    if pacman -Q nautilus-python &>/dev/null; then
        echo -e "  • Paquete nautilus-python:   ${GREEN}Instalado${NC}"
    else
        echo -e "  • Paquete nautilus-python:   ${YELLOW}No instalado${NC}"
    fi

    if [[ -f "/usr/share/nautilus-python/extensions/ghostty.py" ]]; then
        echo -e "  • Menú contextual Nautilus:  ${GREEN}Extensión nativa del paquete (/usr/share/nautilus-python/extensions/ghostty.py)${NC}"
    elif [[ -f "$NAUTILUS_EXT_FILE" ]]; then
        echo -e "  • Menú contextual Nautilus:  ${GREEN}Extensión de usuario (${NAUTILUS_EXT_FILE})${NC}"
    else
        echo -e "  • Menú contextual Nautilus:  ${YELLOW}No configurado${NC}"
    fi

    local default_term
    default_term=$(run_as_user gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null | tr -d "'" || echo "N/A")
    echo -e "  • Terminal por defecto GNOME:${CYAN} ${default_term:-N/A}${NC}"

    local current_term_bind="No asignado"
    local raw_bindings
    raw_bindings=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")
    if [[ "$raw_bindings" =~ \[.*\] ]]; then
        local c_idx=0
        while [[ $c_idx -le 40 ]]; do
            local c_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${c_idx}/"
            if [[ "$raw_bindings" == *"$c_path"* ]]; then
                local b_val cmd_val
                b_val=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$c_path" binding 2>/dev/null | tr -d "'" || true)
                cmd_val=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$c_path" command 2>/dev/null | tr -d "'" || true)
                if [[ "$b_val" == "<Control><Alt>t" ]]; then
                    current_term_bind="${cmd_val} (${c_path})"
                    break
                fi
            fi
            c_idx=$((c_idx + 1))
        done
    fi
    echo -e "  • Atajo global Ctrl+Alt+T:   ${CYAN}${current_term_bind}${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

configure_gnome_shortcut() {
    local cmd="$1"
    local name="$2"

    if ! command -v gsettings &>/dev/null; then
        log_warn "gsettings no disponible; omitiendo configuración de atajo GNOME."
        return 0
    fi

    local schema="org.gnome.settings-daemon.plugins.media-keys"
    local custom_schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
    local raw_list
    raw_list=$(run_as_user gsettings get "$schema" custom-keybindings 2>/dev/null || echo "@as []")

    local target_path=""
    local custom_prefix="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom"

    # Buscar si ya existe una entrada con binding <Control><Alt>t o comando asignado
    local idx=0
    while [[ $idx -le 40 ]]; do
        local check_path="${custom_prefix}${idx}/"
        if [[ "$raw_list" == *"$check_path"* ]]; then
            local existing_bind existing_cmd
            existing_bind=$(run_as_user gsettings get "$custom_schema:$check_path" binding 2>/dev/null | tr -d "'" || true)
            existing_cmd=$(run_as_user gsettings get "$custom_schema:$check_path" command 2>/dev/null | tr -d "'" || true)
            if [[ "$existing_bind" == "<Control><Alt>t" || "$existing_cmd" == "$cmd"* ]]; then
                target_path="$check_path"
                break
            fi
        fi
        idx=$((idx + 1))
    done

    # Si no existe, buscar el primer índice custom libre para no sobrescribir atajos existentes
    if [[ -z "$target_path" ]]; then
        idx=0
        while true; do
            local candidate="${custom_prefix}${idx}/"
            if [[ "$raw_list" != *"$candidate"* ]]; then
                target_path="$candidate"
                break
            fi
            idx=$((idx + 1))
        done

        local updated_list
        if [[ "$raw_list" == "@as []" || -z "$raw_list" || "$raw_list" == "[]" ]]; then
            updated_list="['$target_path']"
        else
            updated_list="${raw_list%]*}, '$target_path']"
        fi
        run_as_user gsettings set "$schema" custom-keybindings "$updated_list" 2>/dev/null || true
    fi

    run_as_user gsettings set "$custom_schema:$target_path" name "$name" 2>/dev/null || true
    run_as_user gsettings set "$custom_schema:$target_path" command "$cmd" 2>/dev/null || true
    run_as_user gsettings set "$custom_schema:$target_path" binding '<Control><Alt>t' 2>/dev/null || true
    log_ok "Atajo global Ctrl+Alt+T asignado en GNOME ($target_path -> '$cmd')."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)           ACTION="status"; shift ;;
        --no-install|--config) DO_INSTALL=false; shift ;;
        --bind-ctrl-alt-t)     BIND_KEY=true; shift ;;
        --default-terminal)    SET_DEFAULT_TERM=true; BIND_KEY=true; shift ;;
        --opacity)             OPACITY="${2:-0.85}"; shift 2 ;;
        -h|--help)             show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
fi

if [[ "$DO_INSTALL" == true ]]; then
    PKGS_TO_INSTALL=()
    pacman -Q wl-clipboard &>/dev/null || PKGS_TO_INSTALL+=(wl-clipboard)
    pacman -Q nautilus-python &>/dev/null || PKGS_TO_INSTALL+=(nautilus-python)

    if [[ ${#PKGS_TO_INSTALL[@]} -gt 0 ]]; then
        log_info "Instalando dependencias de integración en CachyOS (Pacman): ${PKGS_TO_INSTALL[*]}..."
        sudo pacman -S --needed --noconfirm "${PKGS_TO_INSTALL[@]}"
    fi

    if ! command -v ghostty &>/dev/null && ! pacman -Q ghostty &>/dev/null; then
        log_info "Instalando Ghostty en CachyOS mediante Pacman / Paru..."
        if ! sudo pacman -S --needed --noconfirm ghostty 2>/dev/null; then
            if command -v paru &>/dev/null; then
                run_as_user paru -S --needed --noconfirm ghostty-bin 2>/dev/null || run_as_user paru -S --needed --noconfirm ghostty 2>/dev/null || true
            fi
        fi
        log_ok "Ghostty instalado exitosamente."
    else
        log_ok "Ghostty ya está instalado."
    fi
fi

log_info "Generando configuración de Ghostty (Catppuccin Mocha + Wayland) en $GHOSTTY_CONF_FILE (opacidad: $OPACITY)..."
mkdir -p "$GHOSTTY_CONF_DIR"

cat << EOF > "$GHOSTTY_CONF_FILE"
# ==============================================================================
#  Ghostty Configuration - CachyOS Workstation (GNOME Wayland)
#  Theme: Catppuccin Mocha | Font: JetBrainsMono Nerd Font
# ==============================================================================
#  Theme: Catppuccin Mocha | Font: JetBrainsMono Nerd Font
# ==============================================================================

theme = Catppuccin Mocha
font-family = JetBrainsMono Nerd Font
font-size = 11

# Apariencia y Transparencia Wayland
background-opacity = ${OPACITY}
background-blur-radius = 20
window-padding-x = 10
window-padding-y = 8
window-decoration = true
window-theme = dark
gtk-titlebar = true
gtk-tabs-location = top
gtk-wide-tabs = true
gtk-single-instance = true

# Cursor y Ratón
cursor-style = block
cursor-style-blink = false
mouse-hide-while-typing = true
copy-on-select = clipboard

# Historial y Shell Integration (Búfer de 100 MB)
scrollback-limit = 104857600
shell-integration = detect
confirm-close-surface = false

# Atajos de teclado intuitivos
keybind = ctrl+shift+c=copy_to_clipboard
keybind = ctrl+shift+v=paste_from_clipboard
keybind = ctrl+shift+t=new_tab
keybind = ctrl+shift+enter=new_window
keybind = ctrl+shift+w=close_surface
keybind = ctrl+shift+r=reload_config
keybind = ctrl+plus=increase_font_size:1
keybind = ctrl+equal=increase_font_size:1
keybind = ctrl+kp_add=increase_font_size:1
keybind = ctrl+minus=decrease_font_size:1
keybind = ctrl+kp_subtract=decrease_font_size:1
keybind = ctrl+zero=reset_font_size
EOF

# Limpiar scripts antiguos en submenú para evitar duplicados
rm -f "$NAUTILUS_SCRIPT_DIR/Abrir en Ghostty" "$NAUTILUS_SCRIPT_DIR/Open in Ghostty" 2>/dev/null || true

# Si el paquete RPM de ghostty ya instala /usr/share/nautilus-python/extensions/ghostty.py,
# evitamos duplicar la entrada en el menú contextual; de lo contrario, instalamos nuestra extensión.
if [[ -f "/usr/share/nautilus-python/extensions/ghostty.py" ]]; then
    rm -f "$NAUTILUS_EXT_FILE" 2>/dev/null || true
    log_ok "Extensión oficial de Ghostty para Nautilus detectada en /usr/share/nautilus-python/extensions/ghostty.py."
else
    log_info "Configurando extensión Nautilus Python en $NAUTILUS_EXT_FILE..."
    mkdir -p "$NAUTILUS_EXT_DIR"
    cat << 'EOF' > "$NAUTILUS_EXT_FILE"
import os
import subprocess
import shutil
from urllib.parse import unquote, urlparse
import gi

try:
    gi.require_version('Nautilus', '4.1')
except ValueError:
    try:
        gi.require_version('Nautilus', '4.0')
    except ValueError:
        pass
try:
    gi.require_version('GObject', '2.0')
except ValueError:
    pass

from gi.repository import Nautilus, GObject


class OpenGhosttyExtension(GObject.GObject, Nautilus.MenuProvider):
    def _open_ghostty(self, menu, folder_path):
        subprocess.Popen(["ghostty", f"--working-directory={folder_path}"], start_new_session=True)

    def _get_path(self, file_info):
        try:
            location = file_info.get_location()
            if location:
                path = location.get_path()
                if path and os.path.isdir(path):
                    return path
        except Exception:
            pass
        uri = file_info.get_uri()
        if uri and uri.startswith("file://"):
            return unquote(urlparse(uri).path)
        return None

    def get_file_items(self, *args):
        files = args[-1]
        if len(files) != 1 or not files[0].is_directory():
            return []
        if not shutil.which("ghostty"):
            return []
        path = self._get_path(files[0])
        if not path:
            return []
        item = Nautilus.MenuItem(
            name="GhosttyNautilus::OpenFolder",
            label="Abrir en Ghostty",
            tip=f"Abrir {path} en Ghostty",
            icon="com.mitchellh.ghostty",
        )
        item.connect("activate", self._open_ghostty, path)
        return [item]

    def get_background_items(self, *args):
        current_folder = args[-1]
        if not shutil.which("ghostty"):
            return []
        path = self._get_path(current_folder)
        if not path:
            return []
        item = Nautilus.MenuItem(
            name="GhosttyNautilus::OpenBackground",
            label="Abrir en Ghostty",
            tip=f"Abrir {path} en Ghostty",
            icon="com.mitchellh.ghostty",
        )
        item.connect("activate", self._open_ghostty, path)
        return [item]
EOF
fi

if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
    chown -R "$REAL_USER:$REAL_USER" "$GHOSTTY_CONF_DIR" "$USER_HOME/.local/share/nautilus-python" 2>/dev/null || true
fi

if [[ "$SET_DEFAULT_TERM" == true ]]; then
    log_info "Configurando Ghostty como terminal predeterminada en GNOME..."
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec 'ghostty' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec-arg '' 2>/dev/null || true
fi

if [[ "$BIND_KEY" == true ]]; then
    log_info "Configurando atajo global Ctrl+Alt+T para Ghostty en GNOME..."
    configure_gnome_shortcut "ghostty" "Terminal (Ghostty)"
fi

run_as_user nautilus -q 2>/dev/null || true
log_ok "Ghostty configurado correctamente en CachyOS Workstation."
