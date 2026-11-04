#!/usr/bin/env bash
# ==============================================================================
#  apariencia.sh - Gestor de Temas, Iconos y Cursores en Fedora 45 Workstation
#  Sistema: Fedora 45 Workstation (GNOME Shell Wayland + DNF5)
#  Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics)
#  Topología: Triple Monitor 1080p (DP-3, DP-4, eDP-1)
# ==============================================================================
#  Características:
#   - Homogeneización visual completa entre Libadwaita (GTK4), GTK3 y Flatpak.
#   - Modo oscuro nativo (prefer-dark) con adw-gtk3-dark para apps GTK3 legacy.
#   - Tema de iconos Papirus-Dark / Papirus de alta definición y contraste.
#   - Cursores Bibata Modern (Classic e Ice) con tamaño consistente de 24px en multimonitor.
#   - Soporte nativo para Accent Colors de GNOME Shell 47+ (blue, teal, green, etc.).
#   - Sincronización automática de ~/.config/gtk-3.0 y ~/.config/gtk-4.0 settings.ini.
#   - Configuración de índice de cursor para XWayland (~/.icons/default/index.theme).
#   - Inyección de permisos y variables de entorno en Flatpak (overrides de usuario).
#   - Instalación segura tanto a nivel de sistema (/usr/share/icons) como local (~/.local/share/icons).
#   - Diagnóstico O(1) rápido e independiente de sudo (--status).
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

require_sudo() {
    if [[ $EUID -ne 0 && -z "$SUDO" ]]; then
        log_err "Esta operación requiere privilegios de superusuario (root o sudo)."
        exit 1
    fi
}

DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"

# ------------------------------------------------------------------------------
# 3. VALORES PREDETERMINADOS DE CONFIGURACIÓN
# ------------------------------------------------------------------------------
MODE_COLOR="dark"
MODE_ACCENT="blue"
MODE_ICONS="Papirus-Dark"
MODE_CURSOR="Bibata-Modern-Classic"
CURSOR_SIZE=24

DO_INSTALL=true
ONLY_INSTALL=false
INTERACTIVE=false
ACTION="apply"

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN IDEMPOTENTE DE PAQUETES (DNF5 + CURSORES BIBATA)
# ------------------------------------------------------------------------------
is_pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

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

    log_info "Instalando cursores Bibata Modern (Classic e Ice)..."

    # Seleccionar destino: /usr/share/icons si hay sudo/root; de lo contrario ~/.local/share/icons
    local target_dir="/usr/share/icons"
    local use_sudo=false

    if [[ $EUID -eq 0 ]]; then
        target_dir="/usr/share/icons"
    elif [[ -n "$SUDO" ]]; then
        target_dir="/usr/share/icons"
        use_sudo=true
    else
        target_dir="$USER_HOME/.local/share/icons"
        mkdir -p "$target_dir"
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)

    for variant in "${variants[@]}"; do
        if ! has_bibata_cursor "$variant"; then
            local url="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/${variant}.tar.xz"
            log_info "Descargando $variant desde GitHub Releases..."

            if curl -fsSL --connect-timeout 10 --max-time 60 "$url" -o "$tmp_dir/${variant}.tar.xz"; then
                if [[ "$use_sudo" == true ]]; then
                    $SUDO mkdir -p "$target_dir"
                    $SUDO tar -xJf "$tmp_dir/${variant}.tar.xz" -C "$target_dir"
                    $SUDO chmod -R 755 "$target_dir/$variant" 2>/dev/null || true
                elif [[ $EUID -eq 0 ]]; then
                    mkdir -p "$target_dir"
                    tar -xJf "$tmp_dir/${variant}.tar.xz" -C "$target_dir"
                    chmod -R 755 "$target_dir/$variant" 2>/dev/null || true
                else
                    mkdir -p "$target_dir"
                    tar -xJf "$tmp_dir/${variant}.tar.xz" -C "$target_dir"
                    chmod -R 755 "$target_dir/$variant" 2>/dev/null || true
                fi
                log_ok "Cursor $variant instalado exitosamente en $target_dir/$variant."
            else
                log_warn "No se pudo descargar $variant (comprueba tu conexión a internet)."
            fi
        fi
    done

    rm -rf "$tmp_dir"
}

install_packages() {
    log_info "Verificando paquetes visuales en Fedora 45 vía DNF5..."
    local pkgs=(adw-gtk3-theme papirus-icon-theme gnome-tweaks curl tar xz)
    local missing=()

    for p in "${pkgs[@]}"; do
        if ! is_pkg_installed "$p"; then
            missing+=("$p")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        require_sudo
        log_info "Instalando paquetes faltantes (${missing[*]}):"
        if [[ -n "$SUDO" ]]; then
            $SUDO "$DNF_BIN" install -y "${missing[@]}"
        else
            "$DNF_BIN" install -y "${missing[@]}"
        fi
        log_ok "Paquetes visuales instalados con éxito."
    else
        log_ok "Paquetes adw-gtk3-theme, papirus-icon-theme y gnome-tweaks ya instalados."
    fi

    install_bibata_cursors
}

# ------------------------------------------------------------------------------
# 5. DIAGNÓSTICO Y ESTADO DE APARIENCIA (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🎨 ${BOLD}${CYAN}ESTADO DE APARIENCIA Y TEMAS - FEDORA 45 WORKSTATION${NC}"
    echo -e "  💻 Hardware: HP ProBook 455 G10 | Triple Monitor 1080p (DP-3, DP-4, eDP-1)"
    echo -e "${BOLD}======================================================================${NC}"

    local color_scheme gtk_theme icon_theme cursor_theme cursor_sz accent_color font_hinting font_anti font_name mono_name
    color_scheme=$(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "N/A")
    gtk_theme=$(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "N/A")
    icon_theme=$(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo "N/A")
    cursor_theme=$(run_as_user gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo "N/A")
    cursor_sz=$(run_as_user gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null || echo "N/A")
    accent_color=$(run_as_user gsettings get org.gnome.desktop.interface accent-color 2>/dev/null || echo "N/A")
    font_hinting=$(run_as_user gsettings get org.gnome.desktop.interface font-hinting 2>/dev/null || echo "N/A")
    font_anti=$(run_as_user gsettings get org.gnome.desktop.interface font-antialiasing 2>/dev/null || echo "N/A")
    font_name=$(run_as_user gsettings get org.gnome.desktop.interface font-name 2>/dev/null || echo "N/A")
    mono_name=$(run_as_user gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || echo "N/A")

    echo -e "  • Esquema de color:          ${GREEN}${color_scheme}${NC}"
    echo -e "  • Color de Acento (GNOME):   ${CYAN}${accent_color}${NC}"
    echo -e "  • Tema GTK3 / Legacy:        ${CYAN}${gtk_theme}${NC}"
    echo -e "  • Tema de Iconos:            ${CYAN}${icon_theme}${NC}"
    echo -e "  • Tema de Cursor:            ${CYAN}${cursor_theme}${NC} (${cursor_sz}px)"
    echo -e "  • Tipografía de Sistema:     ${CYAN}${font_name}${NC} (Antialiasing: ${font_anti}, Hinting: ${font_hinting})"
    echo -e "  • Tipografía Monoespacio:    ${CYAN}${mono_name}${NC}"

    echo -e "\n${BOLD}📦 Paquetes y Recursos Instalados (DNF5 / Local):${NC}"
    for pkg in adw-gtk3-theme papirus-icon-theme gnome-tweaks; do
        if is_pkg_installed "$pkg"; then
            printf "  • %-26s ${GREEN}✅ Instalado (RPM)${NC}\n" "$pkg"
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

    echo -e "\n${BOLD}📁 Archivos de Sincronización GTK y Cursor:${NC}"
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

    if command -v flatpak &>/dev/null; then
        local fp_ov
        fp_ov=$(run_as_user flatpak override --user --show 2>/dev/null | grep "GTK_THEME" || true)
        if [[ -n "$fp_ov" ]]; then
            echo -e "  • Overrides de Flatpak:          ${GREEN}✅ Integrados${NC}"
        else
            echo -e "  • Overrides de Flatpak:          ${YELLOW}⚪ No sincronizados${NC}"
        fi
    fi

    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 6. ASISTENTE INTERACTIVO (-i, --interactive)
# ------------------------------------------------------------------------------
run_interactive() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🎨 ${BOLD}SELECTOR INTERACTIVO DE APARIENCIA - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    echo -e "\n${BOLD}1) Selecciona el Esquema de Color:${NC}"
    echo "   1) Oscuro (prefer-dark + adw-gtk3-dark) [Recomendado]"
    echo "   2) Claro  (default + adw-gtk3)"
    read -rp "Opción [1]: " opt_color
    case "${opt_color:-1}" in
        2) MODE_COLOR="light" ;;
        *) MODE_COLOR="dark" ;;
    esac

    echo -e "\n${BOLD}2) Color de Acento de GNOME Shell 47+:${NC}"
    echo "   1) Azul (blue) [Recomendado Fedora]"
    echo "   2) Verde azulado (teal)"
    echo "   3) Verde (green)"
    echo "   4) Amarillo (yellow)"
    echo "   5) Naranja (orange)"
    echo "   6) Rojo (red)"
    echo "   7) Púrpura (purple)"
    echo "   8) Pizarra / Gris neutro (slate)"
    read -rp "Opción [1]: " opt_accent
    case "${opt_accent:-1}" in
        2) MODE_ACCENT="teal" ;;
        3) MODE_ACCENT="green" ;;
        4) MODE_ACCENT="yellow" ;;
        5) MODE_ACCENT="orange" ;;
        6) MODE_ACCENT="red" ;;
        7) MODE_ACCENT="purple" ;;
        8) MODE_ACCENT="slate" ;;
        *) MODE_ACCENT="blue" ;;
    esac

    echo -e "\n${BOLD}3) Selecciona el Tema de Iconos:${NC}"
    echo "   1) Papirus-Dark [Recomendado para modo oscuro]"
    echo "   2) Papirus"
    echo "   3) Adwaita (Nativo GNOME)"
    read -rp "Opción [1]: " opt_icons
    case "${opt_icons:-1}" in
        2) MODE_ICONS="Papirus" ;;
        3) MODE_ICONS="Adwaita" ;;
        *) MODE_ICONS="Papirus-Dark" ;;
    esac

    echo -e "\n${BOLD}4) Selecciona el Tema de Cursor:${NC}"
    echo "   1) Bibata-Modern-Classic (Negro con borde blanco) [Recomendado]"
    echo "   2) Bibata-Modern-Ice (Blanco)"
    echo "   3) Adwaita (Nativo GNOME)"
    read -rp "Opción [1]: " opt_cursor
    case "${opt_cursor:-1}" in
        2) MODE_CURSOR="Bibata-Modern-Ice" ;;
        3) MODE_CURSOR="Adwaita" ;;
        *) MODE_CURSOR="Bibata-Modern-Classic" ;;
    esac

    echo -e "\n${BOLD}5) Tamaño del Cursor en píxeles (24 para 1080p, 32, 48):${NC}"
    read -rp "Tamaño [24]: " opt_size
    CURSOR_SIZE="${opt_size:-24}"
}

# ------------------------------------------------------------------------------
# 7. AYUDA CLI
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}🎨 Gestor de Apariencia (Temas, Iconos y Cursores) - Fedora 45 Workstation${NC}
Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U + Triple Monitor FHD)

Instala paquetes visuales mediante DNF5 (${BOLD}adw-gtk3-theme${NC}, ${BOLD}papirus-icon-theme${NC}) y el
cursor ${BOLD}Bibata Modern${NC} (Classic e Ice), aplicando la configuración en GNOME Wayland
y sincronizando GTK3, GTK4 y Flatpak.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones de Diagnóstico y Flujo:${NC}
  (sin argumentos)       Instala temas y aplica perfil predeterminado (Dark + Papirus-Dark + Bibata Classic 24px)
  -s, --status           Muestra el diagnóstico completo de apariencia, temas, iconos y fuentes
  -i, --interactive      Inicia el selector interactivo paso a paso
  --no-install, --config Aplica temas en GSettings/GTK sin ejecutar DNF5 ni descargas
  --install              Solo instala los paquetes y cursores sin alterar configuraciones
  -h, --help             Muestra esta ayuda

${BOLD}Personalización de Temas y Acentos:${NC}
  --dark                 Activa Modo Oscuro (prefer-dark + adw-gtk3-dark)
  --light                Activa Modo Claro (default + adw-gtk3)
  --accent <color>       Color de acento GNOME 47+ (blue, teal, green, yellow, orange, red, purple, slate)
  --papirus-dark         Usa iconos Papirus-Dark
  --papirus              Usa iconos Papirus estándar
  --adwaita              Usa iconos nativos Adwaita
  --bibata               Usa cursor Bibata-Modern-Classic (Negro con borde blanco)
  --bibata-ice           Usa cursor Bibata-Modern-Ice (Blanco)
  --adwaita-cursor       Usa cursor nativo Adwaita
  --cursor-size <px>     Define tamaño del cursor (predeterminado: 24 para triple monitor 1080p)
EOF
}

# ------------------------------------------------------------------------------
# 8. PARSER DE ARGUMENTOS CLI
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
# 9. APLICAR CONFIGURACIÓN EN GSETTINGS Y ENTORNO WAYLAND
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
run_as_user gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME_VAL"
run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_VAL"
run_as_user gsettings set org.gnome.desktop.interface icon-theme "$MODE_ICONS"
run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$MODE_CURSOR"
run_as_user gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"

# Configurar Accent Color si el esquema lo soporta (GNOME 47+)
if run_as_user gsettings range org.gnome.desktop.interface accent-color &>/dev/null; then
    run_as_user gsettings set org.gnome.desktop.interface accent-color "$MODE_ACCENT"
    log_ok "Color de acento de GNOME Shell establecido en '$MODE_ACCENT'."
fi

# Sincronizar archivos settings.ini de GTK 3.0 y GTK 4.0 a nivel de usuario
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

# Configurar índice global de cursor del usuario en ~/.icons/default/index.theme (XWayland compatibility)
mkdir -p "$USER_HOME/.icons/default"
cat << EOF > "$USER_HOME/.icons/default/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=${MODE_CURSOR}
EOF

# Corregir permisos en caso de invocación con sudo
if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0" "$USER_HOME/.icons"
fi

# Sincronización de temas y cursores con aplicaciones Flatpak
if command -v flatpak &>/dev/null; then
    log_info "Sincronizando temas y directorios de iconos con Flatpak..."
    run_as_user flatpak override --user \
        --filesystem=xdg-config/gtk-3.0:ro \
        --filesystem=xdg-config/gtk-4.0:ro \
        --filesystem=/usr/share/icons:ro \
        --filesystem=~/.icons:ro \
        --filesystem=xdg-data/icons:ro \
        --filesystem=/usr/share/themes:ro \
        --filesystem=~/.themes:ro \
        2>/dev/null || true

    run_as_user flatpak override --user \
        --env=GTK_THEME="$GTK_THEME_VAL" \
        --env=XCURSOR_THEME="$MODE_CURSOR" \
        --env=XCURSOR_SIZE="$CURSOR_SIZE" \
        2>/dev/null || true
    log_ok "Overrides de Flatpak actualizados."
fi

log_ok "Apariencia aplicada correctamente en Fedora 45 Workstation."
echo ""
show_status
