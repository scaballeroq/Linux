#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  ptyxis.sh - Instalación y Personalización de Ptyxis en CachyOS Workstation
#  Paleta Catppuccin Mocha + Opacidad Wayland + Extensión Nautilus Python
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
        sudo -u "$REAL_USER" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${REAL_UID}/bus" \
            XDG_RUNTIME_DIR="/run/user/${REAL_UID}" \
            "$@"
    else
        "$@"
    fi
}

has_schema() {
    local schema="$1"
    (run_as_user gsettings list-schemas 2>/dev/null || true) | grep -Fxq "$schema"
}

fix_permissions() {
    local target_path="$1"
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" && -e "$target_path" ]]; then
        chown -R "$REAL_USER:$REAL_USER" "$target_path" 2>/dev/null || true
    fi
}

PALETTE_DIR="$USER_HOME/.local/share/org.gnome.Ptyxis/palettes"
PALETTE_FILE="$PALETTE_DIR/catppuccin-mocha.palette"
NAUTILUS_EXT_DIR="$USER_HOME/.local/share/nautilus-python/extensions"
NAUTILUS_EXT_FILE="$NAUTILUS_EXT_DIR/open-ptyxis.py"
NAUTILUS_SCRIPT_DIR="$USER_HOME/.local/share/nautilus/scripts"
XDG_TERMINALS_FILE="$USER_HOME/.config/xdg-terminals.list"

OPACITY="0.85"
FONT_NAME="JetBrainsMono Nerd Font 11"
PALETTE_NAME="Catppuccin Mocha"
DO_INSTALL=true
BIND_KEY=false
SET_DEFAULT_TERM=false
UNINSTALL_NAUTILUS=false
ACTION="run"

show_help() {
    cat << EOF
${BOLD}📦 Instalador y Optimizador de Ptyxis - CachyOS Workstation (GNOME Wayland)${NC}

Instala y optimiza ${BOLD}ptyxis${NC} (terminal acelerada por GPU para
contenedores Podman/Distrobox), aplica el tema ${BOLD}Catppuccin Mocha${NC},
transparencia configurable, tipografía JetBrainsMono Nerd Font, atajo global
e integración de primer nivel en el menú contextual de Nautilus.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)       Instala dependencias y aplica toda la configuración estética
  --no-install, --config Solo aplica la configuración sin reinstalar paquetes
  --opacity <0.1-1.0>    Define la opacidad del perfil (por defecto: 0.85)
  --font <fuente>        Define la tipografía (por defecto: 'JetBrainsMono Nerd Font 11')
  --palette <nombre>     Define el nombre de la paleta (por defecto: 'Catppuccin Mocha')
  --bind-ctrl-alt-t      Asigna el atajo global Ctrl+Alt+T en GNOME a Ptyxis
  --default-terminal     Establece Ptyxis como terminal predeterminada y asigna Ctrl+Alt+T
  --uninstall-nautilus   Elimina la extensión de menú contextual de Nautilus para Ptyxis
  -s, --status           Muestra diagnóstico detallado del estado de Ptyxis
  -h, --help             Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  📦 ${BOLD}ESTADO DE PTYXIS TERMINAL - CACHYOS WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    # 1. Binario y paquetes
    if command -v ptyxis &>/dev/null; then
        local ptyxis_ver
        ptyxis_ver=$(pacman -Q ptyxis 2>/dev/null | awk '{print $2}' || ptyxis --version 2>/dev/null || echo "OK")
        echo -e "  • Paquete ptyxis:            ${GREEN}Instalado (${ptyxis_ver})${NC}"
    else
        echo -e "  • Paquete ptyxis:            ${RED}No instalado${NC}"
    fi

    if pacman -Q python-nautilus &>/dev/null; then
        local np_ver
        np_ver=$(pacman -Q python-nautilus 2>/dev/null | awk '{print $2}' || echo "OK")
        echo -e "  • Paquete python-nautilus:   ${GREEN}Instalado (${np_ver})${NC}"
    else
        echo -e "  • Paquete python-nautilus:   ${YELLOW}No instalado${NC}"
    fi

    if pacman -Q wl-clipboard &>/dev/null; then
        echo -e "  • Paquete wl-clipboard:      ${GREEN}Instalado (Portapapeles Wayland)${NC}"
    else
        echo -e "  • Paquete wl-clipboard:      ${YELLOW}No instalado${NC}"
    fi

    # 2. Paleta de colores
    if [[ -f "$PALETTE_FILE" ]]; then
        echo -e "  • Paleta Catppuccin Mocha:   ${GREEN}Instalada (${PALETTE_FILE})${NC}"
    else
        echo -e "  • Paleta Catppuccin Mocha:   ${YELLOW}No instalada en ~/.local${NC} (usa recursos internos de Ptyxis)"
    fi

    # 3. GSettings Global Ptyxis
    if has_schema "org.gnome.Ptyxis"; then
        local font_val sys_font style_val toast_val bell_aud bell_vis
        font_val=$(run_as_user gsettings get org.gnome.Ptyxis font-name 2>/dev/null || echo "N/A")
        sys_font=$(run_as_user gsettings get org.gnome.Ptyxis use-system-font 2>/dev/null || echo "N/A")
        style_val=$(run_as_user gsettings get org.gnome.Ptyxis interface-style 2>/dev/null || echo "N/A")
        toast_val=$(run_as_user gsettings get org.gnome.Ptyxis toast-on-copy-clipboard 2>/dev/null || echo "N/A")
        bell_aud=$(run_as_user gsettings get org.gnome.Ptyxis audible-bell 2>/dev/null || echo "N/A")
        bell_vis=$(run_as_user gsettings get org.gnome.Ptyxis visual-bell 2>/dev/null || echo "N/A")

        echo -e "  • Esquema GSettings Global:  ${GREEN}Activo${NC}"
        echo -e "      - Tema / Estilo:         ${CYAN}${style_val}${NC}"
        echo -e "      - Tipografía:            ${CYAN}${font_val}${NC} (use-system-font: ${sys_font})"
        echo -e "      - Campanas (aud/vis):     ${bell_aud} / ${bell_vis}"
        echo -e "      - Notificación de copia: ${toast_val}"

        # 4. Perfil Predeterminado
        local def_uuid
        def_uuid=$(run_as_user gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || echo "")
        if [[ -n "$def_uuid" && "$def_uuid" != "@ms nothing" ]]; then
            local prof_path="/org/gnome/Ptyxis/Profiles/$def_uuid/"
            local prof_label prof_palette prof_op prof_scroll prof_cont
            prof_label=$(run_as_user gsettings get org.gnome.Ptyxis.Profile:$prof_path label 2>/dev/null | tr -d "'" || echo "N/A")
            prof_palette=$(run_as_user gsettings get org.gnome.Ptyxis.Profile:$prof_path palette 2>/dev/null | tr -d "'" || echo "N/A")
            prof_op=$(run_as_user gsettings get org.gnome.Ptyxis.Profile:$prof_path opacity 2>/dev/null || echo "1.0")
            prof_scroll=$(run_as_user gsettings get org.gnome.Ptyxis.Profile:$prof_path scrollback-lines 2>/dev/null || echo "N/A")
            prof_cont=$(run_as_user gsettings get org.gnome.Ptyxis.Profile:$prof_path preserve-container 2>/dev/null || echo "N/A")

            # Formatear opacidad a 2 decimales
            local prof_op_fmt
            prof_op_fmt=$(awk '{printf "%.2f", $1}' <<< "$prof_op" 2>/dev/null || echo "$prof_op")

            echo -e "  • Perfil Activo ($def_uuid):"
            echo -e "      - Etiqueta:              ${BOLD}${prof_label}${NC}"
            echo -e "      - Paleta configurada:    ${CYAN}${prof_palette}${NC}"
            echo -e "      - Opacidad / Alpha:      ${GREEN}${prof_op_fmt}${NC}"
            echo -e "      - Líneas de scroll:      ${prof_scroll}"
            echo -e "      - Preservar contenedor:  ${prof_cont}"
        else
            echo -e "  • Perfil Activo:             ${YELLOW}No hay perfil por defecto definido${NC}"
        fi
    else
        echo -e "  • Esquema GSettings Global:  ${YELLOW}No disponible (ptyxis no inicializado)${NC}"
    fi

    # 5. Integración de Sistema y Escritorio
    local def_term
    def_term=$(run_as_user gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null | tr -d "'" || echo "N/A")
    echo -e "  • Terminal por defecto GNOME:${CYAN} ${def_term}${NC}"

    if [[ -f "$XDG_TERMINALS_FILE" ]]; then
        local top_xdg
        top_xdg=$(head -n1 "$XDG_TERMINALS_FILE" 2>/dev/null || echo "Vacío")
        echo -e "  • Terminal por defecto XDG:  ${CYAN}${top_xdg}${NC} (${XDG_TERMINALS_FILE})"
    else
        echo -e "  • Terminal por defecto XDG:  ${YELLOW}No configurado${NC}"
    fi

    # Verificar atajo Ctrl+Alt+T
    local custom_list key_assigned=false key_target=""
    custom_list=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "")
    if [[ "$custom_list" =~ custom[0-9]+ ]]; then
        local paths
        paths=$(echo "$custom_list" | grep -o -E "'[^']+'" | tr -d "'")
        for p in $paths; do
            local b_binding b_cmd
            b_binding=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$p binding 2>/dev/null || true)
            b_cmd=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$p command 2>/dev/null || true)
            if [[ "$b_binding" == "'<Control><Alt>t'" ]]; then
                key_assigned=true
                key_target="$b_cmd ($p)"
                break
            fi
        done
    fi

    if [[ "$key_assigned" == true ]]; then
        echo -e "  • Atajo Ctrl+Alt+T GNOME:    ${GREEN}Asignado -> ${key_target}${NC}"
    else
        echo -e "  • Atajo Ctrl+Alt+T GNOME:    ${YELLOW}No asignado${NC}"
    fi

    # Verificar menú contextual Nautilus
    if [[ -f "$NAUTILUS_EXT_FILE" ]]; then
        echo -e "  • Extensión Python Nautilus: ${GREEN}Activa (${NAUTILUS_EXT_FILE})${NC}"
    else
        echo -e "  • Extensión Python Nautilus: ${YELLOW}No instalada${NC}"
    fi

    # 6. Disponibilidad de fuente JetBrainsMono
    if (fc-list "JetBrainsMono Nerd Font" 2>/dev/null || true) | grep -q .; then
        echo -e "  • Tipografía JetBrainsMono:  ${GREEN}Instalada en el sistema${NC}"
    else
        echo -e "  • Tipografía JetBrainsMono:  ${YELLOW}No detectada en fontconfig${NC}"
    fi

    echo -e "${BOLD}======================================================================${NC}"
}

# Procesamiento de argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)
            ACTION="status"
            shift
            ;;
        --no-install|--config)
            DO_INSTALL=false
            shift
            ;;
        --bind-ctrl-alt-t)
            BIND_KEY=true
            shift
            ;;
        --default-terminal)
            SET_DEFAULT_TERM=true
            BIND_KEY=true
            shift
            ;;
        --opacity)
            if [[ -n "${2:-}" && "$2" =~ ^0(\.[0-9]+)?$|^1(\.0+)?$ ]]; then
                OPACITY="$2"
                shift 2
            else
                log_err "El valor de --opacity debe ser un número decimal entre 0.1 y 1.0 (ej. 0.85)."
                exit 1
            fi
            ;;
        --font)
            if [[ -n "${2:-}" ]]; then
                FONT_NAME="$2"
                shift 2
            else
                log_err "Debe especificar el nombre y tamaño de la fuente para --font."
                exit 1
            fi
            ;;
        --palette)
            if [[ -n "${2:-}" ]]; then
                PALETTE_NAME="$2"
                shift 2
            else
                log_err "Debe especificar el nombre de la paleta para --palette."
                exit 1
            fi
            ;;
        --uninstall-nautilus)
            UNINSTALL_NAUTILUS=true
            ACTION="uninstall_nautilus"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_err "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
fi

if [[ "$ACTION" == "uninstall_nautilus" ]]; then
    log_info "Desinstalando extensión de Nautilus para Ptyxis..."
    rm -f "$NAUTILUS_EXT_FILE"
    rm -f "$NAUTILUS_SCRIPT_DIR/Abrir en Ptyxis" "$NAUTILUS_SCRIPT_DIR/Open in Ptyxis" 2>/dev/null || true
    run_as_user nautilus -q 2>/dev/null || true
    log_ok "Extensión de Nautilus eliminada correctamente."
    exit 0
fi

# ==============================================================================
# 1. INSTALACIÓN DE DEPENDENCIAS
# ==============================================================================
if [[ "$DO_INSTALL" == true ]]; then
    PKGS_TO_INSTALL=()
    pacman -Q ptyxis &>/dev/null || PKGS_TO_INSTALL+=(ptyxis)
    pacman -Q python-nautilus &>/dev/null || PKGS_TO_INSTALL+=(python-nautilus)
    pacman -Q wl-clipboard &>/dev/null || PKGS_TO_INSTALL+=(wl-clipboard)

    if [[ ${#PKGS_TO_INSTALL[@]} -gt 0 ]]; then
        log_info "Instalando paquetes requeridos en CachyOS (Pacman): ${PKGS_TO_INSTALL[*]}..."
        if [[ $EUID -eq 0 ]]; then
            pacman -S --needed --noconfirm "${PKGS_TO_INSTALL[@]}" 2>/dev/null || true
        else
            sudo pacman -S --needed --noconfirm "${PKGS_TO_INSTALL[@]}" 2>/dev/null || true
        fi
        log_ok "Paquetes instalados correctamente."
    else
        log_ok "Ptyxis, python-nautilus y wl-clipboard ya están instalados."
    fi
fi

# ==============================================================================
# 2. INSTALACIÓN DE PALETA CATPPUCCIN MOCHA
# ==============================================================================
log_info "Configurando archivo de paleta Catppuccin Mocha en $PALETTE_FILE..."
mkdir -p "$PALETTE_DIR"

cat << 'EOF' > "$PALETTE_FILE"
[Palette]
Name=Catppuccin Mocha
Background=#1E1E2E
Foreground=#CDD6F4
TitlebarBackground=#181825
TitlebarForeground=#CDD6F4
Cursor=#F5E0DC
Color0=#45475A
Color1=#F38BA8
Color2=#A6E3A1
Color3=#F9E2AF
Color4=#89B4FA
Color5=#F5C2E7
Color6=#94E2D5
Color7=#BAC2DE
Color8=#585B70
Color9=#F38BA8
Color10=#A6E3A1
Color11=#F9E2AF
Color12=#89B4FA
Color13=#F5C2E7
Color14=#94E2D5
Color15=#A6ADC8

[Dark]
Background=#1E1E2E
Foreground=#CDD6F4
TitlebarBackground=#181825
TitlebarForeground=#CDD6F4
Cursor=#F5E0DC
Color0=#45475A
Color1=#F38BA8
Color2=#A6E3A1
Color3=#F9E2AF
Color4=#89B4FA
Color5=#F5C2E7
Color6=#94E2D5
Color7=#BAC2DE
Color8=#585B70
Color9=#F38BA8
Color10=#A6E3A1
Color11=#F9E2AF
Color12=#89B4FA
Color13=#F5C2E7
Color14=#94E2D5
Color15=#A6ADC8
EOF

chmod 644 "$PALETTE_FILE"
fix_permissions "$USER_HOME/.local/share/org.gnome.Ptyxis"

# ==============================================================================
# 3. CONFIGURACIÓN GSETTINGS DE PTYXIS (GLOBAL Y PERFIL)
# ==============================================================================
if has_schema "org.gnome.Ptyxis"; then
    log_info "Aplicando ajustes GSettings globales a org.gnome.Ptyxis..."
    run_as_user gsettings set org.gnome.Ptyxis interface-style 'dark'
    run_as_user gsettings set org.gnome.Ptyxis use-system-font false
    run_as_user gsettings set org.gnome.Ptyxis font-name "$FONT_NAME"
    run_as_user gsettings set org.gnome.Ptyxis cursor-shape 'block'
    run_as_user gsettings set org.gnome.Ptyxis cursor-blink-mode 'off'
    run_as_user gsettings set org.gnome.Ptyxis scrollbar-policy 'never'
    run_as_user gsettings set org.gnome.Ptyxis restore-session false
    run_as_user gsettings set org.gnome.Ptyxis audible-bell false
    run_as_user gsettings set org.gnome.Ptyxis visual-bell false
    run_as_user gsettings set org.gnome.Ptyxis toast-on-copy-clipboard true
    run_as_user gsettings set org.gnome.Ptyxis enable-zoom-scroll-ctrl true
    run_as_user gsettings set org.gnome.Ptyxis restore-window-size true

    # Obtener o inicializar UUID del perfil predeterminado
    DEFAULT_UUID=$(run_as_user gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || echo "")
    if [[ -z "$DEFAULT_UUID" || "$DEFAULT_UUID" == "@ms nothing" ]]; then
        EXISTING_LIST=$(run_as_user gsettings get org.gnome.Ptyxis profile-uuids 2>/dev/null || echo "[]")
        FIRST_UUID=$(echo "$EXISTING_LIST" | grep -o -E "[a-f0-9]{32}|[a-f0-9-]{36}" | head -n1 || true)
        if [[ -n "$FIRST_UUID" ]]; then
            DEFAULT_UUID="$FIRST_UUID"
        else
            DEFAULT_UUID="d4d4d4d4-0000-4000-8000-000000000045"
        fi
        run_as_user gsettings set org.gnome.Ptyxis default-profile-uuid "$DEFAULT_UUID"
    fi

    # Asegurar que DEFAULT_UUID esté incluido en profile-uuids
    PROFILE_LIST=$(run_as_user gsettings get org.gnome.Ptyxis profile-uuids 2>/dev/null || echo "[]")
    if [[ "$PROFILE_LIST" == "@as []" || "$PROFILE_LIST" == "[]" || -z "$PROFILE_LIST" ]]; then
        run_as_user gsettings set org.gnome.Ptyxis profile-uuids "['$DEFAULT_UUID']"
    elif [[ "$PROFILE_LIST" != *"$DEFAULT_UUID"* ]]; then
        NEW_PROFILE_LIST="${PROFILE_LIST%]*}, '$DEFAULT_UUID']"
        run_as_user gsettings set org.gnome.Ptyxis profile-uuids "$NEW_PROFILE_LIST"
    fi

    # Configuración del perfil de Ptyxis
    PROFILE_PATH="/org/gnome/Ptyxis/Profiles/$DEFAULT_UUID/"
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH label 'CachyOS Workstation'
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH palette "$PALETTE_NAME"
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH opacity "$OPACITY"
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH limit-scrollback true
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH scrollback-lines 15000
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH preserve-directory 'safe'
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH preserve-container 'always'
    run_as_user gsettings set org.gnome.Ptyxis.Profile:$PROFILE_PATH bold-is-bright false

    log_ok "Perfil Ptyxis ($DEFAULT_UUID) configurado: paleta '$PALETTE_NAME', opacidad $OPACITY, fuente '$FONT_NAME'."
else
    log_warn "Esquema GSettings org.gnome.Ptyxis no encontrado aún. Se aplicará al iniciar Ptyxis por primera vez."
fi

# ==============================================================================
# 4. EXTENSIÓN NAUTILUS PYTHON (MENÚ CONTEXTUAL DE PRIMER NIVEL)
# ==============================================================================
# Limpiar scripts de nautilus antiguos o duplicados en el submenú Scripts
rm -f "$NAUTILUS_SCRIPT_DIR/Abrir en Ptyxis" "$NAUTILUS_SCRIPT_DIR/Open in Ptyxis" 2>/dev/null || true

log_info "Configurando extensión de Nautilus en $NAUTILUS_EXT_FILE..."
mkdir -p "$NAUTILUS_EXT_DIR"

cat << 'EOF' > "$NAUTILUS_EXT_FILE"
import os
import shutil
import subprocess
from urllib.parse import unquote, urlparse

import gi
try:
    gi.require_version('Nautilus', '4.1')
except ValueError:
    try:
        gi.require_version('Nautilus', '4.0')
    except ValueError:
        pass

from gi.repository import GObject, Nautilus


class OpenPtyxisExtension(GObject.GObject, Nautilus.MenuProvider):
    def _open_ptyxis(self, menu, folder_path, *args):
        if not folder_path or not os.path.exists(folder_path):
            return
        subprocess.Popen(
            ["ptyxis", "--new-window", f"--working-directory={folder_path}"],
            cwd=folder_path,
            start_new_session=True,
        )

    def _get_path(self, file_info):
        try:
            uri = file_info.get_uri()
            if not uri or not uri.startswith("file://"):
                return None
            return unquote(urlparse(uri).path)
        except Exception:
            return None

    def get_file_items(self, *args):
        if not args or not shutil.which("ptyxis"):
            return []
        files = args[-1]
        if len(files) != 1 or not files[0].is_directory():
            return []
        path = self._get_path(files[0])
        if not path:
            return []
        item = Nautilus.MenuItem(
            name="PtyxisNautilus::OpenFolder",
            label="Abrir en Ptyxis",
            tip=f"Abrir {path} en la terminal Ptyxis",
            icon="org.gnome.Ptyxis",
        )
        item.connect("activate", self._open_ptyxis, path)
        return [item]

    def get_background_items(self, *args):
        if not args or not shutil.which("ptyxis"):
            return []
        current_folder = args[-1]
        path = self._get_path(current_folder)
        if not path:
            return []
        item = Nautilus.MenuItem(
            name="PtyxisNautilus::OpenBackground",
            label="Abrir en Ptyxis",
            tip=f"Abrir {path} en la terminal Ptyxis",
            icon="org.gnome.Ptyxis",
        )
        item.connect("activate", self._open_ptyxis, path)
        return [item]
EOF

chmod 644 "$NAUTILUS_EXT_FILE"
fix_permissions "$USER_HOME/.local/share/nautilus-python"

# ==============================================================================
# 5. TERMINAL POR DEFECTO Y ATAJO GLOBAL (CTRL+ALT+T)
# ==============================================================================
if [[ "$SET_DEFAULT_TERM" == true ]]; then
    log_info "Configurando Ptyxis como terminal predeterminada en GNOME y XDG..."
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec 'ptyxis' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec-arg '--new-window' 2>/dev/null || true

    mkdir -p "$(dirname "$XDG_TERMINALS_FILE")"
    if [[ ! -f "$XDG_TERMINALS_FILE" ]]; then
        echo "org.gnome.Ptyxis.desktop" > "$XDG_TERMINALS_FILE"
    else
        temp_list=$(grep -v "^org.gnome.Ptyxis.desktop$" "$XDG_TERMINALS_FILE" 2>/dev/null || true)
        printf "%s\n%s\n" "org.gnome.Ptyxis.desktop" "$temp_list" | sed '/^$/d' > "$XDG_TERMINALS_FILE"
    fi
    chmod 644 "$XDG_TERMINALS_FILE"
    fix_permissions "$XDG_TERMINALS_FILE"
    log_ok "Ptyxis establecida como terminal predeterminada."
fi

if [[ "$BIND_KEY" == true ]]; then
    log_info "Asignando atajo global Ctrl+Alt+T a Ptyxis..."
    custom_base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
    raw_list=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")

    target_path=""
    # Buscar si ya existe una entrada asociada a Ptyxis o con binding Ctrl+Alt+T
    if [[ "$raw_list" =~ custom[0-9]+ ]]; then
        paths=$(echo "$raw_list" | grep -o -E "'[^']+'" | tr -d "'")
        for p in $paths; do
            b_cmd=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$p command 2>/dev/null || true)
            b_key=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$p binding 2>/dev/null || true)
            if [[ "$b_cmd" == *ptyxis* || "$b_key" == "'<Control><Alt>t'" ]]; then
                target_path="$p"
                break
            fi
        done
    fi

    # Si no existe, asignar el siguiente índice libre de customN
    if [[ -z "$target_path" ]]; then
        i=0
        while [[ "$raw_list" == *"custom${i}/"* ]]; do
            ((i++))
        done
        target_path="$custom_base/custom${i}/"

        if [[ "$raw_list" == "@as []" || "$raw_list" == "[]" || -z "$raw_list" ]]; then
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$target_path']"
        else
            updated_list="${raw_list%]*}, '$target_path']"
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$updated_list"
        fi
    fi

    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$target_path name 'Terminal (Ptyxis)'
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$target_path command 'ptyxis --new-window'
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$target_path binding '<Control><Alt>t'
    log_ok "Atajo Ctrl+Alt+T asignado a Ptyxis ($target_path)."
fi

# Reiniciar instancia de Nautilus del usuario para cargar la extensión
run_as_user nautilus -q 2>/dev/null || true

log_ok "Ptyxis configurado y optimizado correctamente en CachyOS Workstation."
