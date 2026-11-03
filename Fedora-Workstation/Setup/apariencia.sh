#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  apariencia.sh - Gestor de Temas, Iconos y Cursores en Fedora 45 Workstation
#  GNOME Shell Wayland | adw-gtk3 | Papirus | Bibata Cursor | Modo Interactivo
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

MODE_COLOR="dark"
MODE_ICONS="Papirus-Dark"
MODE_CURSOR="Bibata-Modern-Classic"
CURSOR_SIZE=24
DO_INSTALL=true
ONLY_INSTALL=false
INTERACTIVE=false
ACTION="apply"

show_help() {
    cat << EOF
${BOLD}🎨 Gestor de Apariencia (Temas, Iconos y Cursores) - Fedora 45 Workstation${NC}

Instala paquetes visuales mediante DNF5 (${BOLD}adw-gtk3-theme${NC}, ${BOLD}papirus-icon-theme${NC}) y el
cursor ${BOLD}Bibata Modern${NC} (Classic e Ice), aplicando la configuración en GNOME Wayland
y sincronizando GTK3/GTK4.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)       Instala temas y aplica perfil predeterminado (Dark + Papirus-Dark + Bibata Classic 24px)
  -i, --interactive      Inicia el selector interactivo paso a paso
  --no-install, --config Aplica temas en GSettings/GTK sin ejecutar DNF5 ni descargas
  --install              Solo instala los paquetes y cursores sin alterar GSettings
  --dark                 Activa Modo Oscuro (prefer-dark + adw-gtk3-dark)
  --light                Activa Modo Claro (default + adw-gtk3)
  --papirus-dark         Usa iconos Papirus-Dark
  --papirus              Usa iconos Papirus estándar
  --adwaita              Usa iconos nativos Adwaita
  --bibata               Usa cursor Bibata-Modern-Classic (Negro)
  --bibata-ice           Usa cursor Bibata-Modern-Ice (Blanco)
  --adwaita-cursor       Usa cursor nativo Adwaita
  --cursor-size <px>     Define tamaño del cursor (ej. 24, 32)
  -s, --status           Muestra el estado actual de temas, iconos y cursor en GNOME
  -h, --help             Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🎨 ${BOLD}ESTADO DE APARIENCIA EN GNOME - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    local color_scheme gtk_theme icon_theme cursor_theme cursor_sz
    color_scheme=$(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "N/A")
    gtk_theme=$(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "N/A")
    icon_theme=$(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo "N/A")
    cursor_theme=$(run_as_user gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo "N/A")
    cursor_sz=$(run_as_user gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null || echo "N/A")

    echo -e "  • Esquema de color:          ${CYAN}${color_scheme}${NC}"
    echo -e "  • Tema GTK3/Legacy:          ${CYAN}${gtk_theme}${NC}"
    echo -e "  • Tema de Iconos:            ${CYAN}${icon_theme}${NC}"
    echo -e "  • Tema de Cursor:            ${CYAN}${cursor_theme}${NC} (${cursor_sz}px)"

    echo ""
    echo -e "${BOLD}📦 Paquetes y Recursos Instalados (DNF5 / Local):${NC}"
    for pkg in adw-gtk3-theme papirus-icon-theme gnome-tweaks; do
        if rpm -q "$pkg" &>/dev/null; then
            echo -e "  • $(printf '%-25s' "$pkg"): ${GREEN}Instalado${NC}"
        else
            echo -e "  • $(printf '%-25s' "$pkg"): ${YELLOW}No instalado${NC}"
        fi
    done

    for cur in Bibata-Modern-Classic Bibata-Modern-Ice; do
        if [[ -d "/usr/share/icons/$cur" || -d "$USER_HOME/.local/share/icons/$cur" ]]; then
            echo -e "  • Cursor $(printf '%-18s' "$cur"): ${GREEN}Instalado${NC}"
        else
            echo -e "  • Cursor $(printf '%-18s' "$cur"): ${YELLOW}No instalado${NC}"
        fi
    done
    echo -e "${BOLD}======================================================================${NC}"
}

install_bibata_cursors() {
    local target_dir="/usr/share/icons"
    if [[ -d "$target_dir/Bibata-Modern-Classic" && -d "$target_dir/Bibata-Modern-Ice" ]]; then
        log_ok "Cursores Bibata-Modern-Classic y Bibata-Modern-Ice ya están instalados."
        return 0
    fi

    log_info "Instalando cursores Bibata Modern (Classic e Ice)..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    for variant in Bibata-Modern-Classic Bibata-Modern-Ice; do
        if [[ ! -d "$target_dir/$variant" ]]; then
            local url="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/${variant}.tar.xz"
            if curl -fsSL "$url" -o "$tmp_dir/${variant}.tar.xz"; then
                sudo tar -xJf "$tmp_dir/${variant}.tar.xz" -C "$target_dir"
                log_ok "Cursor $variant instalado en $target_dir/$variant."
            else
                log_warn "No se pudo descargar $variant desde GitHub."
            fi
        fi
    done
    rm -rf "$tmp_dir"
}

install_packages() {
    log_info "Verificando paquetes de temas e iconos en Fedora 45 ($DNF_BIN)..."
    local pkgs=(adw-gtk3-theme papirus-icon-theme gnome-tweaks curl tar xz)
    local missing=()
    for p in "${pkgs[@]}"; do
        rpm -q "$p" &>/dev/null || missing+=("$p")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        sudo "$DNF_BIN" install -y "${missing[@]}"
    else
        log_ok "Paquetes adw-gtk3-theme, papirus-icon-theme y gnome-tweaks ya instalados."
    fi
    install_bibata_cursors
}

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

    echo -e "\n${BOLD}2) Selecciona el Tema de Iconos:${NC}"
    echo "   1) Papirus-Dark [Recomendado para modo oscuro]"
    echo "   2) Papirus"
    echo "   3) Adwaita (Nativo GNOME)"
    read -rp "Opción [1]: " opt_icons
    case "${opt_icons:-1}" in
        2) MODE_ICONS="Papirus" ;;
        3) MODE_ICONS="Adwaita" ;;
        *) MODE_ICONS="Papirus-Dark" ;;
    esac

    echo -e "\n${BOLD}3) Selecciona el Tema de Cursor:${NC}"
    echo "   1) Bibata-Modern-Classic (Negro con borde blanco) [Recomendado]"
    echo "   2) Bibata-Modern-Ice (Blanco)"
    echo "   3) Adwaita (Nativo GNOME)"
    read -rp "Opción [1]: " opt_cursor
    case "${opt_cursor:-1}" in
        2) MODE_CURSOR="Bibata-Modern-Ice" ;;
        3) MODE_CURSOR="Adwaita" ;;
        *) MODE_CURSOR="Bibata-Modern-Classic" ;;
    esac

    echo -e "\n${BOLD}4) Tamaño del Cursor en píxeles (24, 32, 48):${NC}"
    read -rp "Tamaño [24]: " opt_size
    CURSOR_SIZE="${opt_size:-24}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)           ACTION="status"; shift ;;
        -i|--interactive)      INTERACTIVE=true; shift ;;
        --no-install|--config) DO_INSTALL=false; shift ;;
        --install)             ONLY_INSTALL=true; shift ;;
        --dark)                MODE_COLOR="dark"; shift ;;
        --light)               MODE_COLOR="light"; shift ;;
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

if [[ "$MODE_COLOR" == "light" ]]; then
    COLOR_SCHEME_VAL="default"
    GTK_THEME_VAL="adw-gtk3"
    GTK_PREFER_DARK=0
else
    COLOR_SCHEME_VAL="prefer-dark"
    GTK_THEME_VAL="adw-gtk3-dark"
    GTK_PREFER_DARK=1
fi

log_info "Aplicando configuración en GNOME Wayland ($COLOR_SCHEME_VAL | $GTK_THEME_VAL | $MODE_ICONS | $MODE_CURSOR ${CURSOR_SIZE}px)..."
run_as_user gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME_VAL"
run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_VAL"
run_as_user gsettings set org.gnome.desktop.interface icon-theme "$MODE_ICONS"
run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$MODE_CURSOR"
run_as_user gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"

# Sincronizar archivos settings.ini de GTK 3.0 y GTK 4.0
for gtk_ver in gtk-3.0 gtk-4.0; do
    mkdir -p "$USER_HOME/.config/$gtk_ver"
    cat << EOF > "$USER_HOME/.config/$gtk_ver/settings.ini"
[Settings]
gtk-application-prefer-dark-theme=${GTK_PREFER_DARK}
gtk-theme-name=${GTK_THEME_VAL}
gtk-icon-theme-name=${MODE_ICONS}
gtk-cursor-theme-name=${MODE_CURSOR}
gtk-cursor-theme-size=${CURSOR_SIZE}
EOF
done

# Configurar índice global de cursor del usuario en ~/.icons/default/index.theme
mkdir -p "$USER_HOME/.icons/default"
cat << EOF > "$USER_HOME/.icons/default/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=${MODE_CURSOR}
EOF

if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0" "$USER_HOME/.icons"
fi

# Aplicar overrides a Flatpak si está disponible
if command -v flatpak &>/dev/null; then
    run_as_user flatpak override --user --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro --filesystem=/usr/share/icons:ro --filesystem=~/.icons:ro 2>/dev/null || true
    run_as_user flatpak override --user --env=GTK_THEME="$GTK_THEME_VAL" --env=XCURSOR_THEME="$MODE_CURSOR" --env=XCURSOR_SIZE="$CURSOR_SIZE" 2>/dev/null || true
fi

log_ok "Apariencia aplicada correctamente en Fedora 45 Workstation."
show_status
