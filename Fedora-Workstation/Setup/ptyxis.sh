#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  ptyxis.sh - Instalación y Personalización de Ptyxis en Fedora 45 Workstation
#  Paleta Catppuccin Mocha + Opacidad 85% + Extensión Nautilus Python
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

PALETTE_DIR="$USER_HOME/.local/share/org.gnome.Ptyxis/palettes"
PALETTE_FILE="$PALETTE_DIR/catppuccin-mocha.palette"
NAUTILUS_EXT_DIR="$USER_HOME/.local/share/nautilus-python/extensions"
NAUTILUS_EXT_FILE="$NAUTILUS_EXT_DIR/open-ptyxis.py"
NAUTILUS_SCRIPT_DIR="$USER_HOME/.local/share/nautilus/scripts"

DO_INSTALL=true
BIND_KEY=false
SET_DEFAULT_TERM=false
ACTION="run"

show_help() {
    cat << EOF
${BOLD}📦 Instalador y Configurador de Ptyxis - Fedora 45 Workstation (GNOME Wayland)${NC}

Verifica o instala ${BOLD}ptyxis${NC} (terminal nativa por defecto de Fedora Workstation para
contenedores Podman/Toolbx/Distrobox), instala la paleta ${BOLD}Catppuccin Mocha${NC}, aplica
transparencia al 85%, JetBrainsMono Nerd Font 11 e integración en Nautilus.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)       Instala Ptyxis y aplica toda la configuración estética
  --no-install, --config Solo aplica la paleta, GSettings y extensión de Nautilus
  --bind-ctrl-alt-t      Asigna el atajo global Ctrl+Alt+T en GNOME a Ptyxis
  --default-terminal     Establece Ptyxis como terminal por defecto y asigna Ctrl+Alt+T
  -s, --status           Muestra el estado actual de Ptyxis, paleta, GSettings y Nautilus
  -h, --help             Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  📦 ${BOLD}ESTADO DE PTYXIS TERMINAL - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if command -v ptyxis &>/dev/null; then
        echo -e "  • Paquete ptyxis:            ${GREEN}Instalado ($(rpm -q --queryformat '%{VERSION}' ptyxis 2>/dev/null || echo 'OK'))${NC}"
    else
        echo -e "  • Paquete ptyxis:            ${RED}No instalado${NC}"
    fi

    if [[ -f "$PALETTE_FILE" ]]; then
        echo -e "  • Paleta Catppuccin Mocha:   ${GREEN}Instalada (${PALETTE_FILE})${NC}"
    else
        echo -e "  • Paleta Catppuccin Mocha:   ${YELLOW}No instalada${NC}"
    fi

    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "^org.gnome.Ptyxis$"; then
        local font_name iface_style
        font_name=$(run_as_user gsettings get org.gnome.Ptyxis font-name 2>/dev/null || echo "N/A")
        iface_style=$(run_as_user gsettings get org.gnome.Ptyxis interface-style 2>/dev/null || echo "N/A")
        echo -e "  • Esquema GSettings Ptyxis:  ${GREEN}Activo (font=${font_name}, style=${iface_style})${NC}"
    else
        echo -e "  • Esquema GSettings Ptyxis:  ${YELLOW}No disponible${NC}"
    fi

    if [[ -f "$NAUTILUS_EXT_FILE" ]]; then
        echo -e "  • Menú contextual Nautilus:  ${GREEN}Activo (${NAUTILUS_EXT_FILE})${NC}"
    else
        echo -e "  • Menú contextual Nautilus:  ${YELLOW}No configurado${NC}"
    fi
    echo -e "${BOLD}======================================================================${NC}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)           ACTION="status"; shift ;;
        --no-install|--config) DO_INSTALL=false; shift ;;
        --bind-ctrl-alt-t)     BIND_KEY=true; shift ;;
        --default-terminal)    SET_DEFAULT_TERM=true; BIND_KEY=true; shift ;;
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
    rpm -q ptyxis &>/dev/null || PKGS_TO_INSTALL+=(ptyxis)
    rpm -q nautilus-python &>/dev/null || PKGS_TO_INSTALL+=(nautilus-python)
    if [[ ${#PKGS_TO_INSTALL[@]} -gt 0 ]]; then
        log_info "Instalando paquetes en Fedora 45 ($DNF_BIN): ${PKGS_TO_INSTALL[*]}..."
        sudo "$DNF_BIN" install -y "${PKGS_TO_INSTALL[@]}"
    else
        log_ok "Ptyxis y nautilus-python ya están instalados."
    fi
fi

log_info "Instalando paleta Catppuccin Mocha para Ptyxis en $PALETTE_FILE..."
mkdir -p "$PALETTE_DIR"

cat << 'EOF' > "$PALETTE_FILE"
[Palette]
Name=Catppuccin Mocha
Primary=true

[Dark]
Background=#1e1e2e
Foreground=#cdd6f4
TitlebarBackground=#181825
TitlebarForeground=#cdd6f4
Cursor=#f5e0dc
Color0=#45475a
Color1=#f38ba8
Color2=#a6e3a1
Color3=#f9e2af
Color4=#89b4fa
Color5=#f5c2e7
Color6=#94e2d5
Color7=#bac2de
Color8=#585b70
Color9=#f38ba8
Color10=#a6e3a1
Color11=#f9e2af
Color12=#89b4fa
Color13=#f5c2e7
Color14=#94e2d5
Color15=#a6adc8
EOF

if run_as_user gsettings list-schemas 2>/dev/null | grep -q "^org.gnome.Ptyxis$"; then
    log_info "Aplicando configuración GSettings a org.gnome.Ptyxis..."
    run_as_user gsettings set org.gnome.Ptyxis interface-style 'dark'
    run_as_user gsettings set org.gnome.Ptyxis use-system-font false
    run_as_user gsettings set org.gnome.Ptyxis font-name 'JetBrainsMono Nerd Font 11'
    run_as_user gsettings set org.gnome.Ptyxis cursor-shape 'block'
    run_as_user gsettings set org.gnome.Ptyxis cursor-blink-mode 'off'
    run_as_user gsettings set org.gnome.Ptyxis scrollbar-policy 'never'
    run_as_user gsettings set org.gnome.Ptyxis restore-session false
    run_as_user gsettings set org.gnome.Ptyxis audible-bell false
    run_as_user gsettings set org.gnome.Ptyxis visual-bell false

    DEFAULT_UUID=$(run_as_user gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'")
    if [[ -z "$DEFAULT_UUID" ]]; then
        DEFAULT_UUID="d4d4d4d4-0000-4000-8000-000000000045"
        run_as_user gsettings set org.gnome.Ptyxis default-profile-uuid "$DEFAULT_UUID"
        run_as_user gsettings set org.gnome.Ptyxis profile-uuids "['$DEFAULT_UUID']"
    fi

    PROFILE_PATH="/org/gnome/Ptyxis/Profiles/$DEFAULT_UUID/"
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH label 'Fedora 45 Workstation'
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH palette 'Catppuccin Mocha'
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH opacity 0.85
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH scrollback-lines 15000 2>/dev/null || true
    log_ok "Perfil Ptyxis ($DEFAULT_UUID) configurado con Catppuccin Mocha y opacidad 85%."
fi

# Limpiar scripts antiguos de Nautilus en submenú para evitar duplicados
rm -f "$NAUTILUS_SCRIPT_DIR/Abrir en Ptyxis" "$NAUTILUS_SCRIPT_DIR/Open in Ptyxis" 2>/dev/null || true

log_info "Configurando extensión Nautilus Python para Ptyxis en $NAUTILUS_EXT_FILE..."
mkdir -p "$NAUTILUS_EXT_DIR"

cat << 'EOF' > "$NAUTILUS_EXT_FILE"
import os
import subprocess
import shutil
from urllib.parse import unquote, urlparse
from gi.repository import Nautilus, GObject


class OpenPtyxisExtension(GObject.GObject, Nautilus.MenuProvider):
    def _open_ptyxis(self, menu, folder_path):
        subprocess.Popen(["ptyxis", "--new-window", f"--working-directory={folder_path}"])

    def _get_path(self, file_info):
        uri = file_info.get_uri()
        if not uri.startswith("file://"):
            return None
        return unquote(urlparse(uri).path)

    def get_file_items(self, *args):
        files = args[-1]
        if len(files) != 1 or not files[0].is_directory():
            return []
        if not shutil.which("ptyxis"):
            return []
        path = self._get_path(files[0])
        if not path:
            return []
        item = Nautilus.MenuItem(
            name="PtyxisNautilus::OpenFolder",
            label="Abrir en Ptyxis",
            tip=f"Abrir {path} en Ptyxis",
        )
        item.connect("activate", self._open_ptyxis, path)
        return [item]

    def get_background_items(self, *args):
        current_folder = args[-1]
        if not shutil.which("ptyxis"):
            return []
        path = self._get_path(current_folder)
        if not path:
            return []
        item = Nautilus.MenuItem(
            name="PtyxisNautilus::OpenBackground",
            label="Abrir en Ptyxis",
            tip=f"Abrir {path} en Ptyxis",
        )
        item.connect("activate", self._open_ptyxis, path)
        return [item]
EOF

if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.local/share/org.gnome.Ptyxis" "$USER_HOME/.local/share/nautilus-python" 2>/dev/null || true
fi

if [[ "$SET_DEFAULT_TERM" == true ]]; then
    log_info "Configurando Ptyxis como terminal predeterminada en GNOME..."
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec 'ptyxis'
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec-arg '--new-window'
fi

if [[ "$BIND_KEY" == true ]]; then
    log_info "Asignando atajo global Ctrl+Alt+T a Ptyxis..."
    KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    CURRENT_LIST=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")
    if [[ "$CURRENT_LIST" == "@as []" || -z "$CURRENT_LIST" ]]; then
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$KEY_PATH']"
    elif [[ "$CURRENT_LIST" != *"$KEY_PATH"* ]]; then
        NEW_LIST="${CURRENT_LIST%]*}, '$KEY_PATH']"
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"
    fi
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name 'Terminal (Ptyxis)'
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command 'ptyxis --new-window'
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding '<Control><Alt>t'
fi

nautilus -q 2>/dev/null || true
log_ok "Ptyxis configurado correctamente en Fedora 45 Workstation."
