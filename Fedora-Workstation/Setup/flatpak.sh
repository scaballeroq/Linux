#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  flatpak.sh - Gestor e Instalador de Catálogo Flatpak (Flathub)
#  Sistema: Fedora 45 Workstation (GNOME Shell Wayland)
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

ESSENTIAL_APPS=(
    "com.github.tchx84.Flatseal"
    "io.github.flattool.Warehouse"
    "com.mattjakeman.ExtensionManager"
    "org.localsend.localsend_app"
)

DEV_APPS=(
    "io.podman_desktop.PodmanDesktop"
    "com.usebruno.Bruno"
    "io.dbeaver.DBeaverCommunity"
)

MULTIMEDIA_APPS=(
    "org.kde.kdenlive"
    "org.shotcut.Shotcut"
    "com.obsproject.Studio"
    "org.videolan.VLC"
    "io.github.celluloid_player.Celluloid"
    "com.spotify.Client"
)

OFFICE_SOCIAL_APPS=(
    "md.obsidian.Obsidian"
    "org.onlyoffice.desktopeditors"
    "dev.vencord.Vesktop"
    "org.telegram.desktop"
)

DEFAULT_APPS=(
    "${ESSENTIAL_APPS[@]}"
    "io.podman_desktop.PodmanDesktop"
    "org.kde.kdenlive"
    "com.obsproject.Studio"
    "org.videolan.VLC"
    "md.obsidian.Obsidian"
)

show_help() {
    cat << EOF
${BOLD}📦 Gestor e Instalador de Software Flatpak (Flathub) - Fedora 45 Workstation (GNOME Wayland)${NC}

Configura el repositorio oficial Flathub (reemplazando el filtro limitado de Fedora),
instala perfiles de aplicaciones desacopladas y aplica overrides para temas GTK oscuros,
cursores Bibata y aceleración GPU Wayland.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)   Instala el perfil estándar recomendado + overrides Wayland/GTK
  --all              Instala el catálogo completo (Esenciales + Dev + Multimedia + Productividad)
  --essential        Instala solo utilidades esenciales (Flatseal, Warehouse, Extension Manager, LocalSend)
  --dev              Instala aplicaciones de desarrollo (Podman Desktop, Bruno, DBeaver)
  --multimedia       Instala suite multimedia (Kdenlive, Shotcut, OBS Studio, VLC, Celluloid, Spotify)
  --office           Instala suite productividad y comunicación (Obsidian, OnlyOffice, Vesktop, Telegram)
  --update           Actualiza todas las aplicaciones y runtimes Flatpak
  --clean            Elimina runtimes huérfanos y limpia caché de Flatpak
  -s, --status       Muestra el estado de Flathub y de todo el catálogo en tiempo O(1)
  -h, --help         Muestra esta ayuda
EOF
}

ensure_flatpak_flathub() {
    if ! command -v flatpak &>/dev/null; then
        log_info "Instalando flatpak mediante $DNF_BIN..."
        sudo "$DNF_BIN" install -y flatpak gnome-software
    fi
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    sudo flatpak remote-modify --enable flathub --no-filter 2>/dev/null || true
}

apply_overrides() {
    log_info "Aplicando overrides de Flatpak para tema oscuro GNOME (adw-gtk3-dark), cursores y DRI GPU..."
    run_as_user flatpak override --user \
        --filesystem=xdg-config/gtk-3.0:ro \
        --filesystem=xdg-config/gtk-4.0:ro \
        --filesystem=/usr/share/icons:ro \
        --filesystem=~/.icons:ro \
        --device=dri \
        --env=GTK_THEME=adw-gtk3-dark \
        --env=XCURSOR_THEME=Bibata-Modern-Classic \
        --env=XCURSOR_SIZE=24 2>/dev/null || true
    log_ok "Overrides de integración Wayland/GTK aplicados."
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🔍 ${BOLD}ESTADO DE FLATPAK Y FLATHUB - FEDORA 45 WORKSTATION (GNOME WAYLAND)${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if ! command -v flatpak &>/dev/null; then
        echo -e "  • Binario Flatpak: ${RED}No instalado${NC}"
        return 0
    fi

    echo -e "  • Versión Flatpak:           ${GREEN}$(flatpak --version)${NC}"
    if flatpak remotes | grep -q "flathub"; then
        echo -e "  • Repositorio Flathub:       ${GREEN}Habilitado sin filtros${NC}"
    else
        echo -e "  • Repositorio Flathub:       ${YELLOW}No configurado${NC}"
    fi

    local installed_list
    installed_list=$(flatpak list --app --columns=application 2>/dev/null || true)

    echo ""
    echo -e "${BOLD}📋 Estado del Catálogo de Aplicaciones:${NC}"
    local all_catalog=("${ESSENTIAL_APPS[@]}" "${DEV_APPS[@]}" "${MULTIMEDIA_APPS[@]}" "${OFFICE_SOCIAL_APPS[@]}")
    for app_id in "${all_catalog[@]}"; do
        if echo "$installed_list" | grep -qx "$app_id"; then
            echo -e "  • $(printf '%-42s' "$app_id"): ${GREEN}Instalado${NC}"
        else
            echo -e "  • $(printf '%-42s' "$app_id"): ${YELLOW}No instalado${NC}"
        fi
    done
    echo -e "${BOLD}======================================================================${NC}"
}

install_list() {
    ensure_flatpak_flathub
    local apps=("$@")
    local installed_list
    installed_list=$(flatpak list --app --columns=application 2>/dev/null || true)

    local to_install=()
    for app in "${apps[@]}"; do
        if echo "$installed_list" | grep -qx "$app"; then
            log_ok "$app ya está instalado."
        else
            to_install+=("$app")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Instalando desde Flathub: ${to_install[*]}..."
        sudo flatpak install -y --noninteractive flathub "${to_install[@]}"
    fi
    apply_overrides
}

MODE="default"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)  MODE="status"; shift ;;
        --all)        MODE="all"; shift ;;
        --essential)  MODE="essential"; shift ;;
        --dev)        MODE="dev"; shift ;;
        --multimedia) MODE="multimedia"; shift ;;
        --office)     MODE="office"; shift ;;
        --update)     MODE="update"; shift ;;
        --clean)      MODE="clean"; shift ;;
        -h|--help)    show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

case "$MODE" in
    status)     show_status ;;
    all)        install_list "${ESSENTIAL_APPS[@]}" "${DEV_APPS[@]}" "${MULTIMEDIA_APPS[@]}" "${OFFICE_SOCIAL_APPS[@]}" ;;
    essential)  install_list "${ESSENTIAL_APPS[@]}" ;;
    dev)        install_list "${DEV_APPS[@]}" ;;
    multimedia) install_list "${MULTIMEDIA_APPS[@]}" ;;
    office)     install_list "${OFFICE_SOCIAL_APPS[@]}" ;;
    update)
        ensure_flatpak_flathub
        log_info "Actualizando aplicaciones y runtimes Flatpak..."
        sudo flatpak update -y
        run_as_user flatpak update --user -y 2>/dev/null || true
        log_ok "Flatpak actualizado."
        ;;
    clean)
        log_info "Limpiando runtimes huérfanos de Flatpak..."
        sudo flatpak uninstall --unused -y
        run_as_user flatpak uninstall --user --unused -y 2>/dev/null || true
        log_ok "Limpieza de Flatpak completada."
        ;;
    default)
        install_list "${DEFAULT_APPS[@]}"
        show_status
        ;;
esac
