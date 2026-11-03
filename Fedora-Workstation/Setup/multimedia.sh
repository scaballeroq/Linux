#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  multimedia.sh - Suite Multimedia Completa + RPM Fusion Obligatorio + VA-API
#  Sistema: Fedora 45 Workstation (GNOME Wayland / AMD Radeon & Intel GPU)
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

MPV_CONF_DIR="$USER_HOME/.config/mpv"
ENV_D_DIR="$USER_HOME/.config/environment.d"
ENV_D_FILE="$ENV_D_DIR/90-fedora-multimedia.conf"

ACTION="install"

show_help() {
    cat << EOF
${BOLD}🎬 Suite Multimedia, RPM Fusion Obligatorio y Aceleración VA-API - Fedora 45 Workstation${NC}

Configura obligatoriamente ${BOLD}RPM Fusion (Free, Non-Free y Tainted)${NC} + Cisco OpenH264,
reemplaza ${BOLD}ffmpeg-free${NC} por ${BOLD}ffmpeg${NC} completo, activa ${BOLD}mesa-va-drivers-freeworld${NC}
(H.264/HEVC/AV1 por hardware en AMD Radeon), instala GStreamer completo, miniaturas
para Nautilus (${BOLD}glycin-loaders${NC}, ${BOLD}ffmpegthumbnailer${NC}, ${BOLD}libheif-ffmpeg${NC}) y optimiza
reproductores nativos Wayland (${BOLD}Showtime${NC}, ${BOLD}Loupe${NC}, ${BOLD}Amberol${NC}, ${BOLD}Celluloid${NC}, ${BOLD}MPV${NC} y ${BOLD}VLC${NC}).

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)   Instala RPM Fusion, códecs, drivers VA-API y reproductores
  -s, --status       Muestra el diagnóstico completo de RPM Fusion, códecs y VA-API
  --mpv-only         Solo genera la configuración optimizada de MPV y Celluloid
  -h, --help         Muestra esta ayuda
EOF
}

ensure_rpmfusion() {
    local fed_ver
    fed_ver=$(rpm -E %fedora)
    log_info "Verificando repositorios obligatorios RPM Fusion (Free & Non-Free) para Fedora ${fed_ver}..."
    if ! rpm -q rpmfusion-free-release &>/dev/null || ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
        log_info "Instalando RPM Fusion Free y Non-Free..."
        sudo "$DNF_BIN" install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fed_ver}.noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fed_ver}.noarch.rpm"
    else
        log_ok "RPM Fusion Free y Non-Free ya están instalados."
    fi

    sudo "$DNF_BIN" config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true

    local extra_repos=()
    for pkg in rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted; do
        rpm -q "$pkg" &>/dev/null || extra_repos+=("$pkg")
    done
    if [[ ${#extra_repos[@]} -gt 0 ]]; then
        sudo "$DNF_BIN" install -y "${extra_repos[@]}" 2>/dev/null || true
    fi
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🎬 ${BOLD}ESTADO MULTIMEDIA, RPM FUSION Y VA-API - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    echo -e "${BOLD}📦 Repositorios RPM Fusion (Obligatorios en Fedora):${NC}"
    for repo_pkg in rpmfusion-free-release rpmfusion-nonfree-release rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted; do
        if rpm -q "$repo_pkg" &>/dev/null; then
            echo -e "  • $(printf '%-33s' "$repo_pkg"): ${GREEN}Activo ($(rpm -q --queryformat '%{VERSION}' "$repo_pkg"))${NC}"
        else
            echo -e "  • $(printf '%-33s' "$repo_pkg"): ${RED}No instalado${NC}"
        fi
    done

    echo ""
    echo -e "${BOLD}🎞️  Códecs, Drivers VA-API y Miniaturas:${NC}"
    for pkg in ffmpeg mesa-va-drivers-freeworld gstreamer1-plugins-bad-freeworld gstreamer1-plugin-openh264 gstreamer1-plugin-libav ffmpegthumbnailer glycin-loaders; do
        if rpm -q "$pkg" &>/dev/null; then
            echo -e "  • $(printf '%-33s' "$pkg"): ${GREEN}Instalado${NC}"
        else
            echo -e "  • $(printf '%-33s' "$pkg"): ${YELLOW}No instalado${NC}"
        fi
    done

    echo ""
    echo -e "${BOLD}📺 Aplicaciones Multimedia GNOME Wayland:${NC}"
    for app in mpv celluloid vlc showtime loupe snapshot amberol; do
        if rpm -q "$app" &>/dev/null || command -v "$app" &>/dev/null; then
            echo -e "  • $(printf '%-33s' "$app"): ${GREEN}Instalado${NC}"
        else
            echo -e "  • $(printf '%-33s' "$app"): ${YELLOW}No instalado${NC}"
        fi
    done

    echo ""
    echo -e "${BOLD}🔊 Audio PipeWire y Configuración MPV:${NC}"
    if systemctl --user is-active --quiet pipewire 2>/dev/null || pgrep -x pipewire &>/dev/null; then
        echo -e "  • PipeWire / WirePlumber:          ${GREEN}Activo${NC}"
    else
        echo -e "  • PipeWire / WirePlumber:          ${YELLOW}No detectado en sesión actual${NC}"
    fi
    [[ -f "$MPV_CONF_DIR/mpv.conf" ]] && echo -e "  • Perfil MPV Vulkan/VA-API:        ${GREEN}${MPV_CONF_DIR}/mpv.conf${NC}" || echo -e "  • Perfil MPV Vulkan/VA-API:        ${YELLOW}No configurado${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

configure_mpv_and_env() {
    log_info "Configurando MPV (gpu-next + Vulkan Wayland + VA-API + PipeWire) en $MPV_CONF_DIR..."
    mkdir -p "$MPV_CONF_DIR" "$ENV_D_DIR"

    cat << 'EOF' > "$MPV_CONF_DIR/mpv.conf"
# ==============================================================================
#  MPV Configuration - Fedora 45 Workstation (GNOME Wayland / AMD Radeon RADV)
# ==============================================================================

# Renderizado de vídeo nativo Wayland + Vulkan
vo=gpu-next
gpu-api=vulkan
gpu-context=waylandvk
hwdec=vaapi
hwdec-codecs=all

# Calidad de escalado
profile=high-quality
scale=ewa_lanczossharp
cscale=ewa_lanczossharp
video-sync=display-resample
interpolation=yes
tscale=oversample

# Audio nativo PipeWire
ao=pipewire
volume=100
volume-max=150

# Interfaz y subtítulos
osc=yes
osd-bar=yes
sub-auto=fuzzy
sub-font="Sans"
sub-font-size=42
save-position-on-quit=yes
keep-open=yes
EOF

    cat << 'EOF' > "$MPV_CONF_DIR/input.conf"
WHEEL_UP      add volume 2
WHEEL_DOWN    add volume -2
UP            add volume 5
DOWN          add volume -5
RIGHT         seek 5
LEFT          seek -5
f             cycle fullscreen
s             screenshot
EOF

    # Configurar Celluloid para usar decodificación por hardware si el esquema existe
    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "^io.github.celluloid_player.Celluloid$"; then
        run_as_user gsettings set io.github.celluloid_player.Celluloid mpv-config-enable true 2>/dev/null || true
        run_as_user gsettings set io.github.celluloid_player.Celluloid mpv-config-file "file://$MPV_CONF_DIR/mpv.conf" 2>/dev/null || true
    fi

    # Variables de entorno multimedia para aceleración en sesión Wayland
    local gpu_vendor="amd"
    if lspci 2>/dev/null | grep -qiE "VGA|3D" && lspci 2>/dev/null | grep -E "VGA|3D" | grep -qi "Intel" && ! lspci 2>/dev/null | grep -E "VGA|3D" | grep -qiE "AMD|ATI|Radeon"; then
        gpu_vendor="intel"
    fi

    if [[ "$gpu_vendor" == "amd" ]]; then
        cat << 'EOF' > "$ENV_D_FILE"
# Aceleración VA-API y Vulkan para AMD Radeon en Fedora 45 Workstation (Wayland)
LIBVA_DRIVER_NAME=radeonsi
VDPAU_DRIVER=radeonsi
AMD_VULKAN_ICD=RADV
MOZ_ENABLE_WAYLAND=1
GST_VAAPI_ALL_DRIVERS=1
EOF
    else
        cat << 'EOF' > "$ENV_D_FILE"
# Aceleración VA-API para Intel Graphics en Fedora 45 Workstation (Wayland)
MOZ_ENABLE_WAYLAND=1
GST_VAAPI_ALL_DRIVERS=1
EOF
    fi

    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        chown -R "$REAL_USER:$REAL_USER" "$MPV_CONF_DIR" "$ENV_D_DIR"
    fi
    log_ok "MPV, Celluloid y variables de entorno multimedia configurados."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status) ACTION="status"; shift ;;
        --mpv-only)  ACTION="mpv-only"; shift ;;
        -h|--help)   show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
elif [[ "$ACTION" == "mpv-only" ]]; then
    configure_mpv_and_env
    exit 0
fi

# 1. Asegurar obligatoriamente RPM Fusion Free, Non-Free y Tainted
ensure_rpmfusion

# 2. Reemplazar ffmpeg-free por ffmpeg completo de RPM Fusion
log_info "Instalando FFmpeg completo desde RPM Fusion (--allowerasing)..."
sudo "$DNF_BIN" install -y --allowerasing ffmpeg ffmpeg-libs libavcodec-freeworld 2>/dev/null || \
    sudo "$DNF_BIN" install -y --allowerasing ffmpeg ffmpeg-libs

# 3. Activar aceleración por hardware VA-API / VDPAU (AMD Radeon Freeworld / Intel)
log_info "Configurando aceleración por hardware VA-API y Vulkan..."
if lspci 2>/dev/null | grep -E "VGA|3D" | grep -qiE "AMD|ATI|Radeon"; then
    sudo "$DNF_BIN" swap -y mesa-va-drivers mesa-va-drivers-freeworld 2>/dev/null || \
        sudo "$DNF_BIN" install -y --allowerasing mesa-va-drivers-freeworld
    sudo "$DNF_BIN" swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld 2>/dev/null || \
        sudo "$DNF_BIN" install -y --allowerasing mesa-vdpau-drivers-freeworld
fi

if lspci 2>/dev/null | grep -E "VGA|3D" | grep -qi "Intel"; then
    sudo "$DNF_BIN" install -y intel-media-driver libva-intel-driver 2>/dev/null || true
fi

# 4. Instalar pila GStreamer 1.26+, PipeWire, miniaturas Nautilus y reproductores GNOME
log_info "Instalando pila GStreamer completa, códecs de imagen/vídeo y reproductores Wayland..."
MULTIMEDIA_PKGS=(
    gstreamer1-plugins-base
    gstreamer1-plugins-good
    gstreamer1-plugins-good-extras
    gstreamer1-plugins-bad-free
    gstreamer1-plugins-bad-free-extras
    gstreamer1-plugins-bad-freeworld
    gstreamer1-plugins-ugly
    gstreamer1-plugins-ugly-free
    gstreamer1-plugin-libav
    gstreamer1-plugin-openh264
    gstreamer1-plugin-gtk4
    gstreamer1-vaapi
    mozilla-openh264
    libva-utils
    vulkan-tools
    pipewire-alsa
    pipewire-pulseaudio
    pipewire-jack-audio-connection-kit
    pipewire-plugin-libcamera
    wireplumber
    ffmpegthumbnailer
    glycin-loaders
    gdk-pixbuf2-modules-extra
    libheif-freeworld
    libheif-tools
    libwebp-tools
     ImageMagick
    lame
    flac
    opus-tools
    vorbis-tools
    mpv
    celluloid
    vlc
    loupe
)

# Filtrar paquetes disponibles e instalar de forma resiliente
sudo "$DNF_BIN" install -y --skip-unavailable "${MULTIMEDIA_PKGS[@]}" 2>/dev/null || \
    sudo "$DNF_BIN" install -y mpv celluloid vlc ffmpegthumbnailer libva-utils vulkan-tools

# Aplicaciones modernas de GNOME 48+/50 (Showtime, Snapshot, Amberol, SoundConverter)
sudo "$DNF_BIN" install -y --skip-unavailable showtime snapshot amberol soundconverter 2>/dev/null || true

# Soporte de DVD cifrado desde RPM Fusion Tainted
sudo "$DNF_BIN" install -y --enablerepo=rpmfusion-free-tainted libdvdcss 2>/dev/null || true

# 5. Configurar MPV, Celluloid y variables de entorno
configure_mpv_and_env

# Limpiar caché de miniaturas fallidas para que Nautilus regenere vistas previas con ffmpegthumbnailer y glycin
rm -rf "$USER_HOME/.cache/thumbnails/fail" 2>/dev/null || true

log_ok "Suite multimedia completa y RPM Fusion configurados en Fedora 45 Workstation."
show_status
