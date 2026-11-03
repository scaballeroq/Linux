#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  ghostty.sh - Instalación y Configuración de Ghostty en Fedora 45 Workstation
#  Catppuccin Mocha + Wayland + Atajo GNOME + Menú Contextual Nautilus (Python)
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

GHOSTTY_CONF_DIR="$USER_HOME/.config/ghostty"
GHOSTTY_CONF_FILE="$GHOSTTY_CONF_DIR/config"
NAUTILUS_EXT_DIR="$USER_HOME/.local/share/nautilus-python/extensions"
NAUTILUS_EXT_FILE="$NAUTILUS_EXT_DIR/open-ghostty.py"
NAUTILUS_SCRIPT_DIR="$USER_HOME/.local/share/nautilus/scripts"

DO_INSTALL=true
BIND_KEY=false
SET_DEFAULT_TERM=false
ACTION="run"

show_help() {
    cat << EOF
${BOLD}👻 Instalador y Configurador de Ghostty - Fedora 45 Workstation (GNOME Wayland)${NC}

Instala Ghostty mediante DNF5 (repositorio oficial / COPR pgdev/ghostty), aplica el
tema ${BOLD}Catppuccin Mocha${NC}, JetBrainsMono Nerd Font, transparencia al 85% e integración
en el menú contextual principal de Nautilus mediante ${BOLD}nautilus-python${NC}.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)      Instala Ghostty y aplica toda la configuración
  --no-install, --config Solo genera la configuración y extensión de Nautilus sin usar DNF5
  --bind-ctrl-alt-t     Asigna el atajo global Ctrl+Alt+T en GNOME a Ghostty
  --default-terminal    Configura Ghostty como terminal por defecto en GNOME y asigna Ctrl+Alt+T
  -s, --status          Muestra el estado actual de Ghostty, configuración y Nautilus
  -h, --help            Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  👻 ${BOLD}ESTADO DE GHOSTTY TERMINAL - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if command -v ghostty &>/dev/null; then
        echo -e "  • Binario Ghostty:           ${GREEN}Instalado ($(ghostty --version 2>/dev/null | head -n1 || echo 'OK'))${NC}"
    else
        echo -e "  • Binario Ghostty:           ${RED}No instalado${NC}"
    fi

    if [[ -f "$GHOSTTY_CONF_FILE" ]]; then
        echo -e "  • Configuración:             ${GREEN}${GHOSTTY_CONF_FILE}${NC}"
    else
        echo -e "  • Configuración:             ${YELLOW}No configurada${NC}"
    fi

    if rpm -q nautilus-python &>/dev/null; then
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
    default_term=$(run_as_user gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null || echo "N/A")
    echo -e "  • Terminal por defecto GNOME:${CYAN} ${default_term}${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)          ACTION="status"; shift ;;
        --no-install|--config) DO_INSTALL=false; shift ;;
        --bind-ctrl-alt-t)    BIND_KEY=true; shift ;;
        --default-terminal)   SET_DEFAULT_TERM=true; BIND_KEY=true; shift ;;
        -h|--help)            show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
fi

if [[ "$DO_INSTALL" == true ]]; then
    if ! command -v ghostty &>/dev/null; then
        log_info "Instalando Ghostty en Fedora 45 mediante $DNF_BIN..."
        if ! sudo "$DNF_BIN" install -y ghostty 2>/dev/null; then
            log_info "Habilitando repositorio COPR pgdev/ghostty para Fedora..."
            sudo "$DNF_BIN" install -y dnf5-plugins 2>/dev/null || true
            sudo "$DNF_BIN" copr enable -y pgdev/ghostty || sudo "$DNF_BIN" copr enable -y scottames/ghostty
            sudo "$DNF_BIN" install -y ghostty
        fi
    else
        log_ok "Ghostty ya está instalado."
    fi

    if ! rpm -q nautilus-python &>/dev/null; then
        log_info "Instalando nautilus-python para menú contextual de primer nivel en Nautilus..."
        sudo "$DNF_BIN" install -y nautilus-python
    fi
fi

log_info "Generando configuración de Ghostty (Catppuccin Mocha + Wayland) en $GHOSTTY_CONF_FILE..."
mkdir -p "$GHOSTTY_CONF_DIR"

cat << 'EOF' > "$GHOSTTY_CONF_FILE"
# ==============================================================================
#  Ghostty Configuration - Fedora 45 Workstation (GNOME Wayland)
#  Theme: Catppuccin Mocha | Font: JetBrainsMono Nerd Font
# ==============================================================================

theme = Catppuccin Mocha
font-family = JetBrainsMono Nerd Font
font-size = 11

# Apariencia y Transparencia Wayland
background-opacity = 0.85
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

# Historial y Shell Integration
scrollback-limit = 10000000
shell-integration = detect
confirm-close-surface = false

# Atajos de teclado intuitivos
keybind = ctrl+shift+c=copy_to_clipboard
keybind = ctrl+shift+v=paste_from_clipboard
keybind = ctrl+shift+t=new_tab
keybind = ctrl+shift+w=close_surface
keybind = ctrl+shift+r=reload_config
keybind = ctrl+plus=increase_font_size:1
keybind = ctrl+minus=decrease_font_size:1
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
from gi.repository import Nautilus, GObject


class OpenGhosttyExtension(GObject.GObject, Nautilus.MenuProvider):
    def _open_ghostty(self, menu, folder_path):
        subprocess.Popen(["ghostty", f"--working-directory={folder_path}"])

    def _get_path(self, file_info):
        uri = file_info.get_uri()
        if not uri.startswith("file://"):
            return None
        return unquote(urlparse(uri).path)

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
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec 'ghostty'
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec-arg ''
fi

if [[ "$BIND_KEY" == true ]]; then
    log_info "Asignando atajo global Ctrl+Alt+T a Ghostty en GNOME..."
    KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    CURRENT_LIST=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")
    if [[ "$CURRENT_LIST" == "@as []" || -z "$CURRENT_LIST" ]]; then
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$KEY_PATH']"
    elif [[ "$CURRENT_LIST" != *"$KEY_PATH"* ]]; then
        NEW_LIST="${CURRENT_LIST%]*}, '$KEY_PATH']"
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"
    fi
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name 'Terminal (Ghostty)'
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command 'ghostty'
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding '<Control><Alt>t'
fi

nautilus -q 2>/dev/null || true
log_ok "Ghostty configurado correctamente en Fedora 45 Workstation."
