#!/usr/bin/env bash
# ==============================================================================
#  apariencia.sh - Gestor de Temas, Iconos, Cursores y Fuentes en CachyOS Workstation
#  Sistema: CachyOS / Arch Linux (GNOME Shell Wayland + Pacman / Paru)
#  Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8)
#  Topología: Triple Monitor Full HD 1080p (DP-3, DP-4, eDP-1)
# ==============================================================================
#  Características:
#   - Homogeneización visual completa entre Libadwaita (GTK4), GTK3 y Flatpak.
#   - Modo oscuro nativo (prefer-dark) con adw-gtk3-dark para aplicaciones GTK3 heredadas.
#   - Tema de iconos Papirus-Dark / Papirus de alta definición y contraste.
#   - Sincronización automática de color de carpetas Papirus con el acento de GNOME.
#   - Cursores Bibata Modern (Classic e Ice) con tamaño consistente de 24px en multimonitor.
#   - Soporte nativo para los 9 Accent Colors de GNOME Shell 47+ / 51+ (blue, teal, green,
#     yellow, orange, red, pink, purple, slate).
#   - Optimización de renderizado tipográfico subpixel RGB (rgba + hintslight) para monitores 1080p.
#   - Sincronización de tipografía monoespacio (JetBrainsMono Nerd Font) con GNOME.
#   - Sincronización automática de ~/.config/gtk-3.0 y ~/.config/gtk-4.0 settings.ini.
#   - Sincronización de cursores Wayland/XWayland vía ~/.icons/default/index.theme,
#     ~/.config/environment.d/10-cursor.conf y ~/.Xresources.
#   - Inyección de permisos, variables de entorno y runtimes en Flatpak (overrides de usuario).
#   - Instalación segura vía Pacman/Chaotic-AUR/Paru con fallback local a GitHub Releases.
#   - Diagnóstico O(1) rápido e independiente de sudo (--status).
#   - Conforme a directrices: set -euo pipefail, Wayland nativo sin utilidades X11 heredadas.
# ==============================================================================

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y FORMATO VISUAL (ANSI)
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'
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

USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6 2>/dev/null || echo "${HOME:-/home/$REAL_USER}")
REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

if [[ $EUID -ne 0 ]]; then
    if command -v sudo &>/dev/null; then
        SUDO="sudo"
    else
        SUDO=""
    fi
else
    SUDO=""
fi

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
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    fi
}

fix_permissions() {
    local target_path="$1"
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" && -e "$target_path" ]]; then
        chown -R "$REAL_USER:$REAL_USER" "$target_path" 2>/dev/null || true
    fi
}

require_sudo() {
    if [[ $EUID -ne 0 && -z "$SUDO" ]]; then
        log_err "Esta operación requiere privilegios de superusuario (root o sudo)."
        exit 1
    fi
}

is_pkg_installed() {
    pacman -Q "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# 3. VALORES POR DEFECTO E INICIALIZACIÓN DE VARIABLES
# ------------------------------------------------------------------------------
ACTION="apply"
INTERACTIVE=false
DO_INSTALL=true
ONLY_INSTALL=false
MODE_COLOR="dark"
MODE_ACCENT="blue"
MODE_ICONS="Papirus-Dark"
MODE_CURSOR="Bibata-Modern-Classic"
CURSOR_SIZE="24"
OPTIMIZE_FONTS=true
SET_MONO_FONT=false
MONO_FONT_NAME="JetBrainsMono Nerd Font 10"
SYNC_FLATPAK=true

# ------------------------------------------------------------------------------
# 4. GESTIÓN DE CURSORES BIBATA MODERN
# ------------------------------------------------------------------------------
has_bibata_cursor() {
    local variant="$1"
    [[ -d "/usr/share/icons/$variant" || -d "$USER_HOME/.local/share/icons/$variant" || -d "$USER_HOME/.icons/$variant" ]]
}

install_bibata_cursors() {
    local variants=("Bibata-Modern-Classic" "Bibata-Modern-Ice")
    local needs_install=false

    for v in "${variants[@]}"; do
        if ! has_bibata_cursor "$v"; then
            needs_install=true
            break
        fi
    done

    if [[ "$needs_install" == false ]]; then
        log_ok "Cursores Bibata-Modern-Classic y Bibata-Modern-Ice ya están instalados."
        return 0
    fi

    log_info "Verificando disponibilidad de bibata-cursor-theme en repositorios..."

    # 1. Intentar instalar mediante pacman (chaotic-aur o repos oficiales) si tenemos sudo/root
    if is_pkg_installed "bibata-cursor-theme"; then
        log_ok "Paquete bibata-cursor-theme ya instalado en el sistema."
        return 0
    fi

    local installed_via_pkg=false
    if [[ -n "$SUDO" || $EUID -eq 0 ]]; then
        if $SUDO pacman -Si bibata-cursor-theme &>/dev/null; then
            log_info "Instalando bibata-cursor-theme desde repositorios CachyOS/Chaotic-AUR..."
            if $SUDO pacman -S --needed --noconfirm bibata-cursor-theme 2>/dev/null; then
                installed_via_pkg=true
                log_ok "bibata-cursor-theme instalado exitosamente con pacman."
            fi
        fi
    fi

    # 2. Si no se instaló con pacman, intentar con paru en espacio de usuario
    if [[ "$installed_via_pkg" == false ]] && command -v paru &>/dev/null; then
        log_info "Intentando instalar bibata-cursor-theme vía paru..."
        if run_as_user paru -S --needed --noconfirm bibata-cursor-theme 2>/dev/null; then
            installed_via_pkg=true
            log_ok "bibata-cursor-theme instalado exitosamente con paru."
        fi
    fi

    # 3. Fallback directo: descargar desde GitHub Releases al espacio de usuario o sistema
    if [[ "$installed_via_pkg" == false ]]; then
        log_info "Descargando cursores Bibata Modern desde GitHub Releases (fallback)..."
        local target_dir="$USER_HOME/.local/share/icons"
        if [[ -n "$SUDO" || $EUID -eq 0 ]]; then
            target_dir="/usr/share/icons"
        fi

        local tmp_dir
        tmp_dir=$(mktemp -d)

        for variant in "${variants[@]}"; do
            if ! has_bibata_cursor "$variant"; then
                local url="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/${variant}.tar.xz"
                log_info "Descargando $variant..."

                if curl -fsSL --connect-timeout 10 --max-time 60 "$url" -o "$tmp_dir/${variant}.tar.xz"; then
                    if [[ "$target_dir" == "/usr/share/icons" ]]; then
                        $SUDO mkdir -p "$target_dir"
                        $SUDO tar -xJf "$tmp_dir/${variant}.tar.xz" -C "$target_dir"
                        $SUDO chmod -R 755 "$target_dir/$variant" 2>/dev/null || true
                    else
                        mkdir -p "$target_dir"
                        tar -xJf "$tmp_dir/${variant}.tar.xz" -C "$target_dir"
                        chmod -R 755 "$target_dir/$variant" 2>/dev/null || true
                        fix_permissions "$target_dir"
                    fi
                    log_ok "Cursor $variant instalado exitosamente en $target_dir/$variant."
                else
                    log_warn "No se pudo descargar $variant (comprueba tu conexión a internet)."
                fi
            fi
        done
        rm -rf "$tmp_dir"
    fi
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN DE PAQUETES VISUALES EN CACHYOS
# ------------------------------------------------------------------------------
install_packages() {
    log_info "Verificando paquetes visuales en CachyOS (Pacman / AUR)..."
    local pkgs=(adw-gtk-theme papirus-icon-theme gnome-tweaks curl tar xz)
    local optional_pkgs=(bibata-cursor-theme papirus-folders)
    local missing=()

    for p in "${pkgs[@]}"; do
        if ! is_pkg_installed "$p"; then
            missing+=("$p")
        fi
    done

    # Agregar paquetes opcionales si están en repositorios y no están instalados
    for p in "${optional_pkgs[@]}"; do
        if ! is_pkg_installed "$p"; then
            if pacman -Si "$p" &>/dev/null; then
                missing+=("$p")
            fi
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        require_sudo
        log_info "Instalando paquetes faltantes (${missing[*]}):"
        if [[ -n "$SUDO" ]]; then
            $SUDO pacman -S --needed --noconfirm "${missing[@]}"
        else
            pacman -S --needed --noconfirm "${missing[@]}"
        fi
        log_ok "Paquetes visuales instalados con éxito."
    else
        log_ok "Paquetes visuales base ya están instalados."
    fi

    # Asegurar cursores Bibata
    install_bibata_cursors

    # Si Flatpak está instalado, asegurar los runtimes GTK3 de libadwaita para Flatpak
    if [[ "$SYNC_FLATPAK" == true ]] && command -v flatpak &>/dev/null; then
        if flatpak remotes 2>/dev/null | grep -q "flathub"; then
            local fp_runtimes=()
            if ! flatpak list --runtime 2>/dev/null | grep -q "org.gtk.Gtk3theme.adw-gtk3-dark"; then
                fp_runtimes+=("org.gtk.Gtk3theme.adw-gtk3-dark")
            fi
            if ! flatpak list --runtime 2>/dev/null | grep -q "org.gtk.Gtk3theme.adw-gtk3 "; then
                fp_runtimes+=("org.gtk.Gtk3theme.adw-gtk3")
            fi
            if [[ ${#fp_runtimes[@]} -gt 0 ]]; then
                log_info "Instalando runtimes Flatpak adw-gtk3 (${fp_runtimes[*]}) para consistencia visual..."
                run_as_user flatpak install -y --user flathub "${fp_runtimes[@]}" 2>/dev/null || true
            fi
        fi
    fi
}

# ------------------------------------------------------------------------------
# 6. SINCRONIZACIÓN DE COLOR DE CARPETAS PAPIRUS
# ------------------------------------------------------------------------------
sync_papirus_folders() {
    local accent="$1"
    if ! command -v papirus-folders &>/dev/null; then
        return 0
    fi

    local folder_color="blue"
    case "$accent" in
        teal)   folder_color="teal" ;;
        green)  folder_color="green" ;;
        yellow) folder_color="yellow" ;;
        orange) folder_color="orange" ;;
        red)    folder_color="red" ;;
        pink)   folder_color="magenta" ;;
        purple) folder_color="violet" ;;
        slate)  folder_color="grey" ;;
        *)      folder_color="blue" ;;
    esac

    log_info "Sincronizando color de carpetas Papirus a '$folder_color' (acento: $accent)..."
    if [[ -n "$SUDO" || $EUID -eq 0 ]]; then
        $SUDO papirus-folders -C "$folder_color" -t Papirus-Dark,Papirus 2>/dev/null || true
    else
        papirus-folders -C "$folder_color" -t Papirus-Dark,Papirus 2>/dev/null || true
    fi
    log_ok "Carpetas Papirus actualizadas a tono '$folder_color'."
}

# ------------------------------------------------------------------------------
# 7. DIAGNÓSTICO Y ESTADO DE APARIENCIA (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🎨 ${BOLD}${CYAN}ESTADO DE APARIENCIA Y TEMAS - CACHYOS WORKSTATION${NC}"
    echo -e "  💻 Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)"
    echo -e "  🖥️  Topología: Triple Monitor 1080p (DP-3, DP-4, eDP-1)"
    echo -e "${BOLD}======================================================================${NC}"

    local color_scheme gtk_theme icon_theme cursor_theme cursor_sz accent_color
    local font_hinting font_anti font_order font_name mono_name text_scale
    local gnome_ver session_type

    gnome_ver=$(gnome-shell --version 2>/dev/null || echo "GNOME Shell")
    session_type="${XDG_SESSION_TYPE:-wayland}"

    color_scheme=$(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "N/A")
    gtk_theme=$(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "N/A")
    icon_theme=$(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo "N/A")
    cursor_theme=$(run_as_user gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo "N/A")
    cursor_sz=$(run_as_user gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null || echo "N/A")
    accent_color=$(run_as_user gsettings get org.gnome.desktop.interface accent-color 2>/dev/null || echo "N/A")
    font_hinting=$(run_as_user gsettings get org.gnome.desktop.interface font-hinting 2>/dev/null || echo "N/A")
    font_anti=$(run_as_user gsettings get org.gnome.desktop.interface font-antialiasing 2>/dev/null || echo "N/A")
    font_order=$(run_as_user gsettings get org.gnome.desktop.interface font-rgba-order 2>/dev/null || echo "N/A")
    font_name=$(run_as_user gsettings get org.gnome.desktop.interface font-name 2>/dev/null || echo "N/A")
    mono_name=$(run_as_user gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || echo "N/A")
    text_scale=$(run_as_user gsettings get org.gnome.desktop.interface text-scaling-factor 2>/dev/null || echo "1.0")

    echo -e "  • Entorno de Escritorio:     ${CYAN}${gnome_ver}${NC} (${session_type})"
    echo -e "  • Esquema de color:          ${GREEN}${color_scheme}${NC}"
    echo -e "  • Color de Acento (GNOME):   ${CYAN}${accent_color}${NC}"
    echo -e "  • Tema GTK3 / Legacy:        ${CYAN}${gtk_theme}${NC}"
    echo -e "  • Tema de Iconos:            ${CYAN}${icon_theme}${NC}"
    echo -e "  • Tema de Cursor:            ${CYAN}${cursor_theme}${NC} (${cursor_sz}px)"
    echo -e "  • Tipografía de Sistema:     ${CYAN}${font_name}${NC}"
    echo -e "  • Tipografía Monoespacio:    ${CYAN}${mono_name}${NC}"
    echo -e "  • Renderizado Tipográfico:   Antialiasing: ${GREEN}${font_anti}${NC} | Hinting: ${GREEN}${font_hinting}${NC} | Subpixel: ${GREEN}${font_order}${NC} (Scale: ${text_scale})"

    echo -e "\n${BOLD}📦 Paquetes y Recursos Visuales:${NC}"
    for pkg in adw-gtk-theme papirus-icon-theme bibata-cursor-theme papirus-folders gnome-tweaks; do
        if is_pkg_installed "$pkg"; then
            printf "  • %-26s ${GREEN}✅ Instalado (pacman)${NC}\n" "$pkg"
        else
            printf "  • %-26s ${YELLOW}⚪ No instalado${NC}\n" "$pkg"
        fi
    done

    for cur in Bibata-Modern-Classic Bibata-Modern-Ice; do
        if [[ -d "/usr/share/icons/$cur" ]]; then
            printf "  • Cursor %-19s ${GREEN}✅ Instalado (/usr/share/icons)${NC}\n" "$cur"
        elif [[ -d "$USER_HOME/.local/share/icons/$cur" ]]; then
            printf "  • Cursor %-19s ${GREEN}✅ Instalado (~/.local/share/icons)${NC}\n" "$cur"
        else
            printf "  • Cursor %-19s ${YELLOW}⚪ No instalado${NC}\n" "$cur"
        fi
    done

    echo -e "\n${BOLD}📁 Sincronización GTK, Wayland/XWayland y Flatpak:${NC}"
    for cfg in "gtk-3.0/settings.ini" "gtk-4.0/settings.ini"; do
        if [[ -f "$USER_HOME/.config/$cfg" ]]; then
            echo -e "  • ~/.config/$cfg:  ${GREEN}✅ Presente${NC}"
        else
            echo -e "  • ~/.config/$cfg:  ${YELLOW}⚪ No configurado${NC}"
        fi
    done

    if [[ -f "$USER_HOME/.icons/default/index.theme" ]]; then
        local cur_inh
        cur_inh=$(grep -E '^Inherits=' "$USER_HOME/.icons/default/index.theme" 2>/dev/null | cut -d= -f2 || echo "N/A")
        echo -e "  • ~/.icons/default/index.theme:  ${GREEN}✅ Presente (Inherits=${cur_inh})${NC}"
    else
        echo -e "  • ~/.icons/default/index.theme:  ${YELLOW}⚪ No configurado${NC}"
    fi

    if [[ -f "$USER_HOME/.config/environment.d/10-cursor.conf" ]]; then
        echo -e "  • ~/.config/environment.d/10-cursor.conf: ${GREEN}✅ Sincronizado (systemd session)${NC}"
    else
        echo -e "  • ~/.config/environment.d/10-cursor.conf: ${YELLOW}⚪ No configurado${NC}"
    fi

    if [[ -f "$USER_HOME/.Xresources" ]]; then
        echo -e "  • ~/.Xresources (XWayland fallback):   ${GREEN}✅ Presente${NC}"
    else
        echo -e "  • ~/.Xresources (XWayland fallback):   ${YELLOW}⚪ No configurado${NC}"
    fi

    if command -v flatpak &>/dev/null; then
        local fp_ov
        fp_ov=$(run_as_user flatpak override --user --show 2>/dev/null | grep -E "GTK_THEME|XCURSOR" || true)
        if [[ -n "$fp_ov" ]]; then
            echo -e "  • Overrides de Flatpak:          ${GREEN}✅ Sincronizados${NC}"
        else
            echo -e "  • Overrides de Flatpak:          ${YELLOW}⚪ No configurados${NC}"
        fi

        local fp_adw
        fp_adw=$(flatpak list --runtime 2>/dev/null | grep -i "adw-gtk3" || true)
        if [[ -n "$fp_adw" ]]; then
            echo -e "  • Runtimes Flatpak adw-gtk3:     ${GREEN}✅ Instalados${NC}"
        else
            echo -e "  • Runtimes Flatpak adw-gtk3:     ${YELLOW}⚪ No instalados${NC}"
        fi
    fi

    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 8. ASISTENTE INTERACTIVO (-i, --interactive)
# ------------------------------------------------------------------------------
run_interactive() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🎨 ${BOLD}${CYAN}SELECTOR INTERACTIVO DE APARIENCIA - CACHYOS WORKSTATION${NC}"
    echo -e "  HP ProBook 455 G10 | AMD Ryzen 7 7730U | Triple Monitor 1080p"
    echo -e "${BOLD}======================================================================${NC}"

    echo -e "\n${BOLD}1) Esquema de Color:${NC}"
    echo "   1) Oscuro (prefer-dark + adw-gtk3-dark) [Recomendado]"
    echo "   2) Claro  (default + adw-gtk3)"
    read -rp "Opción [1]: " opt_color
    case "${opt_color:-1}" in
        2) MODE_COLOR="light" ;;
        *) MODE_COLOR="dark" ;;
    esac

    echo -e "\n${BOLD}2) Color de Acento de GNOME Shell (47+ / 51+):${NC}"
    echo "   1) Azul (blue) [Predeterminado GNOME / CachyOS]"
    echo "   2) Verde azulado (teal)"
    echo "   3) Verde (green)"
    echo "   4) Amarillo (yellow)"
    echo "   5) Naranja (orange)"
    echo "   6) Rojo (red)"
    echo "   7) Rosa (pink)"
    echo "   8) Púrpura (purple)"
    echo "   9) Pizarra / Gris neutro (slate)"
    read -rp "Opción [1]: " opt_accent
    case "${opt_accent:-1}" in
        2) MODE_ACCENT="teal" ;;
        3) MODE_ACCENT="green" ;;
        4) MODE_ACCENT="yellow" ;;
        5) MODE_ACCENT="orange" ;;
        6) MODE_ACCENT="red" ;;
        7) MODE_ACCENT="pink" ;;
        8) MODE_ACCENT="purple" ;;
        9) MODE_ACCENT="slate" ;;
        *) MODE_ACCENT="blue" ;;
    esac

    echo -e "\n${BOLD}3) Tema de Iconos:${NC}"
    echo "   1) Papirus-Dark [Recomendado para modo oscuro]"
    echo "   2) Papirus"
    echo "   3) Adwaita (Nativo GNOME)"
    read -rp "Opción [1]: " opt_icons
    case "${opt_icons:-1}" in
        2) MODE_ICONS="Papirus" ;;
        3) MODE_ICONS="Adwaita" ;;
        *) MODE_ICONS="Papirus-Dark" ;;
    esac

    echo -e "\n${BOLD}4) Tema de Cursor:${NC}"
    echo "   1) Bibata-Modern-Classic (Negro con borde blanco) [Recomendado]"
    echo "   2) Bibata-Modern-Ice (Blanco)"
    echo "   3) Adwaita (Nativo GNOME)"
    read -rp "Opción [1]: " opt_cursor
    case "${opt_cursor:-1}" in
        2) MODE_CURSOR="Bibata-Modern-Ice" ;;
        3) MODE_CURSOR="Adwaita" ;;
        *) MODE_CURSOR="Bibata-Modern-Classic" ;;
    esac

    echo -e "\n${BOLD}5) Tamaño del Cursor en píxeles (24 para Triple Monitor 1080p, 32, 48):${NC}"
    read -rp "Tamaño [24]: " opt_size
    CURSOR_SIZE="${opt_size:-24}"

    echo -e "\n${BOLD}6) Optimización de Renderizado Tipográfico para monitores 1080p:${NC}"
    echo "   Activar Subpixel RGB (rgba + hintslight) para nitidez máxima en texto LCD"
    echo "   1) Sí [Recomendado para Triple Monitor 1080p]"
    echo "   2) No (mantener estándar)"
    read -rp "Opción [1]: " opt_fonts
    case "${opt_fonts:-1}" in
        2) OPTIMIZE_FONTS=false ;;
        *) OPTIMIZE_FONTS=true ;;
    esac

    echo -e "\n${BOLD}7) Sincronizar Tipografía Monoespacio con JetBrainsMono Nerd Font:${NC}"
    if fc-list : family 2>/dev/null | grep -q "JetBrainsMono Nerd Font"; then
        echo "   1) Sí (JetBrainsMono Nerd Font 10) [Recomendado]"
        echo "   2) No (mantener actual)"
        read -rp "Opción [1]: " opt_mono
        case "${opt_mono:-1}" in
            2) SET_MONO_FONT=false ;;
            *) SET_MONO_FONT=true; MONO_FONT_NAME="JetBrainsMono Nerd Font 10" ;;
        esac
    else
        SET_MONO_FONT=false
        echo "   (JetBrainsMono Nerd Font no detectada; omitiendo)"
    fi
}

# ------------------------------------------------------------------------------
# 9. AYUDA CLI (-h, --help)
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}🎨 Gestor de Apariencia (Temas, Iconos, Cursores y Fuentes) - CachyOS Workstation${NC}
Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U + Triple Monitor FHD 1080p)

Instala paquetes visuales mediante Pacman/AUR (${BOLD}adw-gtk-theme${NC}, ${BOLD}papirus-icon-theme${NC},
${BOLD}bibata-cursor-theme${NC}, ${BOLD}papirus-folders${NC}) y aplica configuración unificada en GNOME
Wayland, GTK3, GTK4, Flatpak, systemd user session y XWayland.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones de Diagnóstico y Flujo:${NC}
  (sin argumentos)       Instala paquetes y aplica perfil óptimo (Dark + Papirus-Dark + Bibata Classic 24px + Subpixel RGB)
  -s, --status           Muestra el diagnóstico completo de apariencia, temas, iconos, cursor y fuentes
  -i, --interactive      Inicia el selector interactivo guiado
  --no-install, --config Aplica configuración en GSettings/GTK sin reinstalar paquetes ni descargas
  --install              Solo instala los paquetes y cursores sin alterar configuraciones
  -h, --help             Muestra esta ayuda

${BOLD}Personalización de Temas y Acentos:${NC}
  --dark                 Activa Modo Oscuro (prefer-dark + adw-gtk3-dark) [Por defecto]
  --light                Activa Modo Claro (default + adw-gtk3)
  --accent <color>       Color de acento GNOME (blue, teal, green, yellow, orange, red, pink, purple, slate)
  --papirus-dark         Usa iconos Papirus-Dark [Por defecto]
  --papirus              Usa iconos Papirus estándar
  --adwaita              Usa iconos nativos Adwaita
  --bibata               Usa cursor Bibata-Modern-Classic (Negro con borde blanco) [Por defecto]
  --bibata-ice           Usa cursor Bibata-Modern-Ice (Blanco)
  --adwaita-cursor       Usa cursor nativo Adwaita
  --cursor-size <px>     Define tamaño del cursor (predeterminado: 24 para triple monitor 1080p)

${BOLD}Opciones Avanzadas de Pantalla y Flatpak:${NC}
  --optimize-fonts       Aplica renderizado Subpixel RGB (rgba + hintslight) para monitores 1080p
  --no-optimize-fonts    Omite ajustes de renderizado de fuentes
  --font-mono <fuente>   Establece tipografía monoespacio (ej. 'JetBrainsMono Nerd Font 10')
  --no-flatpak           Omite sincronización de temas y variables en Flatpak
EOF
}

# ------------------------------------------------------------------------------
# 10. PARSER DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)           ACTION="status"; shift ;;
        -i|--interactive)      INTERACTIVE=true; shift ;;
        --no-install|--config) DO_INSTALL=false; shift ;;
        --install)             ONLY_INSTALL=true; shift ;;
        --dark)                MODE_COLOR="dark"; shift ;;
        --light)               MODE_COLOR="light"; shift ;;
        --accent)              MODE_ACCENT="${2:-blue}"; shift 2 ;;
        --papirus-dark)        MODE_ICONS="Papirus-Dark"; shift ;;
        --papirus)             MODE_ICONS="Papirus"; shift ;;
        --adwaita)             MODE_ICONS="Adwaita"; shift ;;
        --bibata)              MODE_CURSOR="Bibata-Modern-Classic"; shift ;;
        --bibata-ice)          MODE_CURSOR="Bibata-Modern-Ice"; shift ;;
        --adwaita-cursor)      MODE_CURSOR="Adwaita"; shift ;;
        --cursor-size)         CURSOR_SIZE="${2:-24}"; shift 2 ;;
        --optimize-fonts)      OPTIMIZE_FONTS=true; shift ;;
        --no-optimize-fonts)   OPTIMIZE_FONTS=false; shift ;;
        --font-mono)           SET_MONO_FONT=true; MONO_FONT_NAME="${2:-JetBrainsMono Nerd Font 10}"; shift 2 ;;
        --no-flatpak)          SYNC_FLATPAK=false; shift ;;
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

if [[ "$DO_INSTALL" == true ]]; then
    install_packages
fi

if [[ "$ONLY_INSTALL" == true ]]; then
    log_ok "Instalación de paquetes y cursores completada."
    exit 0
fi

# ------------------------------------------------------------------------------
# 11. APLICAR CONFIGURACIÓN EN GSETTINGS Y ENTORNO WAYLAND
# ------------------------------------------------------------------------------
if [[ "$MODE_COLOR" == "light" ]]; then
    COLOR_SCHEME_VAL="default"
    GTK_THEME_VAL="adw-gtk3"
    GTK_PREFER_DARK=0
else
    COLOR_SCHEME_VAL="prefer-dark"
    GTK_THEME_VAL="adw-gtk3-dark"
    GTK_PREFER_DARK=1
fi

log_info "Aplicando apariencia en GNOME Wayland ($COLOR_SCHEME_VAL | $GTK_THEME_VAL | $MODE_ICONS | $MODE_CURSOR ${CURSOR_SIZE}px)..."

# GSettings: Temas, Iconos y Cursor
run_as_user gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME_VAL"
run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_VAL"
run_as_user gsettings set org.gnome.desktop.interface icon-theme "$MODE_ICONS"
run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$MODE_CURSOR"
run_as_user gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"

# GSettings: Color de Acento (GNOME 47+ / 51+)
if run_as_user gsettings range org.gnome.desktop.interface accent-color &>/dev/null; then
    run_as_user gsettings set org.gnome.desktop.interface accent-color "$MODE_ACCENT"
    log_ok "Color de acento de GNOME Shell establecido en '$MODE_ACCENT'."
fi

# GSettings: Optimización de Renderizado Tipográfico para Triple Monitor 1080p
if [[ "$OPTIMIZE_FONTS" == true ]]; then
    log_info "Aplicando renderizado tipográfico Subpixel RGB para pantallas 1080p..."
    run_as_user gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
    run_as_user gsettings set org.gnome.desktop.interface font-hinting 'slight'
    run_as_user gsettings set org.gnome.desktop.interface font-rgba-order 'rgb'
    run_as_user gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
    log_ok "Renderizado de fuentes optimizado (RGBA Subpixel, Slight Hinting, Scale 1.0)."
fi

# GSettings: Tipografía Monoespacio
if [[ "$SET_MONO_FONT" == true ]]; then
    run_as_user gsettings set org.gnome.desktop.interface monospace-font-name "$MONO_FONT_NAME"
    log_ok "Tipografía monoespacio establecida en '$MONO_FONT_NAME'."
fi

# Sincronizar color de carpetas de Papirus con el acento si el tema es Papirus
if [[ "$MODE_ICONS" =~ ^Papirus ]]; then
    sync_papirus_folders "$MODE_ACCENT"
fi

# ------------------------------------------------------------------------------
# 12. ARCHIVOS DE CONFIGURACIÓN GTK, SYSTEMD Y XWAYLAND
# ------------------------------------------------------------------------------
log_info "Sincronizando configuraciones de GTK3, GTK4, systemd y XWayland..."

# Sincronizar archivos settings.ini de GTK 3.0 y GTK 4.0
for gtk_ver in gtk-3.0 gtk-4.0; do
    cfg_dir="$USER_HOME/.config/$gtk_ver"
    mkdir -p "$cfg_dir"
    cat << EOF > "$cfg_dir/settings.ini"
[Settings]
gtk-application-prefer-dark-theme=${GTK_PREFER_DARK}
gtk-theme-name=${GTK_THEME_VAL}
gtk-icon-theme-name=${MODE_ICONS}
gtk-cursor-theme-name=${MODE_CURSOR}
gtk-cursor-theme-size=${CURSOR_SIZE}
EOF
done

# Configurar índice de cursor de compatibilidad Wayland/XWayland en ~/.icons/default/index.theme
mkdir -p "$USER_HOME/.icons/default"
cat << EOF > "$USER_HOME/.icons/default/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=${MODE_CURSOR}
EOF

# Configurar variables de cursor en systemd user session (~/.config/environment.d/10-cursor.conf)
mkdir -p "$USER_HOME/.config/environment.d"
cat << EOF > "$USER_HOME/.config/environment.d/10-cursor.conf"
# Sincronización de cursor para sesión de usuario en CachyOS
XCURSOR_THEME=${MODE_CURSOR}
XCURSOR_SIZE=${CURSOR_SIZE}
EOF

# Configurar ~/.Xresources declarativo para aplicaciones XWayland
cat << EOF > "$USER_HOME/.Xresources"
! Configuración de cursor para compatibilidad XWayland en CachyOS Workstation
Xcursor.theme: ${MODE_CURSOR}
Xcursor.size: ${CURSOR_SIZE}
EOF

# Corregir permisos en caso de invocación con sudo
if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
    fix_permissions "$USER_HOME/.config/gtk-3.0"
    fix_permissions "$USER_HOME/.config/gtk-4.0"
    fix_permissions "$USER_HOME/.config/environment.d"
    fix_permissions "$USER_HOME/.icons"
    fix_permissions "$USER_HOME/.Xresources"
fi

# ------------------------------------------------------------------------------
# 13. SINCRONIZACIÓN CON FLATPAK
# ------------------------------------------------------------------------------
if [[ "$SYNC_FLATPAK" == true ]] && command -v flatpak &>/dev/null; then
    log_info "Sincronizando temas y directorios de iconos con Flatpak..."
    run_as_user flatpak override --user \
        --filesystem=xdg-config/gtk-3.0:ro \
        --filesystem=xdg-config/gtk-4.0:ro \
        --filesystem=/usr/share/icons:ro \
        --filesystem=xdg-data/icons:ro \
        --filesystem=/usr/share/themes:ro \
        --filesystem=xdg-data/themes:ro \
        2>/dev/null || true

    run_as_user flatpak override --user \
        --env=GTK_THEME="$GTK_THEME_VAL" \
        --env=XCURSOR_THEME="$MODE_CURSOR" \
        --env=XCURSOR_SIZE="$CURSOR_SIZE" \
        2>/dev/null || true
    log_ok "Overrides de usuario de Flatpak sincronizados correctamente."
fi

log_ok "Apariencia aplicada correctamente en CachyOS Workstation."
echo ""
show_status
