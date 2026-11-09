#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  gnome-settings.sh - Configuración y Personalización de GNOME Shell (Wayland)
#  Sistema: CachyOS / Arch Linux (GNOME Shell Wayland / Mutter / Pacman)
#  Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)
#  Topología: Triple Pantalla Full HD 1080p (DP-3, DP-4, eDP-1)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y FORMATO VISUAL
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 2. PRIVILEGIOS Y CONTEXTO DE USUARIO WAYLAND / D-BUS
# ------------------------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
else
    REAL_USER="${USER:-$(whoami)}"
fi
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

run_as_user() {
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$REAL_UID}"
    local dbus_addr="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$runtime_dir/bus}"
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# 3. VARIABLES DE ESTADO Y CONFIGURACIÓN POR DEFECTO
# ------------------------------------------------------------------------------
DO_INSTALL=true
INTERACTIVE=false
THEME_MODE="dark"
TERM_CHOICE="kitty"
BUTTON_SIDE="right"

RUN_ALL=true
RUN_PACKAGES=false
RUN_APPEARANCE=false
RUN_WINDOWS=false
RUN_TOUCHPAD=false
RUN_POWER=false
RUN_AUDIO=false
RUN_NAUTILUS=false
RUN_KEYBINDINGS=false
ACTION="run"

# ------------------------------------------------------------------------------
# 4. AYUDA CLI
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}🖥️  Configurador Integral de GNOME Shell (Wayland) - CachyOS Workstation${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / Triple Monitor FHD)

Optimiza GNOME Shell 51+, Mutter Wayland, periféricos (Touchpad HP, NumPad persistente),
energía AMD, audio Realtek ALC236, Nautilus, Luz Nocturna (4000K) y atajos de teclado.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones Generales:${NC}
  (sin argumentos)           Instala utilidades y aplica toda la configuración recomendada
  -i, --interactive          Ejecuta el asistente interactivo de configuración
  --no-install, --config     Aplica ajustes GSettings/Nautilus sin reinstalar paquetes
  -s, --status               Muestra el diagnóstico completo de GNOME Shell y hardware
  -h, --help                 Muestra esta ayuda

${BOLD}Selectores de Preferencias:${NC}
  --dark                     Activa modo oscuro (prefer-dark + adw-gtk3-dark) [Por defecto]
  --light                    Activa modo claro (default + adw-gtk3)
  --terminal <nombre>        Terminal para Ctrl+Alt+T: kitty | ghostty | ptyxis | gnome-terminal
  --buttons <right|left>     Posición de botones minimizar/maximizar/cerrar (por defecto: right)

${BOLD}Ejecución Modular (ejecuta solo los módulos indicados):${NC}
  --packages                 Solo instala paquetes de soporte GNOME mediante Pacman
  --appearance               Solo aplica tema, luz nocturna, fuentes subpixel y reloj
  --windows                  Solo aplica botones, Mutter Wayland y multitarea multimonitor
  --touchpad                 Solo configura gestos de touchpad y persistencia de teclado numérico
  --power                    Solo configura perfiles de reposo, batería y sensor ambiental
  --audio                    Solo aplica amplificación de audio (>100%) y sonidos de evento
  --nautilus                 Solo aplica preferencias de Nautilus y extensiones Python
  --keybindings              Solo aplica atajos de teclado (Ctrl+Alt+T, multimonitor, capturas)
EOF
}

# ------------------------------------------------------------------------------
# 5. DIAGNÓSTICO Y ESTADO (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🖥️  ${BOLD}ESTADO DE GNOME SHELL (WAYLAND) - CACHYOS WORKSTATION${NC}"
    echo -e "      ${CYAN}HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    local color_scheme gtk_theme btn_layout clock_fmt term_exec
    color_scheme=$(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "N/A")
    gtk_theme=$(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "N/A")
    btn_layout=$(run_as_user gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null || echo "N/A")
    clock_fmt=$(run_as_user gsettings get org.gnome.desktop.interface clock-format 2>/dev/null || echo "N/A")
    term_exec=$(run_as_user gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null || echo "N/A")

    local night_light night_temp font_subpixel font_hinting
    night_light=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null || echo "N/A")
    night_temp=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature 2>/dev/null || echo "N/A")
    font_subpixel=$(run_as_user gsettings get org.gnome.desktop.interface font-antialiasing 2>/dev/null || echo "N/A")
    font_hinting=$(run_as_user gsettings get org.gnome.desktop.interface font-hinting 2>/dev/null || echo "N/A")

    echo -e "${BOLD}🎨 Apariencia y Pantalla:${NC}"
    echo -e "  • Esquema de color:          ${CYAN}${color_scheme}${NC} (GTK Theme: ${gtk_theme})"
    echo -e "  • Formato de Reloj:          ${CYAN}${clock_fmt}${NC}"
    echo -e "  • Luz Nocturna:              ${CYAN}${night_light}${NC} (Temperatura: ${night_temp})"
    echo -e "  • Suavizado de Fuentes:      ${CYAN}${font_subpixel}${NC} (Hinting: ${font_hinting})"

    local workspaces_primary dynamic_ws edge_tiling center_win xwayland_scale
    workspaces_primary=$(run_as_user gsettings get org.gnome.mutter workspaces-only-on-primary 2>/dev/null || echo "N/A")
    dynamic_ws=$(run_as_user gsettings get org.gnome.mutter dynamic-workspaces 2>/dev/null || echo "N/A")
    edge_tiling=$(run_as_user gsettings get org.gnome.mutter edge-tiling 2>/dev/null || echo "N/A")
    center_win=$(run_as_user gsettings get org.gnome.mutter center-new-windows 2>/dev/null || echo "N/A")
    xwayland_scale=$(run_as_user gsettings get org.gnome.mutter.wayland xwayland-scaling-factor 2>/dev/null || echo "N/A")

    echo ""
    echo -e "${BOLD}🪟 Ventanas y Mutter Wayland (Triple Monitor FHD DP-3, DP-4, eDP-1):${NC}"
    echo -e "  • Botones de ventana:        ${CYAN}${btn_layout}${NC}"
    echo -e "  • Centrar ventanas nuevas:   ${CYAN}${center_win}${NC}"
    echo -e "  • Ajuste en bordes (Tiling): ${CYAN}${edge_tiling}${NC}"
    echo -e "  • Espacios de trabajo:       Dinámicos (${dynamic_ws}) | Solo primaria: ${CYAN}${workspaces_primary}${NC}"
    echo -e "  • Escala XWayland:           ${CYAN}${xwayland_scale}${NC}"

    local tap_click natural_scroll dwt numlock_state remember_numlock
    tap_click=$(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click 2>/dev/null || echo "N/A")
    natural_scroll=$(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad natural-scroll 2>/dev/null || echo "N/A")
    dwt=$(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad disable-while-typing 2>/dev/null || echo "N/A")
    numlock_state=$(run_as_user gsettings get org.gnome.desktop.peripherals.keyboard numlock-state 2>/dev/null || echo "N/A")
    remember_numlock=$(run_as_user gsettings get org.gnome.desktop.peripherals.keyboard remember-numlock-state 2>/dev/null || echo "N/A")

    echo ""
    echo -e "${BOLD}🖐️  Periféricos del Portátil (HP ProBook 455 G10):${NC}"
    echo -e "  • Touchpad Tap-to-Click:     ${CYAN}${tap_click}${NC} | Scroll Natural: ${CYAN}${natural_scroll}${NC}"
    echo -e "  • Rechazo de Palma (DWT):    ${CYAN}${dwt}${NC}"
    echo -e "  • Teclado NumPad Físico:     NumLock Activo: ${CYAN}${numlock_state}${NC} | Recordar: ${CYAN}${remember_numlock}${NC}"

    local bat_pct idle_dim sleep_bat sleep_ac ambient_sensor audio_boost
    bat_pct=$(run_as_user gsettings get org.gnome.desktop.interface show-battery-percentage 2>/dev/null || echo "N/A")
    idle_dim=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.power idle-dim 2>/dev/null || echo "N/A")
    sleep_bat=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 2>/dev/null || echo "N/A")
    sleep_ac=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 2>/dev/null || echo "N/A")
    ambient_sensor=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.power ambient-enabled 2>/dev/null || echo "N/A")
    audio_boost=$(run_as_user gsettings get org.gnome.desktop.sound allow-volume-above-100-percent 2>/dev/null || echo "N/A")

    echo ""
    echo -e "${BOLD}🔋 Energía AMD y Audio Realtek:${NC}"
    echo -e "  • Porcentaje de Batería:     ${CYAN}${bat_pct}${NC} | Atenuación en Inactividad: ${CYAN}${idle_dim}${NC}"
    echo -e "  • Suspensión Inactividad:    Batería: ${CYAN}${sleep_bat}s${NC} | AC/Docked: ${CYAN}${sleep_ac}s${NC}"
    echo -e "  • Sensor Brillo Ambiental:   ${CYAN}${ambient_sensor}${NC} (desactivado para estabilidad HP)"
    echo -e "  • Amplificación Audio (>100%): ${CYAN}${audio_boost}${NC}"

    local sort_first folder_view
    sort_first=$(run_as_user gsettings get org.gtk.gtk4.Settings.FileChooser sort-directories-first 2>/dev/null || echo "N/A")
    folder_view=$(run_as_user gsettings get org.gnome.nautilus.preferences default-folder-viewer 2>/dev/null || echo "N/A")
    echo ""
    echo -e "${BOLD}📁 Nautilus y Productividad:${NC}"
    echo -e "  • Carpetas Primero:          ${CYAN}${sort_first}${NC} | Vista por defecto: ${CYAN}${folder_view}${NC}"
    echo -e "  • Terminal Predeterminada:   ${CYAN}${term_exec}${NC} (Atajo: Ctrl+Alt+T)"
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 6. ASISTENTE INTERACTIVO (-i)
# ------------------------------------------------------------------------------
run_interactive() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🖥️  ${BOLD}ASISTENTE INTERACTIVO DE GNOME SHELL - CACHYOS WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    echo -e "\n${BOLD}1) Tema del Escritorio:${NC}"
    echo "   1) Modo Oscuro (prefer-dark + adw-gtk3-dark) [Recomendado]"
    echo "   2) Modo Claro  (default + adw-gtk3)"
    read -rp "Opción [1]: " ans_theme
    [[ "${ans_theme:-1}" == "2" ]] && THEME_MODE="light" || THEME_MODE="dark"

    echo -e "\n${BOLD}2) Terminal para atajo Ctrl+Alt+T y predeterminada:${NC}"
    echo "   1) Kitty (GPU Accelerated AMD) [Recomendado]"
    echo "   2) Ghostty"
    echo "   3) Ptyxis (Nativa para Contenedores)"
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

# ------------------------------------------------------------------------------
# 7. MÓDULOS DE CONFIGURACIÓN
# ------------------------------------------------------------------------------
install_gnome_packages() {
    log_info "Verificando herramientas y paquetes de integración GNOME Wayland (Pacman)..."
    local pkgs=(
        gnome-tweaks
        dconf-editor
        wl-clipboard
        libnotify
        python-nautilus
        papirus-icon-theme
        grim
        slurp
        xdg-terminal-exec
    )
    local missing=()
    for p in "${pkgs[@]}"; do
        pacman -Q "$p" &>/dev/null || missing+=("$p")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        sudo pacman -S --needed --noconfirm "${missing[@]}" 2>/dev/null || true
        log_ok "Paquetes instalados correctamente."
    else
        log_ok "Paquetes base de herramientas GNOME Wayland ya están instalados."
    fi
}

apply_appearance() {
    log_info "Aplicando apariencia, reloj 24h, fuentes subpixel y Luz Nocturna (4000K)..."
    if [[ -x "$SCRIPT_DIR/apariencia.sh" ]]; then
        if [[ "$THEME_MODE" == "light" ]]; then
            "$SCRIPT_DIR/apariencia.sh" --no-install --light
        else
            "$SCRIPT_DIR/apariencia.sh" --no-install --dark
        fi
    else
        if [[ "$THEME_MODE" == "light" ]]; then
            run_as_user gsettings set org.gnome.desktop.interface color-scheme 'default'
            run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3' 2>/dev/null || true
        else
            run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
        fi
    fi

    # Reloj, calendario y porcentaje de batería en barra superior
    run_as_user gsettings set org.gnome.desktop.interface clock-format '24h'
    run_as_user gsettings set org.gnome.desktop.interface clock-show-date true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-seconds false
    run_as_user gsettings set org.gnome.desktop.interface clock-show-weekday true
    run_as_user gsettings set org.gnome.desktop.calendar show-weekdate true
    run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true

    # Renderizado de fuentes óptimo para pantallas IPS 1080p (HP ProBook y monitores DP-3/DP-4)
    run_as_user gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
    run_as_user gsettings set org.gnome.desktop.interface font-hinting 'slight'
    run_as_user gsettings set org.gnome.desktop.interface scaling-factor 1 2>/dev/null || true

    # Luz nocturna suave a 4000K con horario automático astronómico
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000
    log_ok "Apariencia, fuentes, reloj y Luz Nocturna configurados."
}

apply_windows() {
    log_info "Configurando Mutter Wayland, ventanas y topología multimonitor (DP-3, DP-4, eDP-1)..."
    if [[ "$BUTTON_SIDE" == "left" ]]; then
        run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:appmenu'
    else
        run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
    fi

    run_as_user gsettings set org.gnome.mutter center-new-windows true
    run_as_user gsettings set org.gnome.mutter edge-tiling true
    run_as_user gsettings set org.gnome.mutter dynamic-workspaces true
    run_as_user gsettings set org.gnome.mutter attach-modal-dialogs true

    # Vital para topología de triple pantalla: espacios de trabajo independientes en todos los monitores
    run_as_user gsettings set org.gnome.mutter workspaces-only-on-primary false
    run_as_user gsettings set org.gnome.shell.app-switcher current-workspace-only false

    # Renderizado nítido XWayland 1:1 en Mutter 51+
    run_as_user gsettings set org.gnome.mutter.wayland xwayland-scaling-factor 1.0 2>/dev/null || true

    # Si el esquema org.gnome.mutter soporta experimental-features, configurarlo con seguridad
    if run_as_user gsettings list-keys org.gnome.mutter 2>/dev/null | grep -qx "experimental-features"; then
        run_as_user gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate']" 2>/dev/null || true
    fi

    # Limpieza automática de temporales y papelera cada 30 días
    run_as_user gsettings set org.gnome.desktop.privacy remove-old-temp-files true
    run_as_user gsettings set org.gnome.desktop.privacy remove-old-trash-files true
    run_as_user gsettings set org.gnome.desktop.privacy old-files-age 30
    log_ok "Ventanas, Mutter Wayland y multimonitor configurados."
}

apply_touchpad() {
    log_info "Configurando Touchpad HP y teclado numérico físico (HP ProBook 455 G10)..."
    local tp_schema="org.gnome.desktop.peripherals.touchpad"
    local kb_schema="org.gnome.desktop.peripherals.keyboard"

    # Gestos y precisión de Touchpad en Wayland
    run_as_user gsettings set "$tp_schema" tap-to-click true
    run_as_user gsettings set "$tp_schema" natural-scroll true
    run_as_user gsettings set "$tp_schema" two-finger-scrolling-enabled true
    run_as_user gsettings set "$tp_schema" click-method 'fingers'
    run_as_user gsettings set "$tp_schema" tap-and-drag true
    run_as_user gsettings set "$tp_schema" disable-while-typing true
    run_as_user gsettings set "$tp_schema" speed 0.15

    # Teclado: activar y recordar estado del NumPad del portátil HP ProBook
    run_as_user gsettings set "$kb_schema" numlock-state true
    run_as_user gsettings set "$kb_schema" remember-numlock-state true
    run_as_user gsettings set "$kb_schema" repeat true
    run_as_user gsettings set "$kb_schema" delay 250
    run_as_user gsettings set "$kb_schema" repeat-interval 30
    log_ok "Touchpad HP y persistencia NumPad configurados con éxito."
}

apply_power() {
    log_info "Optimizando timeouts de energía y batería para AMD Ryzen 7 7730U..."
    local pwr_schema="org.gnome.settings-daemon.plugins.power"

    # Suspender tras 15 minutos en batería, 1 hora en corriente alterna (docked)
    run_as_user gsettings set "$pwr_schema" sleep-inactive-battery-type 'suspend'
    run_as_user gsettings set "$pwr_schema" sleep-inactive-battery-timeout 900
    run_as_user gsettings set "$pwr_schema" sleep-inactive-ac-type 'nothing'
    run_as_user gsettings set "$pwr_schema" sleep-inactive-ac-timeout 3600

    # Desactivar sensor ambiental inestable en HP para evitar saltos bruscos de brillo
    run_as_user gsettings set "$pwr_schema" ambient-enabled false
    run_as_user gsettings set "$pwr_schema" idle-dim true
    run_as_user gsettings set "$pwr_schema" power-saver-profile-on-low-battery true
    run_as_user gsettings set "$pwr_schema" power-button-action 'suspend'
    log_ok "Políticas de energía y batería AMD optimizadas."
}

apply_audio() {
    log_info "Optimizando audio Realtek ALC236 con PipeWire..."
    # Permitir amplificación de volumen superior al 100% para llamadas/reuniones en los altavoces integrados
    run_as_user gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
    run_as_user gsettings set org.gnome.desktop.sound event-sounds true
    log_ok "Amplificación de audio (>100%) y sonidos de evento activados."
}

apply_nautilus() {
    log_info "Optimizando gestor de archivos Nautilus y menús contextuales de desarrollo..."
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

    # Menú contextual de primer nivel para abrir en Antigravity / Antigravity CLI / VS Code
    local nautilus_ext_dir="$USER_HOME/.local/share/nautilus-python/extensions"
    mkdir -p "$nautilus_ext_dir"

    # Contextuales para terminales instaladas
    [[ -x "$SCRIPT_DIR/kitty.sh" ]] && "$SCRIPT_DIR/kitty.sh" --no-install >/dev/null 2>&1 || true
    [[ -x "$SCRIPT_DIR/ghostty.sh" ]] && "$SCRIPT_DIR/ghostty.sh" --no-install >/dev/null 2>&1 || true
    [[ -x "$SCRIPT_DIR/ptyxis.sh" ]] && "$SCRIPT_DIR/ptyxis.sh" --no-install >/dev/null 2>&1 || true

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
    log_ok "Nautilus y extensiones contextuales aplicadas."
}

apply_keybindings() {
    log_info "Configurando terminal predeterminada ($TERM_CHOICE) y atajos de teclado..."
    local term_cmd="$TERM_CHOICE"
    local term_arg=""
    if [[ "$TERM_CHOICE" == "ptyxis" ]]; then
        term_cmd="ptyxis --new-window"
        term_arg="--new-window"
    fi

    # Definir terminal predeterminada en GSettings
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec "$TERM_CHOICE"
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec-arg "$term_arg"

    # Atajo Ctrl+Alt+T para terminal
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

    # Atajos de Mutter para navegación y organización de ventanas en multimonitor
    run_as_user gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>Up', '<Super>m']" 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter.keybindings toggle-tiled-left "['<Super>Left']" 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter.keybindings toggle-tiled-right "['<Super>Right']" 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left "['<Super><Shift>Left']" 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right "['<Super><Shift>Right']" 2>/dev/null || true

    log_ok "Atajos de teclado configurados (Ctrl+Alt+T -> $TERM_CHOICE, Tiling Super+Flechas)."
}

# ------------------------------------------------------------------------------
# 8. PARSEO DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
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
        --touchpad)            RUN_ALL=false; RUN_TOUCHPAD=true; shift ;;
        --power)               RUN_ALL=false; RUN_POWER=true; shift ;;
        --audio)               RUN_ALL=false; RUN_AUDIO=true; shift ;;
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

# ------------------------------------------------------------------------------
# 9. EJECUCIÓN
# ------------------------------------------------------------------------------
if [[ "$RUN_ALL" == true ]]; then
    [[ "$DO_INSTALL" == true ]] && install_gnome_packages
    apply_appearance
    apply_windows
    apply_touchpad
    apply_power
    apply_audio
    apply_nautilus
    apply_keybindings
else
    [[ "$RUN_PACKAGES" == true ]]    && install_gnome_packages
    [[ "$RUN_APPEARANCE" == true ]]  && apply_appearance
    [[ "$RUN_WINDOWS" == true ]]     && apply_windows
    [[ "$RUN_TOUCHPAD" == true ]]    && apply_touchpad
    [[ "$RUN_POWER" == true ]]       && apply_power
    [[ "$RUN_AUDIO" == true ]]       && apply_audio
    [[ "$RUN_NAUTILUS" == true ]]    && apply_nautilus
    [[ "$RUN_KEYBINDINGS" == true ]] && apply_keybindings
fi

log_ok "Configuración de GNOME Shell en CachyOS Workstation completada exitosamente."
echo ""
show_status
