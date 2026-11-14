#!/usr/bin/env bash
# ==============================================================================
# flatpak.sh - Gestor e Instalador de Software Flatpak (Flathub)
# Sistema: CachyOS Workstation (GNOME Shell Wayland / Mutter)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)
# Topología: Triple Pantalla Full HD 1080p (DP-3, DP-4, eDP-1)
# ==============================================================================
# Características:
#   - Repositorio Flathub sin filtros (--no-filter) tanto a nivel sistema como usuario.
#   - Aceleración por hardware AMD Radeon (Mesa RADV, VA-API radeonsi, VDPAU radeonsi).
#   - Detección dinámica de cursores y temas GNOME (Adwaita, Libadwaita prefer-dark).
#   - Integración nativa Wayland y mitigación de borrosidad multi-monitor en Electron.
#   - Permisos optimizados para cámara web HP (/dev/video*), micrófono y PipeWire directo.
#   - Compatibilidad completa con Podman Desktop rootless (~/.config/containers, podman.sock).
#   - Soporte de temas Libadwaita para GTK3 (adw-gtk3, adw-gtk3-dark).
#   - Comandos idempotentes, seguros y compatibilidad total con flags --status y --help.
# ==============================================================================

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y FORMATO VISUAL
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
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
if [[ -n "${SUDO_USER:-}" ]] && [[ "$SUDO_USER" != "root" ]]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi
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

detect_gnome_settings() {
    DETECTED_CURSOR_THEME=$(run_as_user gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'" || echo "Adwaita")
    [[ -z "$DETECTED_CURSOR_THEME" ]] && DETECTED_CURSOR_THEME="Adwaita"

    DETECTED_CURSOR_SIZE=$(run_as_user gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null || echo "24")
    [[ -z "$DETECTED_CURSOR_SIZE" ]] && DETECTED_CURSOR_SIZE="24"

    DETECTED_COLOR_SCHEME=$(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'" || echo "prefer-dark")
}

# ------------------------------------------------------------------------------
# 3. CATÁLOGO MODULAR DE APLICACIONES FLATHUB
# ------------------------------------------------------------------------------
ESSENTIAL_APPS=(
    "com.github.tchx84.Flatseal"            # Gestor gráfico de permisos y overrides Flatpak
    "io.github.flattool.Warehouse"          # Gestión avanzada de paquetes, runtimes y espacio
    "com.mattjakeman.ExtensionManager"      # Gestor gráfico nativo de extensiones GNOME
    "org.localsend.localsend_app"           # Transferencia de archivos P2P segura en red local
    "org.gtk.Gtk3theme.adw-gtk3"            # Tema Libadwaita claro para apps GTK3
    "org.gtk.Gtk3theme.adw-gtk3-dark"       # Tema Libadwaita oscuro para apps GTK3
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
    "org.shotcut.Shotcut"                   # Editor de video ligero acelerado
    "com.spotify.Client"                    # Reproductor oficial de música Spotify
)

OFFICE_SOCIAL_APPS=(
    "md.obsidian.Obsidian"                  # Gestor de conocimiento Markdown con soporte Wayland nativo
    "org.onlyoffice.desktopeditors"         # Suite ofimática de alta fidelidad compatible con MS Office
    "dev.vencord.Vesktop"                   # Cliente Discord nativo Wayland con captura de pantalla PipeWire
    "org.telegram.desktop"                  # Mensajería instantánea nativa Wayland
)

DEFAULT_APPS=(
    "com.github.tchx84.Flatseal"
    "io.github.flattool.Warehouse"
    "com.mattjakeman.ExtensionManager"
    "org.gtk.Gtk3theme.adw-gtk3"
    "org.gtk.Gtk3theme.adw-gtk3-dark"
    "io.podman_desktop.PodmanDesktop"
    "io.github.celluloid_player.Celluloid"
    "org.videolan.VLC"
    "com.obsproject.Studio"
    "md.obsidian.Obsidian"
)

# Modo de instalación: auto (user rootless salvo sudo explícito), user o system
INSTALL_SCOPE="auto"

# ------------------------------------------------------------------------------
# 4. AYUDA CLI
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}📦 Gestor e Instalador de Software Flatpak (Flathub) - CachyOS Workstation${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)
Compositor: GNOME Shell (Mutter Wayland) / Topología Triple Pantalla FHD (DP-3, DP-4, eDP-1)

Configura Flathub sin filtros, optimiza permisos Wayland/GPU (Mesa RADV, VA-API radeonsi,
PipeWire directo, webcam HP /dev/video*, temas adw-gtk3 y fuentes) e instala catálogos desacoplados.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones de Instalación:${NC}
  (sin argumentos)    Instala el perfil estándar recomendado + overrides Wayland/AMD
  --all               Instala todo el catálogo (Esenciales + Dev + Multimedia + Ofimática)
  --essential         Instala utilidades base (Flatseal, Warehouse, Extension Manager, LocalSend, adw-gtk3)
  --dev               Instala suite de desarrollo (Podman Desktop, Bruno, DBeaver)
  --multimedia        Instala suite multimedia acelerada por GPU (VLC, Celluloid, OBS, Kdenlive, Shotcut, Spotify)
  --office            Instala productividad y comunicación (Obsidian, OnlyOffice, Vesktop, Telegram)

${BOLD}Alcance de Instalación:${NC}
  --user              Instala en espacio de usuario rootless (~/.local/share/flatpak)
  --system            Instala a nivel de sistema (/var/lib/flatpak) requiriendo privilegios

${BOLD}Mantenimiento y Diagnóstico:${NC}
  --overrides         Aplica o actualiza los overrides globales y por aplicación para Wayland/AMD
  --reset-overrides   Restablece todos los overrides a los valores por defecto
  --repair            Verifica y repara inconsistencias en el repositorio Flatpak
  --update            Actualiza todas las aplicaciones y runtimes (sistema y usuario)
  --clean             Elimina runtimes huérfanos y limpia cachés no utilizadas
  -s, --status        Muestra diagnóstico completo de repositorios, catálogo, hardware y overrides
  -h, --help          Muestra esta ayuda
EOF
}

# ------------------------------------------------------------------------------
# 5. CONFIGURACIÓN DEL REPOSITORIO FLATHUB (SIN FILTROS)
# ------------------------------------------------------------------------------
ensure_flatpak_flathub() {
    if ! command -v flatpak &>/dev/null; then
        log_info "Instalando flatpak y portal GNOME mediante pacman..."
        if [[ $EUID -eq 0 ]]; then
            pacman -S --needed --noconfirm flatpak xdg-desktop-portal-gnome
        else
            sudo pacman -S --needed --noconfirm flatpak xdg-desktop-portal-gnome
        fi
    fi

    # Configuración de Flathub a nivel de sistema si tenemos privilegios o estamos en scope system
    if [[ "$INSTALL_SCOPE" == "system" ]] || [[ $EUID -eq 0 ]]; then
        if [[ $EUID -eq 0 ]]; then
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
            flatpak remote-modify --enable flathub --no-filter 2>/dev/null || true
        else
            sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
            sudo flatpak remote-modify --enable flathub --no-filter 2>/dev/null || true
        fi
    elif sudo -n true 2>/dev/null; then
        sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
        sudo flatpak remote-modify --enable flathub --no-filter 2>/dev/null || true
    fi

    # Configuración de Flathub a nivel de usuario rootless (siempre garantizada)
    run_as_user flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    run_as_user flatpak remote-modify --user --enable flathub --no-filter 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# 6. APLICACIÓN DE OVERRIDES (WAYLAND, AMD GPU, PIPEWIRE, FUENTES Y TEMAS)
# ------------------------------------------------------------------------------
apply_overrides() {
    detect_gnome_settings
    log_info "Optimizando overrides Flatpak para AMD Radeon Vega 8, GNOME Wayland y PipeWire..."
    log_info "Cursor detectado: ${DETECTED_CURSOR_THEME} (${DETECTED_CURSOR_SIZE}px) | Tema: ${DETECTED_COLOR_SCHEME}"

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
        --filesystem=xdg-data/icons:ro \
        --filesystem=~/.icons:ro \
        --filesystem=xdg-data/fonts:ro \
        --filesystem=~/.fonts:ro \
        --env=XCURSOR_THEME="${DETECTED_CURSOR_THEME}" \
        --env=XCURSOR_SIZE="${DETECTED_CURSOR_SIZE}" \
        --env=XDG_CURRENT_DESKTOP=GNOME \
        --env=ELECTRON_OZONE_PLATFORM_HINT=auto \
        2>/dev/null || true

    # Overrides a nivel de sistema si se ejecuta con privilegios
    if [[ $EUID -eq 0 ]]; then
        flatpak override \
            --socket=wayland \
            --socket=fallback-x11 \
            --socket=pulseaudio \
            --filesystem=xdg-run/pipewire-0:ro \
            --device=dri \
            --env=ELECTRON_OZONE_PLATFORM_HINT=auto \
            2>/dev/null || true
    elif sudo -n true 2>/dev/null; then
        sudo flatpak override \
            --socket=wayland \
            --socket=fallback-x11 \
            --socket=pulseaudio \
            --filesystem=xdg-run/pipewire-0:ro \
            --device=dri \
            --env=ELECTRON_OZONE_PLATFORM_HINT=auto \
            2>/dev/null || true
    fi

    # --------------------------------------------------------------------------
    # Overrides específicos por aplicación para máxima fidelidad y hardware AMD
    # --------------------------------------------------------------------------

    # 1. Obsidian: renderizado Wayland nítido sin borrosidad en triple pantalla FHD
    run_as_user flatpak override --user md.obsidian.Obsidian \
        --socket=wayland \
        --env=ELECTRON_OZONE_PLATFORM_HINT=auto \
        --filesystem=xdg-documents:rw \
        2>/dev/null || true

    # 2. Vesktop: cliente Discord nativo Wayland, captura PipeWire y acceso a webcam
    run_as_user flatpak override --user dev.vencord.Vesktop \
        --socket=wayland \
        --device=dri \
        --device=all \
        --env=ELECTRON_OZONE_PLATFORM_HINT=auto \
        --talk-name=org.freedesktop.portal.Desktop \
        --talk-name=org.freedesktop.portal.ScreenCast \
        --filesystem=xdg-download:rw \
        --filesystem=xdg-pictures:ro \
        2>/dev/null || true

    # 3. OBS Studio: aceleración GPU DRI AMD, PipeWire directo, webcam HP y carpetas
    run_as_user flatpak override --user com.obsproject.Studio \
        --socket=wayland \
        --device=dri \
        --device=all \
        --env=LIBVA_DRIVER_NAME=radeonsi \
        --filesystem=xdg-run/pipewire-0:ro \
        --filesystem=xdg-videos:rw \
        --filesystem=xdg-pictures:rw \
        2>/dev/null || true

    # 4. Celluloid: aceleración de hardware VA-API AMD Radeon Vega 8 (radeonsi)
    run_as_user flatpak override --user io.github.celluloid_player.Celluloid \
        --socket=wayland \
        --device=dri \
        --env=LIBVA_DRIVER_NAME=radeonsi \
        --env=VDPAU_DRIVER=radeonsi \
        --filesystem=xdg-videos:ro \
        --filesystem=xdg-download:ro \
        2>/dev/null || true

    # 5. VLC: reproducción por hardware VA-API / VDPAU y audio PipeWire
    run_as_user flatpak override --user org.videolan.VLC \
        --socket=wayland \
        --device=dri \
        --env=LIBVA_DRIVER_NAME=radeonsi \
        --env=VDPAU_DRIVER=radeonsi \
        --filesystem=xdg-videos:ro \
        --filesystem=xdg-download:ro \
        2>/dev/null || true

    # 6. Kdenlive & Shotcut: edición de video acelerada por GPU AMD
    run_as_user flatpak override --user org.kde.kdenlive \
        --socket=wayland \
        --device=dri \
        --env=LIBVA_DRIVER_NAME=radeonsi \
        --filesystem=xdg-videos:rw \
        --filesystem=xdg-download:rw \
        2>/dev/null || true

    run_as_user flatpak override --user org.shotcut.Shotcut \
        --socket=wayland \
        --device=dri \
        --env=LIBVA_DRIVER_NAME=radeonsi \
        --filesystem=xdg-videos:rw \
        --filesystem=xdg-download:rw \
        2>/dev/null || true

    # 7. Podman Desktop: integración con socket rootless y Quadlets de usuario
    run_as_user flatpak override --user io.podman_desktop.PodmanDesktop \
        --socket=wayland \
        --env=ELECTRON_OZONE_PLATFORM_HINT=auto \
        --filesystem=xdg-run/podman/podman.sock:ro \
        --filesystem=~/.config/containers:ro \
        --talk-name=org.freedesktop.Flatpak \
        2>/dev/null || true

    # 8. Bruno: cliente API ligero
    run_as_user flatpak override --user com.usebruno.Bruno \
        --socket=wayland \
        --env=ELECTRON_OZONE_PLATFORM_HINT=auto \
        --filesystem=xdg-documents:rw \
        2>/dev/null || true

    # 9. Spotify: audio PipeWire de baja latencia y aceleración DRI
    run_as_user flatpak override --user com.spotify.Client \
        --socket=pulseaudio \
        --filesystem=xdg-run/pipewire-0:ro \
        --device=dri \
        --env=ELECTRON_OZONE_PLATFORM_HINT=auto \
        2>/dev/null || true

    # 10. Telegram Desktop: Wayland nativo y acceso a cámara HP
    run_as_user flatpak override --user org.telegram.desktop \
        --socket=wayland \
        --device=dri \
        --device=all \
        --filesystem=xdg-download:rw \
        2>/dev/null || true

    # 11. OnlyOffice: documentos y almacenamiento local
    run_as_user flatpak override --user org.onlyoffice.desktopeditors \
        --socket=wayland \
        --filesystem=xdg-documents:rw \
        --filesystem=xdg-download:rw \
        --filesystem=xdg-desktop:rw \
        2>/dev/null || true

    log_ok "Overrides Wayland, GPU DRI AMD (radeonsi), PipeWire, temas e integración GNOME aplicados."
}

reset_overrides() {
    log_info "Restableciendo overrides de Flatpak..."
    run_as_user flatpak override --user --reset 2>/dev/null || true
    if [[ $EUID -eq 0 ]]; then
        flatpak override --reset 2>/dev/null || true
    elif sudo -n true 2>/dev/null; then
        sudo flatpak override --reset 2>/dev/null || true
    fi
    log_ok "Overrides de Flatpak restaurados a los valores originales de manifiesto."
}

repair_flatpak() {
    log_info "Verificando y reparando referencias del almacén Flatpak..."
    if [[ $EUID -eq 0 ]]; then
        flatpak repair
    elif sudo -n true 2>/dev/null; then
        sudo flatpak repair
    fi
    run_as_user flatpak repair --user 2>/dev/null || true
    log_ok "Reparación de Flatpak completada."
}

# ------------------------------------------------------------------------------
# 7. DIAGNÓSTICO Y ESTADO (--status)
# ------------------------------------------------------------------------------
show_status() {
    detect_gnome_settings
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🔍 ${BOLD}ESTADO DE FLATPAK Y FLATHUB - CACHYOS WORKSTATION${NC}"
    echo -e "      ${CYAN}HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)${NC}"
    echo -e "      ${MAGENTA}Entorno: GNOME Shell (Wayland / Mutter) | Triple Monitor FHD${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if ! command -v flatpak &>/dev/null; then
        echo -e "  • Binario Flatpak:           ${RED}No instalado${NC}"
        return 0
    fi

    echo -e "  • Versión Flatpak:           ${GREEN}$(flatpak --version)${NC}"
    echo -e "  • Cursor GNOME Detectado:    ${CYAN}${DETECTED_CURSOR_THEME} (${DETECTED_CURSOR_SIZE}px)${NC}"
    echo -e "  • Esquema de Color:          ${CYAN}${DETECTED_COLOR_SCHEME}${NC}"

    # Estado de Flathub a nivel sistema y usuario
    local flathub_sys="No configurado" flathub_usr="No configurado"
    if flatpak remotes 2>/dev/null | grep -q "flathub"; then
        flathub_sys="${GREEN}Sin filtros (Catálogo oficial completo)${NC}"
    fi

    if run_as_user flatpak remotes --user 2>/dev/null | grep -q "flathub"; then
        flathub_usr="${GREEN}Sin filtros (Usuario Rootless)${NC}"
    fi

    echo -e "  • Flathub (Sistema):         ${flathub_sys}"
    echo -e "  • Flathub (Usuario):         ${flathub_usr}"

    # Telemetría de Overrides activos
    local active_ov
    active_ov=$(run_as_user flatpak override --user --show 2>/dev/null || true)
    local wayland_ov="No" dri_ov="No" ozone_ov="No" pipewire_ov="No" cursor_ov="No"
    [[ "$active_ov" == *"wayland"* ]] && wayland_ov="${GREEN}Activo (Nativo Wayland)${NC}" || wayland_ov="${YELLOW}Inactivo${NC}"
    [[ "$active_ov" == *"devices=dri"* || "$active_ov" == *"dri;"* ]] && dri_ov="${GREEN}Activo (AMD GPU DRI - radeonsi)${NC}" || dri_ov="${YELLOW}Inactivo${NC}"
    [[ "$active_ov" == *"ELECTRON_OZONE_PLATFORM_HINT"* ]] && ozone_ov="${GREEN}Activo (Wayland Auto)${NC}" || ozone_ov="${YELLOW}Inactivo${NC}"
    [[ "$active_ov" == *"xdg-run/pipewire-0"* ]] && pipewire_ov="${GREEN}Activo (Direct PipeWire 0)${NC}" || pipewire_ov="${YELLOW}Inactivo${NC}"
    [[ "$active_ov" == *"XCURSOR_THEME"* ]] && cursor_ov="${GREEN}Activo (${DETECTED_CURSOR_THEME})${NC}" || cursor_ov="${YELLOW}Inactivo${NC}"

    echo ""
    echo -e "${BOLD}⚡ Overrides de Rendimiento e Integración:${NC}"
    echo -e "  • Socket Wayland:            $wayland_ov"
    echo -e "  • Aceleración GPU (DRI):     $dri_ov"
    echo -e "  • Integración PipeWire:      $pipewire_ov"
    echo -e "  • Renderizado Electron:      $ozone_ov"
    echo -e "  • Sincronización Cursores:   $cursor_ov"

    # Espacio en disco de almacenes Flatpak
    local size_sys size_usr
    size_sys=$(du -sh /var/lib/flatpak 2>/dev/null | cut -f1 || echo "0B")
    size_usr=$(du -sh "$USER_HOME/.local/share/flatpak" 2>/dev/null | cut -f1 || echo "0B")
    echo ""
    echo -e "${BOLD}💾 Espacio en Disco Utilizado (SSD NVMe):${NC}"
    echo -e "  • Almacén Sistema (/var/lib/flatpak):         ${CYAN}${size_sys}${NC}"
    echo -e "  • Almacén Usuario (~/.local/share/flatpak):   ${CYAN}${size_usr}${NC}"

    # Lista de aplicaciones y extensiones instaladas
    local installed_system installed_user
    installed_system=$(flatpak list --columns=application 2>/dev/null || true)
    installed_user=$(run_as_user flatpak list --user --columns=application 2>/dev/null || true)

    echo ""
    echo -e "${BOLD}📋 Estado del Catálogo de Aplicaciones y Temas:${NC}"
    local all_catalog=(
        "${ESSENTIAL_APPS[@]}"
        "${DEV_APPS[@]}"
        "${MULTIMEDIA_APPS[@]}"
        "${OFFICE_SOCIAL_APPS[@]}"
    )

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
    installed_system=$(flatpak list --columns=application 2>/dev/null || true)
    installed_user=$(run_as_user flatpak list --user --columns=application 2>/dev/null || true)

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
        if [[ "$INSTALL_SCOPE" == "user" ]]; then
            log_info "Instalando en espacio de usuario rootless (Flathub): ${to_install[*]}..."
            run_as_user flatpak install -y --user --noninteractive flathub "${to_install[@]}"
        elif [[ "$INSTALL_SCOPE" == "system" ]] || [[ $EUID -eq 0 ]]; then
            log_info "Instalando a nivel de sistema (Flathub): ${to_install[*]}..."
            if [[ $EUID -eq 0 ]]; then
                flatpak install -y --noninteractive flathub "${to_install[@]}"
            else
                sudo flatpak install -y --noninteractive flathub "${to_install[@]}"
            fi
        else
            # En modo auto ejecutado por usuario normal: preferir instalación rootless (--user)
            log_info "Instalando en espacio de usuario rootless (Flathub): ${to_install[*]}..."
            run_as_user flatpak install -y --user --noninteractive flathub "${to_install[@]}"
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
        --reset-overrides) MODE="reset-overrides"; shift ;;
        --repair)          MODE="repair"; shift ;;
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
    reset-overrides)
        reset_overrides
        show_status
        ;;
    repair)
        repair_flatpak
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
        if [[ $EUID -eq 0 ]]; then
            flatpak update -y
        elif sudo -n true 2>/dev/null; then
            sudo flatpak update -y
        fi
        run_as_user flatpak update --user -y 2>/dev/null || true
        log_ok "Actualización de Flatpak completada."
        ;;
    clean)
        log_info "Limpiando runtimes y dependencias huérfanas de Flatpak..."
        if [[ $EUID -eq 0 ]]; then
            flatpak uninstall --unused -y 2>/dev/null || true
        elif sudo -n true 2>/dev/null; then
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
