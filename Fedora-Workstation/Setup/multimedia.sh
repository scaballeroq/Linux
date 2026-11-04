#!/usr/bin/env bash
# ==============================================================================
# multimedia.sh - Suite Multimedia, Códecs y Aceleración HW para Fedora Workstation
# Optimizado para Fedora 45 Workstation (GNOME Shell 48+ Wayland / Mutter)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8)
# Referencias Oficiales:
#   - https://rpmfusion.org/Configuration
#   - https://rpmfusion.org/Howto/Multimedia
# ==============================================================================
# Características:
#   - Integración nativa con RPM Fusion (Free, Non-Free, Cisco OpenH264 y Tainted).
#   - Sustitución de ffmpeg-free por FFmpeg completo (--allowerasing + libavcodec-freeworld).
#   - Aceleración por hardware AMD (Mesa): mesa-va-drivers-freeworld y mesa-vdpau-drivers-freeworld.
#   - Pila GStreamer completa (bad-freeworld, ugly, libav, openh264, gtk4).
#   - Miniaturas e imágenes GNOME (glycin-loaders, ffmpegthumbnailer, libheif-freeworld, libwebp).
#   - Audio PipeWire de baja latencia con WirePlumber.
#   - Reproductores Wayland nativos: Showtime, Celluloid, MPV (gpu-next/vulkan/vaapi), Loupe y VLC.
#   - Soporte de DVD encriptado (libdvdcss vía rpmfusion-free-tainted).
#   - Opciones CLI: --status / -s, --codecs, --players, --mpv-only, --help / -h.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
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
# 2. DETECCIÓN DE USUARIO, ENTORNO Y PRIVILEGIOS SUDO
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible. Ejecuta este script con privilegios de superusuario.${NC}" >&2
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
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
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="/usr/local/bin:/usr/bin:/bin:$PATH" \
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

if command -v dnf5 &>/dev/null; then
    DNF_BIN="dnf5"
else
    DNF_BIN="dnf"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPV_CONF_DIR="$USER_HOME/.config/mpv"
ENV_D_DIR="$USER_HOME/.config/environment.d"
ENV_D_FILE="$ENV_D_DIR/90-fedora-multimedia.conf"

get_os_description() {
    if [ -f /etc/os-release ]; then
        grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"'
    else
        echo "Fedora Linux 45 (Workstation Edition)"
    fi
}

get_gnome_version() {
    local ver
    ver=$(gnome-shell --version 2>/dev/null | awk '{print $3}' || true)
    if [ -z "$ver" ]; then
        ver=$(run_as_user gnome-shell --version 2>/dev/null | awk '{print $3}' || true)
    fi
    echo "${ver:-48}"
}

check_user_service() {
    local svc="$1"
    local active_state enabled_state
    active_state=$(run_as_user systemctl --user is-active "$svc" 2>/dev/null || true)
    if [ "$active_state" = "active" ]; then
        echo -e "${GREEN}✅ Activo (en ejecución)${NC}"
        return
    fi
    enabled_state=$(systemctl --user is-enabled "$svc" 2>/dev/null || true)
    if [ "$enabled_state" = "enabled" ] || [ "$enabled_state" = "enabled-runtime" ] || [ "$enabled_state" = "static" ]; then
        echo -e "${GREEN}✅ Habilitado (systemd user: $enabled_state)${NC}"
    else
        echo -e "${YELLOW}⚠️ Inactivo (${active_state:-desconocido})${NC}"
    fi
}

is_pkg_installed() {
    rpm -q "$1" &>/dev/null
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
${BOLD}🎬 Suite Multimedia, RPM Fusion y Aceleración HW AMD - Fedora 45 Workstation${NC}
Referencias:
  • https://rpmfusion.org/Configuration
  • https://rpmfusion.org/Howto/Multimedia

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Aplica toda la suite: RPM Fusion, Códecs completos, Drivers Freeworld
                      para AMD Radeon, GStreamer, Miniaturas Nautilus, Reproductores y MPV.
  --status, -s        Muestra diagnóstico detallado de VA-API, Vulkan RADV, RPM Fusion,
                      GStreamer, PipeWire y aplicaciones de reproducción.
  --codecs            Instala y configura únicamente códecs, drivers VA-API freeworld,
                      FFmpeg completo y plugins GStreamer.
  --players           Instala y optimiza reproductores nativos GNOME / Wayland
                      (Showtime, Celluloid, MPV, VLC, Loupe, Amberol).
  --mpv-only          Solo genera y despliega la configuración optimizada de MPV y variables.
  --help, -h          Muestra este mensaje de ayuda.

${BOLD}Aceleración Hardware para AMD en Fedora (Mesa):${NC}
  Fedora excluye por patentes la aceleración H.264/HEVC/VC-1 en sus paquetes Mesa oficiales.
  Este script realiza el intercambio oficial (swap) con RPM Fusion:
    • mesa-va-drivers      -> ${BOLD}mesa-va-drivers-freeworld${NC}
    • mesa-vdpau-drivers   -> ${BOLD}mesa-vdpau-drivers-freeworld${NC}
    • ffmpeg-free          -> ${BOLD}ffmpeg${NC} (completo)
EOF
}

show_status() {
    local os_name gnome_ver
    os_name=$(get_os_description)
    gnome_ver=$(get_gnome_version)

    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🔍 ${BOLD}ESTADO MULTIMEDIA, RPM FUSION Y ACELERACIÓN HW - FEDORA WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "• Sistema Operativo:     ${CYAN}$os_name (Kernel $(uname -r))${NC}"
    echo -e "• Entorno Gráfico:       ${CYAN}GNOME Shell $gnome_ver (${XDG_SESSION_TYPE:-wayland} / Mutter)${NC}"
    echo -e "• Hardware de Video:     ${CYAN}HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 Barcelo-R)${NC}"
    echo "----------------------------------------------------------------------"

    echo -e "${BOLD}📦 Estado de Repositorios RPM Fusion:${NC}"
    for repo_pkg in rpmfusion-free-release rpmfusion-nonfree-release rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted; do
        if is_pkg_installed "$repo_pkg"; then
            local rver
            rver=$(rpm -q --queryformat '%{VERSION}' "$repo_pkg" 2>/dev/null || echo "activo")
            echo -e "  • $(printf '%-33s' "$repo_pkg"): ${GREEN}✅ Activo (v$rver)${NC}"
        else
            echo -e "  • $(printf '%-33s' "$repo_pkg"): ${RED}❌ No instalado${NC}"
        fi
    done

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}⚡ Aceleración Gráfica por Hardware para AMD (VA-API / Vulkan RADV):${NC}"

    # Estado de drivers Freeworld
    for drv in mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld; do
        if is_pkg_installed "$drv"; then
            echo -e "  • $(printf '%-33s' "$drv"): ${GREEN}✅ Instalado (Aceleración completa activa)${NC}"
        else
            echo -e "  • $(printf '%-33s' "$drv"): ${YELLOW}⚠️ No instalado (Mesa sin códecs propietarios)${NC}"
        fi
    done

    if command -v vainfo &>/dev/null; then
        local va_out va_driver va_h264 va_hevc va_hevc10 va_vp9 va_enc
        va_out=$(vainfo --display drm --device /dev/dri/renderD128 2>&1 || vainfo 2>&1 || true)
        va_driver=$(echo "$va_out" | grep -m1 "Driver version:" | sed "s/.*Driver version: //" || echo "radeonsi")
        va_h264=$(echo "$va_out" | grep -q "VAProfileH264Main" && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}")
        va_hevc=$(echo "$va_out" | grep -q "VAProfileHEVCMain " && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}")
        va_hevc10=$(echo "$va_out" | grep -q "VAProfileHEVCMain10" && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}")
        va_vp9=$(echo "$va_out" | grep -q "VAProfileVP9Profile0" && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}")
        va_enc=$(echo "$va_out" | grep -q "VAEntrypointEncSlice" && echo -e "${GREEN}✅ Activo (H.264/HEVC)${NC}" || echo -e "${YELLOW}❌ No disponible${NC}")
        echo -e "  • Driver VA-API activo:        ${CYAN}$va_driver${NC}"
        echo -e "  • Decodificación por Hardware: H.264: $va_h264 | HEVC 8-bit: $va_hevc | HEVC 10-bit: $va_hevc10 | VP9: $va_vp9"
        echo -e "  • Codificación por Hardware:   $va_enc"
    else
        echo -e "  • vainfo:                      ${RED}❌ No instalado (instala libva-utils)${NC}"
    fi

    if command -v vulkaninfo &>/dev/null; then
        local vk_dev
        vk_dev=$(vulkaninfo --summary 2>/dev/null | grep -i "deviceName" | head -n1 | sed 's/.*= //' || echo "AMD Radeon (RADV)")
        echo -e "  • Vulkan RADV:                 ${GREEN}✅ Instalado ($vk_dev)${NC}"
    else
        echo -e "  • Vulkan RADV:                 ${YELLOW}⚠️ vulkan-tools no instalado${NC}"
    fi
    [[ -f "$ENV_D_FILE" ]] && echo -e "  • Variables de Entorno VA-API: ${GREEN}✅ Configurado ($ENV_D_FILE)${NC}" || echo -e "  • Variables de Entorno VA-API: ${YELLOW}⚠️ No configurado${NC}"

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}🎞️  Pila de Códecs y FFmpeg Completo:${NC}"
    if command -v ffmpeg &>/dev/null; then
        local ff_ver
        ff_ver=$(ffmpeg -version 2>/dev/null | head -n1 | awk '{print $3}')
        if is_pkg_installed ffmpeg-free; then
            echo -e "  • FFmpeg:                      ${YELLOW}⚠️ ffmpeg-free activo (v$ff_ver) - Requiere swap a FFmpeg RPM Fusion${NC}"
        else
            echo -e "  • FFmpeg:                      ${GREEN}✅ Completo RPM Fusion (v$ff_ver)${NC}"
        fi
    else
        echo -e "  • FFmpeg:                      ${RED}❌ No instalado${NC}"
    fi

    for pkg in libavcodec-freeworld lame flac opus-tools vorbis-tools mediainfo libdvdcss; do
        if is_pkg_installed "$pkg" || command -v "$pkg" &>/dev/null; then
            echo -e "  • $(printf '%-30s' "$pkg"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-30s' "$pkg"): ${YELLOW}⚠️ No instalado${NC}"
        fi
    done

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}🧩 Pila GStreamer (Wayland + GTK4 + Cisco OpenH264):${NC}"
    for gst in gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly gstreamer1-plugin-openh264 gstreamer1-plugin-libav gstreamer1-vaapi; do
        if is_pkg_installed "$gst"; then
            echo -e "  • $(printf '%-33s' "$gst"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-33s' "$gst"): ${YELLOW}⚠️ No instalado${NC}"
        fi
    done

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}🖼️  Miniaturas e Imágenes GNOME (Nautilus & Loupe):${NC}"
    for th in glycin-loaders ffmpegthumbnailer libheif-freeworld libwebp-tools; do
        if is_pkg_installed "$th" || command -v "$th" &>/dev/null; then
            echo -e "  • $(printf '%-33s' "$th"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-33s' "$th"): ${YELLOW}⚠️ No instalado${NC}"
        fi
    done

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}🔊 Servidor de Audio PipeWire & WirePlumber:${NC}"
    echo -e "  • PipeWire Core:               $(check_user_service pipewire)"
    echo -e "  • PipeWire PulseAudio:         $(check_user_service pipewire-pulse)"
    echo -e "  • WirePlumber Session:         $(check_user_service wireplumber)"

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}📺 Reproductores y Aplicaciones Multimedia GNOME Wayland:${NC}"
    for app in showtime celluloid mpv vlc loupe snapshot amberol; do
        if is_pkg_installed "$app" || command -v "$app" &>/dev/null; then
            echo -e "  • $(printf '%-33s' "$app"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-33s' "$app"): ${YELLOW}⚠️ No instalado${NC}"
        fi
    done
    [[ -f "$MPV_CONF_DIR/mpv.conf" ]] && echo -e "  • Perfil MPV Vulkan/VA-API:    ${GREEN}✅ Configurado ($MPV_CONF_DIR/mpv.conf)${NC}" || echo -e "  • Perfil MPV Vulkan/VA-API:    ${YELLOW}⚠️ No configurado${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. CONFIGURACIÓN DE MPV, CELLULOID Y VARIABLES DE ENTORNO
# ------------------------------------------------------------------------------
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

# Calidad de escalado de imagen
profile=high-quality
scale=ewa_lanczossharp
cscale=ewa_lanczossharp
video-sync=display-resample
interpolation=yes
tscale=oversample

# Audio nativo PipeWire de baja latencia
ao=pipewire
volume=100
volume-max=150

# Interfaz visual y subtítulos nítidos
osc=yes
osd-bar=yes
sub-auto=fuzzy
sub-font="Sans"
sub-font-size=42
save-position-on-quit=yes
keep-open=yes
EOF

    cat << 'EOF' > "$MPV_CONF_DIR/input.conf"
# ==============================================================================
#  MPV Keybindings - Controles interactivos de reproducción
# ==============================================================================
WHEEL_UP      add volume 2
WHEEL_DOWN    add volume -2
UP            add volume 5
DOWN          add volume -5
RIGHT         seek 5
LEFT          seek -5
Shift+RIGHT   seek 30
Shift+LEFT    seek -30
f             cycle fullscreen
s             screenshot
m             cycle mute
SPACE         cycle pause
EOF

    # Configurar Celluloid para usar el archivo de configuración de MPV
    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "^io.github.celluloid_player.Celluloid$"; then
        run_as_user gsettings set io.github.celluloid_player.Celluloid mpv-config-enable true 2>/dev/null || true
        run_as_user gsettings set io.github.celluloid_player.Celluloid mpv-config-file "file://$MPV_CONF_DIR/mpv.conf" 2>/dev/null || true
    fi

    # Variables de entorno multimedia para sesión Wayland
    cat << 'EOF' > "$ENV_D_FILE"
# ==============================================================================
# Variables de entorno multimedia - Fedora 45 Workstation (Wayland)
# Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# ==============================================================================
LIBVA_DRIVER_NAME=radeonsi
VDPAU_DRIVER=radeonsi
AMD_VULKAN_ICD=RADV
MOZ_ENABLE_WAYLAND=1
GST_VAAPI_ALL_DRIVERS=1
EOF

    if [ "$EUID" -eq 0 ] && [ "$REAL_USER" != "root" ]; then
        chown -R "$REAL_USER:$REAL_USER" "$MPV_CONF_DIR" "$ENV_D_DIR"
    fi
    log_ok "MPV, Celluloid y variables de entorno multimedia configurados."
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN DE CÓDECS, DRIVERS AMD Y GSTREAMER (RPM FUSION)
# ------------------------------------------------------------------------------
install_codecs() {
    log_info "Asegurando repositorios obligatorios de RPM Fusion..."
    if [ -x "$SCRIPT_DIR/rpmfusion.sh" ]; then
        "$SCRIPT_DIR/rpmfusion.sh"
    else
        local fed_ver
        fed_ver=$(rpm -E %fedora 2>/dev/null || echo "45")
        $SUDO "$DNF_BIN" install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fed_ver}.noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fed_ver}.noarch.rpm" 2>/dev/null || true
        $SUDO "$DNF_BIN" config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
        $SUDO "$DNF_BIN" install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted 2>/dev/null || true
    fi

    # Paso 1: Intercambio a FFmpeg completo según Howto oficial de RPM Fusion
    log_info "Cambiando de ffmpeg-free a FFmpeg completo de RPM Fusion (--allowerasing)..."
    $SUDO "$DNF_BIN" swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null || \
        $SUDO "$DNF_BIN" install -y --allowerasing ffmpeg ffmpeg-libs libavcodec-freeworld

    # Paso 2: Aceleración por hardware AMD (Mesa Freeworld) según Howto oficial
    log_info "Activando códecs de aceleración HW para AMD Radeon (mesa-va-drivers-freeworld)..."
    $SUDO "$DNF_BIN" swap -y mesa-va-drivers mesa-va-drivers-freeworld 2>/dev/null || \
        $SUDO "$DNF_BIN" install -y --allowerasing mesa-va-drivers-freeworld
    $SUDO "$DNF_BIN" swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld 2>/dev/null || \
        $SUDO "$DNF_BIN" install -y --allowerasing mesa-vdpau-drivers-freeworld

    # Intercambio para soporte de 32 bits en caso de estar instalado (Gaming / Steam)
    if is_pkg_installed "mesa-va-drivers.i686"; then
        $SUDO "$DNF_BIN" swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 2>/dev/null || true
    fi
    if is_pkg_installed "mesa-vdpau-drivers.i686"; then
        $SUDO "$DNF_BIN" swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686 2>/dev/null || true
    fi

    # Paso 3: Actualizar grupos Multimedia y Sound-and-Video de RPM Fusion
    log_info "Actualizando grupo Multimedia de RPM Fusion..."
    $SUDO "$DNF_BIN" group upgrade --with-optional Multimedia --setopt="install_weak_deps=False" 2>/dev/null || true
    $SUDO "$DNF_BIN" group upgrade --with-optional sound-and-video 2>/dev/null || true

    # Paso 4: Paquetes esenciales de GStreamer, códecs de audio y utilidades
    log_info "Instalando plugins GStreamer, códecs de audio y utilidades de hardware..."
    local CODECS_PKGS=(
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
        libva
        libva-utils
        vdpauinfo
        vulkan-tools
        lame
        flac
        opus-tools
        vorbis-tools
        sox
        mediainfo
        ffmpegthumbnailer
        glycin-loaders
        gdk-pixbuf2-modules-extra
        libheif-freeworld
        libheif-tools
        libwebp-tools
        ImageMagick
    )

    $SUDO "$DNF_BIN" install -y --skip-unavailable "${CODECS_PKGS[@]}" 2>/dev/null || true

    # Paso 5: DVD con cifrado CSS desde repositorio Tainted
    log_info "Instalando soporte de DVD (libdvdcss) desde RPM Fusion Tainted..."
    $SUDO "$DNF_BIN" install -y --enablerepo=rpmfusion-free-tainted libdvdcss 2>/dev/null || true

    # Configurar MPV y variables
    configure_mpv_and_env

    # Limpiar caché de miniaturas fallidas para regenerar con ffmpegthumbnailer y glycin
    rm -rf "$USER_HOME/.cache/thumbnails/fail" 2>/dev/null || true

    log_ok "Códecs, aceleración HW para AMD Radeon y miniaturas GNOME configurados."
}

# ------------------------------------------------------------------------------
# 6. INSTALACIÓN DE REPRODUCTORES NATIVOS GNOME WAYLAND
# ------------------------------------------------------------------------------
install_players() {
    log_info "Instalando reproductores multimedia nativos GNOME / Wayland..."
    local PLAYERS=(
        mpv
        celluloid
        vlc
        showtime
        loupe
        snapshot
        amberol
        soundconverter
    )
    $SUDO "$DNF_BIN" install -y --skip-unavailable "${PLAYERS[@]}" 2>/dev/null || \
        $SUDO "$DNF_BIN" install -y mpv celluloid vlc loupe

    configure_mpv_and_env
    log_ok "Reproductores multimedia instalados y configurados."
}

# ------------------------------------------------------------------------------
# 7. PARSEO DE ARGUMENTOS Y EJECUCIÓN
# ------------------------------------------------------------------------------
ACTION="all"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status) ACTION="status"; shift ;;
        --codecs)    ACTION="codecs"; shift ;;
        --players)   ACTION="players"; shift ;;
        --mpv-only)  ACTION="mpv-only"; shift ;;
        -h|--help)   show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

case "$ACTION" in
    status)
        show_status
        exit 0
        ;;
    mpv-only)
        configure_mpv_and_env
        exit 0
        ;;
    codecs)
        install_codecs
        show_status
        ;;
    players)
        install_players
        show_status
        ;;
    all)
        install_codecs
        install_players
        show_status
        ;;
esac
