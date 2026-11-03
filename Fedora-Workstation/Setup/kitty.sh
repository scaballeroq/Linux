#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  kitty.sh - Instalación y Optimización de Kitty en Fedora 45 Workstation
#  Catppuccin Mocha + Opacidad/Blur Wayland + Extensión Nautilus Python
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

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
        sudo -u "$REAL_USER" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${REAL_UID}/bus" \
            XDG_RUNTIME_DIR="/run/user/${REAL_UID}" \
            "$@"
    else
        "$@"
    fi
}

DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"

KITTY_CONF_DIR="$USER_HOME/.config/kitty"
KITTY_CONF_FILE="$KITTY_CONF_DIR/kitty.conf"
NAUTILUS_EXT_DIR="$USER_HOME/.local/share/nautilus-python/extensions"
NAUTILUS_EXT_FILE="$NAUTILUS_EXT_DIR/open-kitty.py"
NAUTILUS_SCRIPT_DIR="$USER_HOME/.local/share/nautilus/scripts"

OPACITY="0.75"
DO_INSTALL=true
SET_DEFAULT_TERM=true
ACTION="run"

show_help() {
    cat << EOF
${BOLD}🐱 Instalador y Optimizador de Kitty - Fedora 45 Workstation (GNOME Wayland)${NC}

Instala Kitty y ${BOLD}nautilus-python${NC} mediante DNF5, aplica el tema ${BOLD}Catppuccin Mocha${NC},
opacidad (${OPACITY}), desenfoque Wayland, atajo global Ctrl+Alt+T e integración en el menú
contextual de primer nivel de Nautilus.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)       Instala Kitty y aplica toda la configuración
  --no-install, --config Solo genera la configuración y extensión sin usar DNF5
  --opacity <0.1-1.0>    Define la opacidad del fondo (por defecto: 0.75)
  --default-terminal     Establece Kitty como terminal por defecto y asigna Ctrl+Alt+T
  -s, --status           Muestra el estado actual de Kitty, configuración y Nautilus
  -h, --help             Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🐱 ${BOLD}ESTADO DE KITTY TERMINAL - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if command -v kitty &>/dev/null; then
        echo -e "  • Binario Kitty:             ${GREEN}Instalado ($(kitty --version))${NC}"
    else
        echo -e "  • Binario Kitty:             ${RED}No instalado${NC}"
    fi

    if [[ -f "$KITTY_CONF_FILE" ]]; then
        local cur_op
        cur_op=$(grep -E '^background_opacity' "$KITTY_CONF_FILE" 2>/dev/null | awk '{print $2}' || echo "N/A")
        echo -e "  • Configuración:             ${GREEN}${KITTY_CONF_FILE}${NC} (opacidad: ${BOLD}${cur_op}${NC})"
    else
        echo -e "  • Configuración:             ${YELLOW}No configurada${NC}"
    fi

    if rpm -q nautilus-python &>/dev/null; then
        echo -e "  • Paquete nautilus-python:   ${GREEN}Instalado${NC}"
    else
        echo -e "  • Paquete nautilus-python:   ${YELLOW}No instalado${NC}"
    fi

    if [[ -f "$NAUTILUS_EXT_FILE" ]]; then
        echo -e "  • Menú contextual Nautilus:  ${GREEN}Activo (${NAUTILUS_EXT_FILE})${NC}"
    else
        echo -e "  • Menú contextual Nautilus:  ${YELLOW}No configurado${NC}"
    fi

    local default_term
    default_term=$(run_as_user gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null || echo "N/A")
    echo -e "  • Terminal por defecto GNOME:${CYAN} ${default_term}${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)           ACTION="status"; shift ;;
        --no-install|--config) DO_INSTALL=false; shift ;;
        --default-terminal)    SET_DEFAULT_TERM=true; shift ;;
        --opacity)             OPACITY="${2:-0.75}"; shift 2 ;;
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
    rpm -q kitty &>/dev/null || PKGS_TO_INSTALL+=(kitty)
    rpm -q wl-clipboard &>/dev/null || PKGS_TO_INSTALL+=(wl-clipboard)
    rpm -q nautilus-python &>/dev/null || PKGS_TO_INSTALL+=(nautilus-python)

    if [[ ${#PKGS_TO_INSTALL[@]} -gt 0 ]]; then
        log_info "Instalando paquetes en Fedora 45 ($DNF_BIN): ${PKGS_TO_INSTALL[*]}..."
        sudo "$DNF_BIN" install -y "${PKGS_TO_INSTALL[@]}"
    else
        log_ok "Kitty, wl-clipboard y nautilus-python ya están instalados."
    fi
fi

log_info "Generando configuración de Kitty en $KITTY_CONF_FILE (opacidad: $OPACITY)..."
mkdir -p "$KITTY_CONF_DIR"

cat << EOF > "$KITTY_CONF_FILE"
# ==============================================================================
#  Kitty Terminal Configuration - Fedora 45 Workstation (GNOME Wayland)
#  Theme: Catppuccin Mocha | Font: JetBrainsMono Nerd Font
# ==============================================================================

# Tipografía
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        11.0
disable_ligatures never

# Transparencia y Desenfoque en Wayland
background_opacity ${OPACITY}
background_blur    32
dynamic_background_opacity yes

# Ventana y Diseño (GNOME Wayland)
linux_display_server wayland
wayland_titlebar_color background
window_padding_width 8 10
hide_window_decorations no
remember_window_size  yes
initial_window_width  110c
initial_window_height 32c
confirm_os_window_close 0
enable_audio_bell no

# Cursor y Rendimiento (AMD Radeon RADV)
cursor_shape block
cursor_blink_interval 0
repaint_delay 8
input_delay 2
sync_to_monitor yes
scrollback_lines 15000
copy_on_select clipboard

# Barra de Pestañas (Powerline)
tab_bar_edge top
tab_bar_style powerline
tab_powerline_style slanted

# Atajos de Teclado
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+shift+t new_tab_with_cwd
map ctrl+shift+enter new_window_with_cwd
map ctrl+plus change_font_size all +1.0
map ctrl+minus change_font_size all -1.0
map ctrl+0 change_font_size all 0

# Paleta Catppuccin Mocha
foreground              #CDD6F4
background              #1E1E2E
selection_foreground    #1E1E2E
selection_background    #F5E0DC
cursor                  #F5E0DC
cursor_text_color       #1E1E2E
url_color               #F5E0DC
active_border_color     #B4BEFE
inactive_border_color   #6C7086
bell_border_color       #F9E2AF
active_tab_foreground   #11111B
active_tab_background   #CBA6F7
inactive_tab_foreground #CDD6F4
inactive_tab_background #181825
tab_bar_background      #11111B

color0  #45475A
color8  #585B70
color1  #F38BA8
color9  #F38BA8
color2  #A6E3A1
color10 #A6E3A1
color3  #F9E2AF
color11 #F9E2AF
color4  #89B4FA
color12 #89B4FA
color5  #F5C2E7
color13 #F5C2E7
color6  #94E2D5
color14 #94E2D5
color7  #BAC2DE
color15 #A6ADC8
EOF

# Limpiar scripts antiguos de Nautilus en submenú para evitar duplicados
rm -f "$NAUTILUS_SCRIPT_DIR/Abrir en Kitty" "$NAUTILUS_SCRIPT_DIR/Open in Kitty" 2>/dev/null || true

log_info "Instalando extensión de menú contextual para Nautilus en $NAUTILUS_EXT_FILE..."
mkdir -p "$NAUTILUS_EXT_DIR"

cat << 'EOF' > "$NAUTILUS_EXT_FILE"
import os
import subprocess
import shutil
from urllib.parse import unquote, urlparse
from gi.repository import Nautilus, GObject


class OpenKittyExtension(GObject.GObject, Nautilus.MenuProvider):
    def _open_kitty(self, menu, folder_path):
        subprocess.Popen(["kitty", "--directory", folder_path])

    def _get_path(self, file_info):
        uri = file_info.get_uri()
        if not uri.startswith("file://"):
            return None
        return unquote(urlparse(uri).path)

    def get_file_items(self, *args):
        files = args[-1]
        if len(files) != 1 or not files[0].is_directory():
            return []
        if not shutil.which("kitty"):
            return []
        path = self._get_path(files[0])
        if not path:
            return []
        item = Nautilus.MenuItem(
            name="KittyNautilus::OpenFolder",
            label="Abrir en Kitty",
            tip=f"Abrir {path} en Kitty",
        )
        item.connect("activate", self._open_kitty, path)
        return [item]

    def get_background_items(self, *args):
        current_folder = args[-1]
        if not shutil.which("kitty"):
            return []
        path = self._get_path(current_folder)
        if not path:
            return []
        item = Nautilus.MenuItem(
            name="KittyNautilus::OpenBackground",
            label="Abrir en Kitty",
            tip=f"Abrir {path} en Kitty",
        )
        item.connect("activate", self._open_kitty, path)
        return [item]
EOF

if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
    chown -R "$REAL_USER:$REAL_USER" "$KITTY_CONF_DIR" "$USER_HOME/.local/share/nautilus-python"
fi

if [[ "$SET_DEFAULT_TERM" == true ]]; then
    log_info "Configurando Kitty como terminal predeterminada en GNOME y atajo Ctrl+Alt+T..."
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty'
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec-arg ''

    KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    CURRENT_LIST=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")
    if [[ "$CURRENT_LIST" == "@as []" || -z "$CURRENT_LIST" ]]; then
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$KEY_PATH']"
    elif [[ "$CURRENT_LIST" != *"$KEY_PATH"* ]]; then
        NEW_LIST="${CURRENT_LIST%]*}, '$KEY_PATH']"
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"
    fi
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name 'Terminal (Kitty)'
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command 'kitty'
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding '<Control><Alt>t'
fi

nautilus -q 2>/dev/null || true
log_ok "Kitty configurado correctamente en Fedora 45 Workstation."
