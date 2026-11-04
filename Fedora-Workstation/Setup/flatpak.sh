#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  flatpak.sh - Gestor e Instalador de Software Flatpak (Flathub)
#  Sistema: Fedora 45 Workstation (GNOME Shell 51+ Wayland / Mutter)
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

DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"

# ------------------------------------------------------------------------------
# 3. CATÁLOGO MODULAR DE APLICACIONES FLATHUB
# ------------------------------------------------------------------------------
ESSENTIAL_APPS=(
    "com.github.tchx84.Flatseal"            # Gestor gráfico de permisos y overrides Flatpak
    "io.github.flattool.Warehouse"          # Gestión avanzada de paquetes, runtimes y espacio
    "com.mattjakeman.ExtensionManager"      # Gestor gráfico nativo de extensiones GNOME
    "org.localsend.localsend_app"           # Transferencia de archivos P2P segura en red local
)

DEV_APPS=(
    "io.podman_desktop.PodmanDesktop"       # Interfaz gráfica moderna para contenedores Podman Rootless
    "com.usebruno.Bruno"                    # Cliente API Git-friendly rápido y offline
    "io.dbeaver.DBeaverCommunity"           # Gestor universal de bases de datos relacionales y NoSQL
)

MULTIMEDIA_APPS=(
    "org.videolan.VLC"                      # Reproductor multimedia universal
    "io.github.celluloid_player.Celluloid"  # Reproductor GTK4/MPV Wayland con aceleración VA-API AMD
    "com.obsproject.Studio"                 # Grabación y streaming con captura PipeWire Wayland
    "org.kde.kdenlive"                      # Editor de video multipista profesional (acelerado por GPU)
    "org.shotcut.Shotcut"                   # Editor de video ligero
    "com.spotify.Client"                    # Reproductor oficial de música Spotify
)

OFFICE_SOCIAL_APPS=(
    "md.obsidian.Obsidian"                  # Gestor de conocimiento Markdown con soporte Wayland nativo
    "org.onlyoffice.desktopeditors"         # Suite ofimática de alta fidelidad compatible con MS Office
    "dev.vencord.Vesktop"                   # Cliente Discord nativo Wayland con captura de pantalla PipeWire
    "org.telegram.desktop"                  # Mensajería instantánea nativa Wayland
)

DEFAULT_APPS=(
    "${ESSENTIAL_APPS[@]}"
    "io.podman_desktop.PodmanDesktop"
    "io.github.celluloid_player.Celluloid"
    "org.videolan.VLC"
    "com.obsproject.Studio"
    "md.obsidian.Obsidian"
)

# Modo de instalación: auto, user o system
INSTALL_SCOPE="auto"

# ------------------------------------------------------------------------------
# 4. AYUDA CLI
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}📦 Gestor e Instalador de Software Flatpak (Flathub) - Fedora 45 Workstation${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)
Compositor: GNOME Shell 51+ (Mutter Wayland) / Topología Triple Pantalla FHD

Configura Flathub sin filtros, optimiza permisos Wayland/GPU (Mesa RADV, VA-API,
PipeWire, tema oscuro adw-gtk3-dark y fuentes) e instala catálogos desacoplados.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones de Instalación:${NC}
  (sin argumentos)    Instala el perfil estándar recomendado + overrides Wayland/AMD
  --all               Instala todo el catálogo (Esenciales + Dev + Multimedia + Ofimática)
  --essential         Instala utilidades base (Flatseal, Warehouse, Extension Manager, LocalSend)
  --dev               Instala suite de desarrollo (Podman Desktop, Bruno, DBeaver)
  --multimedia        Instala suite multimedia acelerada por GPU (VLC, Celluloid, OBS, Kdenlive, Spotify)
  --office            Instala productividad y comunicación (Obsidian, OnlyOffice, Vesktop, Telegram)

${BOLD}Alcance de Instalación:${NC}
  --user              Instala en espacio de usuario rootless (~/.local/share/flatpak)
  --system            Instala a nivel de sistema (/var/lib/flatpak) requiriendo sudo

${BOLD}Mantenimiento y Diagnóstico:${NC}
  --overrides         Aplica o actualiza únicamente los overrides globales Wayland/GPU/PipeWire
  --update            Actualiza todas las aplicaciones y runtimes (sistema y usuario)
  --clean             Elimina runtimes huérfanos y limpia caché no utilizada
  -s, --status        Muestra diagnóstico completo de repositorios, catálogo y overrides
  -h, --help          Muestra esta ayuda
EOF
}

# ------------------------------------------------------------------------------
# 5. CONFIGURACIÓN DEL REPOSITORIO FLATHUB (SIN FILTROS)
# ------------------------------------------------------------------------------
ensure_flatpak_flathub() {
    if ! command -v flatpak &>/dev/null; then
        log_info "Instalando flatpak y soporte GNOME mediante $DNF_BIN..."
        if [[ $EUID -eq 0 ]]; then
            "$DNF_BIN" install -y flatpak gnome-software
        else
            sudo "$DNF_BIN" install -y flatpak gnome-software
        fi
    fi

    # Configuración de Flathub a nivel de sistema si tenemos privilegios
    if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null || [[ "$INSTALL_SCOPE" == "system" ]]; then
        sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
        sudo flatpak remote-modify --enable flathub --no-filter 2>/dev/null || true
    fi

    # Configuración de Flathub a nivel de usuario rootless
    run_as_user flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    run_as_user flatpak remote-modify --user --enable flathub --no-filter 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# 6. APLICACIÓN DE OVERRIDES (WAYLAND, AMD GPU, PIPEWIRE, FUENTES Y TEMAS)
# ------------------------------------------------------------------------------
apply_overrides() {
    log_info "Optimizando overrides Flatpak para AMD Radeon Vega 8, Wayland y PipeWire..."

    # Overrides globales a nivel de usuario (rootless)
    # Nota: No inyectar GTK_THEME ni xdg-config/gtk-4.0 ya que rompe la métrica de fuentes
    # y el espaciado vertical en widgets Libadwaita (AdwActionRow) en GTK4.
    run_as_user flatpak override --user \
        --socket=wayland \
        --socket=fallback-x11 \
        --socket=pulseaudio \
        --filesystem=xdg-run/pipewire-0:ro \
        --device=dri \
        --filesystem=xdg-config/gtk-3.0:ro \
        --filesystem=xdg-config/fontconfig:ro \
        --filesystem=~/.icons:ro \
        --filesystem=xdg-data/icons:ro \
        --filesystem=~/.local/share/fonts:ro \
        --env=XCURSOR_THEME=Bibata-Modern-Classic \
        --env=XCURSOR_SIZE=24 \
        --env=XDG_CURRENT_DESKTOP=GNOME \
        --env=ELECTRON_OZONE_PLATFORM_HINT=auto 2>/dev/null || true

    # Overrides a nivel de sistema si se ejecuta con privilegios
    if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null; then
        sudo flatpak override \
            --socket=wayland \
            --socket=fallback-x11 \
            --socket=pulseaudio \
            --filesystem=xdg-run/pipewire-0:ro \
            --device=dri \
            --env=ELECTRON_OZONE_PLATFORM_HINT=auto 2>/dev/null || true
    fi

    # Overrides específicos por aplicación para máxima fidelidad
    # 1. Obsidian: renderizado Wayland nativo nítido en triple monitor 1080p
    run_as_user flatpak override --user md.obsidian.Obsidian \
        --socket=wayland \
        --env=ELECTRON_OZONE_PLATFORM_HINT=auto 2>/dev/null || true

    # 2. Vesktop: captura de pantalla por PipeWire y Wayland
    run_as_user flatpak override --user dev.vencord.Vesktop \
        --socket=wayland \
        --env=ELECTRON_OZONE_PLATFORM_HINT=auto \
        --talk-name=org.freedesktop.portal.Desktop 2>/dev/null || true

    # 3. OBS Studio: aceleración GPU DRI y acceso a carpeta de videos
    run_as_user flatpak override --user com.obsproject.Studio \
        --device=dri \
        --filesystem=xdg-videos 2>/dev/null || true

    # 4. Celluloid: aceleración de hardware VA-API AMD Radeon
    run_as_user flatpak override --user io.github.celluloid_player.Celluloid \
        --device=dri 2>/dev/null || true

    log_ok "Overrides Wayland, GPU DRI, PipeWire, fuentes e integración GNOME aplicados."
}

# ------------------------------------------------------------------------------
# 7. DIAGNÓSTICO Y ESTADO (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🔍 ${BOLD}ESTADO DE FLATPAK Y FLATHUB - FEDORA 45 WORKSTATION${NC}"
    echo -e "      ${CYAN}HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if ! command -v flatpak &>/dev/null; then
        echo -e "  • Binario Flatpak:           ${RED}No instalado${NC}"
        return 0
    fi

    echo -e "  • Versión Flatpak:           ${GREEN}$(flatpak --version)${NC}"

    # Estado de Flathub a nivel sistema y usuario
    local flathub_sys="No configurado" flathub_usr="No configurado"
    if flatpak remotes 2>/dev/null | grep -q "flathub"; then
        if flatpak remotes --show-details 2>/dev/null | grep "flathub" | grep -q "fedora-flathub.filter"; then
            flathub_sys="${YELLOW}Filtrado (Catálogo Fedora reducido)${NC}"
        else
            flathub_sys="${GREEN}Sin filtros (Catálogo oficial completo)${NC}"
        fi
    fi

    if run_as_user flatpak remotes --user 2>/dev/null | grep -q "flathub"; then
        flathub_usr="${GREEN}Sin filtros (Usuario Rootless)${NC}"
    fi

    echo -e "  • Flathub (Sistema):         ${flathub_sys}"
    echo -e "  • Flathub (Usuario):         ${flathub_usr}"

    # Telemetría de Overrides activos
    local active_ov
    active_ov=$(run_as_user flatpak override --user --show 2>/dev/null || true)
    local wayland_ov="No" dri_ov="No" ozone_ov="No" pipewire_ov="No"
    [[ "$active_ov" == *"wayland"* ]] && wayland_ov="${GREEN}Activo (Nativo Wayland)${NC}" || wayland_ov="${YELLOW}Inactivo${NC}"
    [[ "$active_ov" == *"devices=dri"* || "$active_ov" == *"dri;"* ]] && dri_ov="${GREEN}Activo (AMD GPU DRI)${NC}" || dri_ov="${YELLOW}Inactivo${NC}"
    [[ "$active_ov" == *"ELECTRON_OZONE_PLATFORM_HINT"* ]] && ozone_ov="${GREEN}Activo (Auto Wayland)${NC}" || ozone_ov="${YELLOW}Inactivo${NC}"
    [[ "$active_ov" == *"xdg-run/pipewire-0"* ]] && pipewire_ov="${GREEN}Activo (Direct PipeWire)${NC}" || pipewire_ov="${YELLOW}Inactivo${NC}"

    echo ""
    echo -e "${BOLD}⚡ Overrides de Rendimiento e Integración:${NC}"
    echo -e "  • Socket Wayland:            $wayland_ov"
    echo -e "  • Aceleración GPU (DRI):     $dri_ov"
    echo -e "  • Integración PipeWire:      $pipewire_ov"
    echo -e "  • Renderizado Electron:      $ozone_ov"

    # Lista de aplicaciones instaladas
    local installed_system installed_user
    installed_system=$(flatpak list --app --columns=application 2>/dev/null || true)
    installed_user=$(run_as_user flatpak list --user --app --columns=application 2>/dev/null || true)

    echo ""
    echo -e "${BOLD}📋 Estado del Catálogo de Aplicaciones:${NC}"
    local all_catalog=("${ESSENTIAL_APPS[@]}" "${DEV_APPS[@]}" "${MULTIMEDIA_APPS[@]}" "${OFFICE_SOCIAL_APPS[@]}")
    for app_id in "${all_catalog[@]}"; do
        local status="${YELLOW}No instalado${NC}"
        if echo "$installed_system" | grep -qx "$app_id"; then
            status="${GREEN}Instalado [Sistema]${NC}"
        elif echo "$installed_user" | grep -qx "$app_id"; then
            status="${GREEN}Instalado [Usuario Rootless]${NC}"
        fi
        printf "  • %-38s : %b\n" "$app_id" "$status"
    done
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 8. INSTALACIÓN DE APLICACIONES
# ------------------------------------------------------------------------------
install_list() {
    ensure_flatpak_flathub
    local apps=("$@")

    local installed_system installed_user
    installed_system=$(flatpak list --app --columns=application 2>/dev/null || true)
    installed_user=$(run_as_user flatpak list --user --app --columns=application 2>/dev/null || true)

    local to_install=()
    for app in "${apps[@]}"; do
        if echo "$installed_system" | grep -qx "$app" || echo "$installed_user" | grep -qx "$app"; then
            log_ok "$app ya está instalado."
        else
            to_install+=("$app")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        # Determinación de alcance: sistema o usuario
        if [[ "$INSTALL_SCOPE" == "user" ]] || { [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null && [[ "$INSTALL_SCOPE" != "system" ]]; }; then
            log_info "Instalando en espacio de usuario rootless (Flathub): ${to_install[*]}..."
            run_as_user flatpak install -y --user --noninteractive flathub "${to_install[@]}"
        else
            log_info "Instalando a nivel de sistema (Flathub): ${to_install[*]}..."
            sudo flatpak install -y --noninteractive flathub "${to_install[@]}"
        fi
    fi

    apply_overrides
}

# ------------------------------------------------------------------------------
# 9. PARSEO DE ARGUMENTOS CLI Y CONTROL DE FLUJO
# ------------------------------------------------------------------------------
MODE="default"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)       MODE="status"; shift ;;
        --all)             MODE="all"; shift ;;
        --essential)       MODE="essential"; shift ;;
        --dev)             MODE="dev"; shift ;;
        --multimedia)      MODE="multimedia"; shift ;;
        --office)          MODE="office"; shift ;;
        --overrides)       MODE="overrides"; shift ;;
        --update)          MODE="update"; shift ;;
        --clean)           MODE="clean"; shift ;;
        --user|--user-mode)
            INSTALL_SCOPE="user"
            shift
            ;;
        --system|--system-mode)
            INSTALL_SCOPE="system"
            shift
            ;;
        -h|--help)         show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

case "$MODE" in
    status)
        show_status
        ;;
    overrides)
        apply_overrides
        show_status
        ;;
    all)
        install_list "${ESSENTIAL_APPS[@]}" "${DEV_APPS[@]}" "${MULTIMEDIA_APPS[@]}" "${OFFICE_SOCIAL_APPS[@]}"
        show_status
        ;;
    essential)
        install_list "${ESSENTIAL_APPS[@]}"
        show_status
        ;;
    dev)
        install_list "${DEV_APPS[@]}"
        show_status
        ;;
    multimedia)
        install_list "${MULTIMEDIA_APPS[@]}"
        show_status
        ;;
    office)
        install_list "${OFFICE_SOCIAL_APPS[@]}"
        show_status
        ;;
    update)
        ensure_flatpak_flathub
        log_info "Actualizando aplicaciones y runtimes Flatpak (sistema y usuario)..."
        if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null; then
            sudo flatpak update -y
        fi
        run_as_user flatpak update --user -y 2>/dev/null || true
        log_ok "Actualización de Flatpak completada."
        ;;
    clean)
        log_info "Limpiando runtimes y dependencias huérfanas de Flatpak..."
        if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null; then
            sudo flatpak uninstall --unused -y 2>/dev/null || true
        fi
        run_as_user flatpak uninstall --user --unused -y 2>/dev/null || true
        log_ok "Limpieza de Flatpak completada."
        ;;
    default)
        install_list "${DEFAULT_APPS[@]}"
        show_status
        ;;
esac
