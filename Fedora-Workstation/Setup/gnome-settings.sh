#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  gnome-settings.sh - Configuración y Personalización de GNOME Shell (Wayland)
#  Sistema: Fedora 45 Workstation (Mutter / DNF5)
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DO_INSTALL=true
INTERACTIVE=false
THEME_MODE="dark"
TERM_CHOICE="kitty"
BUTTON_SIDE="right"

RUN_ALL=true
RUN_PACKAGES=false
RUN_APPEARANCE=false
RUN_WINDOWS=false
RUN_NAUTILUS=false
RUN_KEYBINDINGS=false
ACTION="run"

show_help() {
    cat << EOF
${BOLD}🖥️  Configurador Integral de GNOME Shell (Wayland) - Fedora 45 Workstation${NC}

Optimiza GNOME Shell, Mutter, Nautilus, Luz Nocturna (4000K), reloj 24h, botones de
ventana, atajos de teclado y menús contextuales en Fedora 45 Workstation.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones Generales:${NC}
  (sin argumentos)           Instala utilidades y aplica toda la configuración
  -i, --interactive          Ejecuta el asistente interactivo de configuración
  --no-install, --config     Aplica ajustes GSettings/Nautilus sin ejecutar DNF5
  -s, --status               Muestra el diagnóstico completo de GNOME Shell
  -h, --help                 Muestra esta ayuda

${BOLD}Selectores de Preferencias:${NC}
  --dark                     Activa modo oscuro (prefer-dark + adw-gtk3-dark) [Por defecto]
  --light                    Activa modo claro (default + adw-gtk3)
  --terminal <nombre>        Terminal para Ctrl+Alt+T: kitty | ghostty | ptyxis | gnome-terminal
  --buttons <right|left>     Posición de botones minimizar/maximizar/cerrar (por defecto: right)

${BOLD}Ejecución Modular (solo ejecuta los módulos indicados):${NC}
  --packages                 Solo instala paquetes de soporte GNOME mediante DNF5
  --appearance               Solo aplica tema, luz nocturna, fuentes y reloj
  --windows                  Solo aplica botones de ventana, Mutter VRR y multitarea
  --nautilus                 Solo aplica preferencias de Nautilus y extensiones Python
  --keybindings              Solo aplica atajos de teclado (Ctrl+Alt+T, capturas, etc.)
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🖥️  ${BOLD}ESTADO DE GNOME SHELL (WAYLAND) - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    local color_scheme gtk_theme btn_layout mutter_exp night_light night_temp clock_fmt term_exec
    color_scheme=$(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "N/A")
    gtk_theme=$(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "N/A")
    btn_layout=$(run_as_user gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null || echo "N/A")
    mutter_exp=$(run_as_user gsettings get org.gnome.mutter experimental-features 2>/dev/null || echo "N/A")
    night_light=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null || echo "N/A")
    night_temp=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature 2>/dev/null || echo "N/A")
    clock_fmt=$(run_as_user gsettings get org.gnome.desktop.interface clock-format 2>/dev/null || echo "N/A")
    term_exec=$(run_as_user gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null || echo "N/A")

    echo -e "  • Esquema de color:          ${CYAN}${color_scheme}${NC} (GTK: ${gtk_theme})"
    echo -e "  • Botones de ventana:        ${CYAN}${btn_layout}${NC}"
    echo -e "  • Mutter Experimental:       ${CYAN}${mutter_exp}${NC}"
    echo -e "  • Luz Nocturna:              ${CYAN}${night_light}${NC} (Temperatura: ${night_temp})"
    echo -e "  • Formato de Reloj:          ${CYAN}${clock_fmt}${NC}"
    echo -e "  • Terminal por defecto:      ${CYAN}${term_exec}${NC}"

    local sort_first
    sort_first=$(run_as_user gsettings get org.gtk.gtk4.Settings.FileChooser sort-directories-first 2>/dev/null || echo "N/A")
    echo -e "  • Nautilus Carpetas Primero: ${CYAN}${sort_first}${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

run_interactive() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🖥️  ${BOLD}ASISTENTE INTERACTIVO DE GNOME SHELL - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    echo -e "\n${BOLD}1) Tema del Escritorio:${NC}"
    echo "   1) Modo Oscuro (prefer-dark + adw-gtk3-dark) [Recomendado]"
    echo "   2) Modo Claro  (default + adw-gtk3)"
    read -rp "Opción [1]: " ans_theme
    [[ "${ans_theme:-1}" == "2" ]] && THEME_MODE="light" || THEME_MODE="dark"

    echo -e "\n${BOLD}2) Terminal para atajo Ctrl+Alt+T y predeterminada:${NC}"
    echo "   1) Kitty (GPU Accelerated) [Recomendado]"
    echo "   2) Ghostty"
    echo "   3) Ptyxis (Nativa de Fedora para Contenedores)"
    echo "   4) GNOME Terminal / Console"
    read -rp "Opción [1]: " ans_term
    case "${ans_term:-1}" in
        2) TERM_CHOICE="ghostty" ;;
        3) TERM_CHOICE="ptyxis" ;;
        4) TERM_CHOICE="gnome-terminal" ;;
        *) TERM_CHOICE="kitty" ;;
    esac

    echo -e "\n${BOLD}3) Disposición de botones de ventana (Minimizar, Maximizar, Cerrar):${NC}"
    echo "   1) Derecha (appmenu:minimize,maximize,close) [Recomendado]"
    echo "   2) Izquierda estilo macOS (close,minimize,maximize:appmenu)"
    read -rp "Opción [1]: " ans_btn
    [[ "${ans_btn:-1}" == "2" ]] && BUTTON_SIDE="left" || BUTTON_SIDE="right"
}

install_gnome_packages() {
    log_info "Verificando paquetes de integración de GNOME en Fedora 45 ($DNF_BIN)..."
    local pkgs=(
        gnome-tweaks
        gnome-extensions-app
        dconf-editor
        wl-clipboard
        libnotify
        nautilus-python
        adw-gtk3-theme
        papirus-icon-theme
        grim
        slurp
    )
    local missing=()
    for p in "${pkgs[@]}"; do
        rpm -q "$p" &>/dev/null || missing+=("$p")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        sudo "$DNF_BIN" install -y "${missing[@]}"
    else
        log_ok "Paquetes base de herramientas GNOME Wayland ya están instalados."
    fi
}

apply_appearance() {
    log_info "Aplicando ajustes de apariencia, reloj 24h, batería y Luz Nocturna (4000K)..."
    if [[ -x "$SCRIPT_DIR/apariencia.sh" ]]; then
        if [[ "$THEME_MODE" == "light" ]]; then
            "$SCRIPT_DIR/apariencia.sh" --no-install --light
        else
            "$SCRIPT_DIR/apariencia.sh" --no-install --dark
        fi
    fi

    # Reloj, calendario y porcentaje de batería en barra superior
    run_as_user gsettings set org.gnome.desktop.interface clock-format '24h'
    run_as_user gsettings set org.gnome.desktop.interface clock-show-date true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-seconds false
    run_as_user gsettings set org.gnome.desktop.interface clock-show-weekday true
    run_as_user gsettings set org.gnome.desktop.calendar show-weekdate true
    run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true
    run_as_user gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
    run_as_user gsettings set org.gnome.desktop.interface font-hinting 'slight'

    # Luz nocturna a 4000K automática
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000
    log_ok "Apariencia, reloj y Luz Nocturna aplicados."
}

apply_windows() {
    log_info "Aplicando preferencias de ventanas, Mutter Wayland (VRR) y multitarea..."
    if [[ "$BUTTON_SIDE" == "left" ]]; then
        run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:appmenu'
    else
        run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
    fi

    run_as_user gsettings set org.gnome.mutter center-new-windows true
    run_as_user gsettings set org.gnome.mutter edge-tiling true
    run_as_user gsettings set org.gnome.mutter dynamic-workspaces true
    run_as_user gsettings set org.gnome.mutter workspaces-only-on-primary false
    run_as_user gsettings set org.gnome.shell.app-switcher current-workspace-only false

    # Activar VRR, escalado fraccional y XWayland native scaling en Mutter
    run_as_user gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate', 'xwayland-native-scaling']" 2>/dev/null || \
        run_as_user gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate']" 2>/dev/null || true

    # Limpieza automática de temporales y papelera (30 días)
    run_as_user gsettings set org.gnome.desktop.privacy remove-old-temp-files true
    run_as_user gsettings set org.gnome.desktop.privacy remove-old-trash-files true
    run_as_user gsettings set org.gnome.desktop.privacy old-files-age 30
    log_ok "Ventanas, Mutter y privacidad configurados."
}

apply_nautilus() {
    log_info "Optimizando el gestor de archivos Nautilus y extensiones contextuales..."
    run_as_user gsettings set org.gtk.Settings.FileChooser sort-directories-first true 2>/dev/null || true
    run_as_user gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-create-link true 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-delete-permanently true 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences recursive-search 'always' 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always' 2>/dev/null || true

    # Plantillas de documento en ~/Plantillas y ~/Templates
    for tpl_dir in "$USER_HOME/Plantillas" "$USER_HOME/Templates"; do
        if [[ -d "$tpl_dir" ]] || [[ "$tpl_dir" == "$USER_HOME/Plantillas" ]]; then
            mkdir -p "$tpl_dir"
            touch "$tpl_dir/Archivo vacío.txt" "$tpl_dir/Nota Markdown.md"
            cat << 'EOF' > "$tpl_dir/Script Bash.sh"
#!/usr/bin/env bash
set -euo pipefail

EOF
            chmod +x "$tpl_dir/Script Bash.sh"
            [[ $EUID -eq 0 && "$REAL_USER" != "root" ]] && chown -R "$REAL_USER:$REAL_USER" "$tpl_dir"
        fi
    done

    # Limpiar scripts antiguos de Nautilus en submenú y configurar extensiones Python de primer nivel
    local nautilus_ext_dir="$USER_HOME/.local/share/nautilus-python/extensions"
    mkdir -p "$nautilus_ext_dir"

    [[ -x "$SCRIPT_DIR/kitty.sh" ]] && "$SCRIPT_DIR/kitty.sh" --no-install >/dev/null 2>&1 || true
    [[ -x "$SCRIPT_DIR/ghostty.sh" ]] && "$SCRIPT_DIR/ghostty.sh" --no-install >/dev/null 2>&1 || true
    [[ -x "$SCRIPT_DIR/ptyxis.sh" ]] && "$SCRIPT_DIR/ptyxis.sh" --no-install >/dev/null 2>&1 || true

    # Extensión para abrir en Antigravity / VS Code desde el menú contextual principal de Nautilus
    cat << 'EOF' > "$nautilus_ext_dir/open-code-editors.py"
import os
import subprocess
import shutil
from urllib.parse import unquote, urlparse
from gi.repository import Nautilus, GObject


class OpenCodeEditorsExtension(GObject.GObject, Nautilus.MenuProvider):
    def _open_cmd(self, menu, cmd, path):
        subprocess.Popen([cmd, path])

    def _get_path(self, file_info):
        uri = file_info.get_uri()
        if not uri.startswith("file://"):
            return None
        return unquote(urlparse(uri).path)

    def _build_items(self, path, prefix):
        items = []
        editors = [
            ("antigravity", "Antigravity"),
            ("agy", "Antigravity CLI"),
            ("code", "VS Code"),
        ]
        seen_labels = set()
        for binary, label in editors:
            if binary == "agy" and "Antigravity" in seen_labels:
                continue
            if shutil.which(binary):
                seen_labels.add("Antigravity" if "Antigravity" in label else label)
                item = Nautilus.MenuItem(
                    name=f"CodeEditors::{prefix}_{binary}",
                    label=f"Abrir en {label}",
                    tip=f"Abrir {path} en {label}",
                )
                item.connect("activate", self._open_cmd, binary, path)
                items.append(item)
        return items

    def get_file_items(self, *args):
        files = args[-1]
        if len(files) != 1 or not files[0].is_directory():
            return []
        path = self._get_path(files[0])
        if not path:
            return []
        return self._build_items(path, "Folder")

    def get_background_items(self, *args):
        current_folder = args[-1]
        path = self._get_path(current_folder)
        if not path:
            return []
        return self._build_items(path, "Bg")
EOF

    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.local/share/nautilus-python"
    fi
    nautilus -q 2>/dev/null || true
    log_ok "Nautilus y extensiones contextuales configuradas."
}

apply_keybindings() {
    log_info "Configurando terminal predeterminada ($TERM_CHOICE) y atajo Ctrl+Alt+T..."
    local term_cmd="$TERM_CHOICE"
    local term_arg=""
    if [[ "$TERM_CHOICE" == "ptyxis" ]]; then
        term_cmd="ptyxis --new-window"
        term_arg="--new-window"
    fi

    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec "$TERM_CHOICE"
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec-arg "$term_arg"

    local key_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    local current_list
    current_list=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")
    if [[ "$current_list" == "@as []" || -z "$current_list" ]]; then
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$key_path']"
    elif [[ "$current_list" != *"$key_path"* ]]; then
        local new_list="${current_list%]*}, '$key_path']"
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_list"
    fi

    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key_path name "Terminal ($TERM_CHOICE)"
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key_path command "$term_cmd"
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key_path binding '<Control><Alt>t'
    log_ok "Atajos de teclado configurados (Ctrl+Alt+T -> $TERM_CHOICE)."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)           ACTION="status"; shift ;;
        -i|--interactive)      INTERACTIVE=true; shift ;;
        --no-install|--config) DO_INSTALL=false; shift ;;
        --dark)                THEME_MODE="dark"; shift ;;
        --light)               THEME_MODE="light"; shift ;;
        --terminal)            TERM_CHOICE="${2:-kitty}"; shift 2 ;;
        --buttons)             BUTTON_SIDE="${2:-right}"; shift 2 ;;
        --packages)            RUN_ALL=false; RUN_PACKAGES=true; shift ;;
        --appearance)          RUN_ALL=false; RUN_APPEARANCE=true; shift ;;
        --windows)             RUN_ALL=false; RUN_WINDOWS=true; shift ;;
        --nautilus)            RUN_ALL=false; RUN_NAUTILUS=true; shift ;;
        --keybindings)         RUN_ALL=false; RUN_KEYBINDINGS=true; shift ;;
        -h|--help)             show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
fi

if [[ "$INTERACTIVE" == true ]]; then
    run_interactive
fi

if [[ "$RUN_ALL" == true ]]; then
    [[ "$DO_INSTALL" == true ]] && install_gnome_packages
    apply_appearance
    apply_windows
    apply_nautilus
    apply_keybindings
else
    [[ "$RUN_PACKAGES" == true ]]    && install_gnome_packages
    [[ "$RUN_APPEARANCE" == true ]]  && apply_appearance
    [[ "$RUN_WINDOWS" == true ]]     && apply_windows
    [[ "$RUN_NAUTILUS" == true ]]    && apply_nautilus
    [[ "$RUN_KEYBINDINGS" == true ]] && apply_keybindings
fi

log_ok "Configuración de GNOME Shell en Fedora 45 Workstation completada."
show_status
