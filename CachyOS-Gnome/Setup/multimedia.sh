#!/usr/bin/env bash
# ==============================================================================
# multimedia.sh - Suite Multimedia, Códecs y Aceleración HW para Fedora Workstation
# Optimizado para Fedora 45 Workstation (GNOME Shell Wayland / Mutter)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8 Barcelo-R)
# Referencias Oficiales:
#   - https://rpmfusion.org/Configuration
#   - https://rpmfusion.org/Howto/Multimedia
# ==============================================================================
# Características:
#   - Integración nativa e idempotente con RPM Fusion (Free, Non-Free, Cisco OpenH264 y Tainted).
#   - Sustitución eficiente de ffmpeg-free por FFmpeg completo (--allowerasing + ffmpeg-libs).
#   - Aceleración por hardware AMD Radeon (Mesa): mesa-va-drivers-freeworld (VCN H.264/HEVC/VP9).
#   - Pila GStreamer completa (bad-freeworld, ugly, libav, openh264, gtk4, dav1d, pipewire).
#   - Miniaturas e imágenes GNOME (glycin-loaders, ffmpegthumbnailer, libheif-freeworld, libwebp).
#   - Audio PipeWire de baja latencia con WirePlumber y códecs Bluetooth de alta fidelidad (aptX).
#   - Reproductores Wayland nativos: Showtime, Celluloid, MPV (gpu-next/vulkan/vaapi), VLC y Loupe.
#   - Soporte de DVD con cifrado CSS (libdvdcss vía rpmfusion-free-tainted).
#   - Ejecución sin sudo para diagnósticos (--status) y configuración de usuario (--mpv-only).
#   - Opciones CLI: --status / -s, --codecs / -c, --players / -p, --mpv-only / -m,
#                   --hwaccel / --amd, --thumbnails, --help / -h.
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
# 2. DETECCIÓN DE USUARIO, ENTORNO Y GESTOR DE PAQUETES
# ------------------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo &> /dev/null; then
            log_err "'sudo' no está disponible. Ejecuta este comando con privilegios de superusuario."
            exit 1
        fi
        SUDO="sudo"
    else
        SUDO=""
    fi
}

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
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
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
SYS_ENV_D_DIR="/etc/environment.d"
SYS_ENV_D_FILE="$SYS_ENV_D_DIR/90-fedora-multimedia.conf"

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
    echo "${ver:-51}"
}

check_user_service() {
    local svc="$1"
    local active_state enabled_state
    active_state=$(run_as_user systemctl --user is-active "$svc" 2>/dev/null || true)
    if [ "$active_state" = "active" ]; then
        echo -e "${GREEN}✅ Activo (en ejecución)${NC}"
        return
    fi
    enabled_state=$(run_as_user systemctl --user is-enabled "$svc" 2>/dev/null || true)
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
${BOLD}🎬 Suite Multimedia, RPM Fusion y Aceleración HW AMD - Fedora Workstation${NC}
Referencias Oficiales:
  • https://rpmfusion.org/Configuration
  • https://rpmfusion.org/Howto/Multimedia

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Aplica la suite completa: RPM Fusion, Códecs completos, Drivers Freeworld
                      para AMD Radeon, GStreamer, Miniaturas Nautilus, Reproductores y MPV.
  -s, --status        Muestra diagnóstico detallado de VA-API, Vulkan RADV, RPM Fusion,
                      GStreamer, PipeWire, miniaturas y aplicaciones (no requiere sudo).
  -c, --codecs        Instala y configura únicamente códecs, drivers VA-API freeworld,
                      FFmpeg completo y plugins GStreamer.
  -p, --players       Instala y optimiza reproductores nativos GNOME / Wayland
                      (Showtime, Celluloid, MPV, VLC, Loupe, Snapshot).
  -m, --mpv-only      Genera y despliega la configuración optimizada de MPV, Celluloid y
                      variables de entorno Wayland (no requiere sudo).
  --hwaccel, --amd    Configura exclusivamente la aceleración por hardware Mesa Freeworld para AMD.
  --thumbnails        Instala loaders y thumbnailers para Nautilus (glycin, ffmpegthumbnailer)
                      y limpia la caché de miniaturas fallidas.
  -h, --help          Muestra este mensaje de ayuda.

${BOLD}Aceleración Hardware para AMD en Fedora (Mesa):${NC}
  Fedora excluye por patentes la aceleración H.264/HEVC/VC-1 en sus paquetes Mesa oficiales.
  Este script realiza el intercambio oficial (swap) con RPM Fusion de forma idempotente:
    • mesa-va-drivers      -> ${BOLD}mesa-va-drivers-freeworld${NC}
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
            echo -e "  • $(printf '%-34s' "$repo_pkg"): ${GREEN}✅ Activo (v$rver)${NC}"
        else
            echo -e "  • $(printf '%-34s' "$repo_pkg"): ${RED}❌ No instalado${NC}"
        fi
    done

    # Cisco OpenH264
    local openh264_status
    if $DNF_BIN repolist --enabled 2>/dev/null | grep -qi "fedora-cisco-openh264"; then
        openh264_status="${GREEN}✅ Habilitado${NC}"
    else
        openh264_status="${YELLOW}⚠️ Deshabilitado o no presente${NC}"
    fi
    echo -e "  • $(printf '%-34s' "fedora-cisco-openh264"): $openh264_status"

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}⚡ Aceleración Gráfica por Hardware para AMD (VA-API / Vulkan RADV):${NC}"

    if is_pkg_installed "mesa-va-drivers-freeworld"; then
        echo -e "  • $(printf '%-34s' "mesa-va-drivers-freeworld"): ${GREEN}✅ Instalado (Aceleración completa activa)${NC}"
    else
        echo -e "  • $(printf '%-34s' "mesa-va-drivers-freeworld"): ${YELLOW}⚠️ No instalado (Mesa sin códecs propietarios)${NC}"
    fi

    if is_pkg_installed "mesa-vdpau-drivers-freeworld"; then
        echo -e "  • $(printf '%-34s' "mesa-vdpau-drivers-freeworld"): ${GREEN}✅ Instalado${NC}"
    elif $DNF_BIN repoquery mesa-vdpau-drivers-freeworld 2>/dev/null | grep -q "mesa-vdpau-drivers-freeworld"; then
        echo -e "  • $(printf '%-34s' "mesa-vdpau-drivers-freeworld"): ${YELLOW}⚠️ No instalado${NC}"
    else
        echo -e "  • $(printf '%-34s' "VDPAU (Mesa X11 legacy)"): ${CYAN}ℹ️  Obsoleto en Mesa 24+ / Sustituido por VA-API Wayland${NC}"
    fi

    if command -v vainfo &>/dev/null; then
        local va_out va_driver va_h264 va_hevc va_hevc10 va_vp9 va_vc1 va_enc
        va_out=$(vainfo --display drm --device /dev/dri/renderD128 2>&1 || vainfo 2>&1 || true)
        va_driver=$(echo "$va_out" | grep -m1 "Driver version:" | sed "s/.*Driver version: //" || echo "radeonsi")
        va_h264=$(echo "$va_out" | grep -q "VAProfileH264Main" && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}")
        va_hevc=$(echo "$va_out" | grep -q "VAProfileHEVCMain " && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}")
        va_hevc10=$(echo "$va_out" | grep -q "VAProfileHEVCMain10" && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}")
        va_vp9=$(echo "$va_out" | grep -q "VAProfileVP9Profile0" && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}")
        va_vc1=$(echo "$va_out" | grep -q "VAProfileVC1Advanced" && echo -e "${GREEN}✅${NC}" || echo -e "${YELLOW}❌${NC}")
        va_enc=$(echo "$va_out" | grep -q "VAEntrypointEncSlice" && echo -e "${GREEN}✅ Activa (H.264 / HEVC slices)${NC}" || echo -e "${YELLOW}❌ No disponible${NC}")
        echo -e "  • Driver VA-API activo              : ${CYAN}$va_driver${NC}"
        echo -e "  • Decodificación por Hardware       : H.264: $va_h264 | HEVC (8/10-bit): $va_hevc/$va_hevc10 | VP9: $va_vp9 | VC-1: $va_vc1 | AV1: ${CYAN}CPU (dav1d)${NC}"
        echo -e "  • Codificación por Hardware         : $va_enc"
    else
        echo -e "  • vainfo                            : ${RED}❌ No instalado (instala libva-utils)${NC}"
    fi

    if command -v vulkaninfo &>/dev/null; then
        local vk_out vk_dev vk_drv vk_api
        vk_out=$(vulkaninfo --summary 2>/dev/null || true)
        vk_dev=$(echo "$vk_out" | grep -m1 "deviceName" | sed 's/.*= //' || echo "AMD Radeon Graphics (RADV RENOIR)")
        vk_drv=$(echo "$vk_out" | grep -m1 "driverInfo" | sed 's/.*= //' || echo "Mesa")
        vk_api=$(echo "$vk_out" | grep -m1 "apiVersion" | sed 's/.*= //' || echo "1.4")
        echo -e "  • Vulkan RADV                       : ${GREEN}✅ Activo ($vk_dev - $vk_drv - API $vk_api)${NC}"
    else
        echo -e "  • Vulkan RADV                       : ${YELLOW}⚠️ vulkan-tools no instalado${NC}"
    fi

    if [[ -f "$ENV_D_FILE" || -f "$SYS_ENV_D_FILE" ]]; then
        local target_env="${ENV_D_FILE}"
        [[ -f "$SYS_ENV_D_FILE" ]] && target_env="$SYS_ENV_D_FILE"
        echo -e "  • Variables de Entorno VA-API       : ${GREEN}✅ Configurado ($target_env)${NC}"
    else
        echo -e "  • Variables de Entorno VA-API       : ${YELLOW}⚠️ No configurado${NC}"
    fi

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}🎞️  Pila de Códecs y FFmpeg Completo:${NC}"
    if command -v ffmpeg &>/dev/null; then
        local ff_ver
        ff_ver=$(ffmpeg -version 2>/dev/null | head -n1 | awk '{print $3}')
        if is_pkg_installed ffmpeg-free; then
            echo -e "  • FFmpeg                            : ${YELLOW}⚠️ ffmpeg-free activo (v$ff_ver) - Requiere swap a FFmpeg RPM Fusion${NC}"
        else
            echo -e "  • FFmpeg                            : ${GREEN}✅ Completo RPM Fusion (v$ff_ver - H.264/HEVC/Vulkan/VA-API)${NC}"
        fi
    else
        echo -e "  • FFmpeg                            : ${RED}❌ No instalado${NC}"
    fi

    # libavcodec verificación precisa (ffmpeg-libs RPM Fusion vs libavcodec-freeworld)
    if is_pkg_installed libavcodec-freeworld; then
        echo -e "  • $(printf '%-34s' "libavcodec"): ${GREEN}✅ Instalado (libavcodec-freeworld)${NC}"
    elif is_pkg_installed ffmpeg-libs; then
        local vendor
        vendor=$(rpm -q --queryformat '%{VENDOR}' ffmpeg-libs 2>/dev/null || true)
        if [[ "$vendor" =~ "RPM Fusion" ]]; then
            echo -e "  • $(printf '%-34s' "libavcodec"): ${GREEN}✅ Activo (Integrado en ffmpeg-libs RPM Fusion)${NC}"
        else
            echo -e "  • $(printf '%-34s' "libavcodec"): ${YELLOW}⚠️ Limitado (Fedora libre)${NC}"
        fi
    else
        echo -e "  • $(printf '%-34s' "libavcodec"): ${RED}❌ No instalado${NC}"
    fi

    for pkg in lame flac opus-tools vorbis-tools mediainfo libdvdcss; do
        if is_pkg_installed "$pkg" || command -v "$pkg" &>/dev/null; then
            echo -e "  • $(printf '%-34s' "$pkg"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-34s' "$pkg"): ${YELLOW}⚠️ No instalado${NC}"
        fi
    done

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}🧩 Pila GStreamer (Wayland + GTK4 + Cisco OpenH264):${NC}"
    for gst in gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly gstreamer1-plugin-openh264 gstreamer1-plugin-libav gstreamer1-plugin-gtk4 gstreamer1-plugin-dav1d gstreamer1-vaapi pipewire-gstreamer; do
        if is_pkg_installed "$gst"; then
            echo -e "  • $(printf '%-34s' "$gst"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-34s' "$gst"): ${YELLOW}⚠️ No instalado${NC}"
        fi
    done

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}🔊 Servidor de Audio PipeWire & WirePlumber:${NC}"
    echo -e "  • PipeWire Core                     : $(check_user_service pipewire)"
    echo -e "  • PipeWire PulseAudio               : $(check_user_service pipewire-pulse)"
    echo -e "  • WirePlumber Session               : $(check_user_service wireplumber)"

    if is_pkg_installed pipewire-codec-aptx; then
        echo -e "  • Códec Bluetooth aptX              : ${GREEN}✅ Instalado (pipewire-codec-aptx)${NC}"
    else
        echo -e "  • Códec Bluetooth aptX              : ${YELLOW}⚠️ No instalado (Opcional para auriculares aptX/aptX-HD)${NC}"
    fi

    if command -v wpctl &>/dev/null; then
        local audio_sink audio_vol
        audio_sink=$(run_as_user wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -m1 "node.description" | cut -d'"' -f2 || echo "Desconocido")
        audio_vol=$(run_as_user wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)"%"}' || echo "N/A")
        echo -e "  • Salida de Audio Activa            : ${CYAN}$audio_sink (Vol: $audio_vol)${NC}"
    fi

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}🖼️  Miniaturas e Imágenes GNOME (Nautilus & Loupe):${NC}"
    for th in glycin-loaders ffmpegthumbnailer libheif-freeworld libwebp-tools; do
        if is_pkg_installed "$th" || command -v "$th" &>/dev/null; then
            echo -e "  • $(printf '%-34s' "$th"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-34s' "$th"): ${YELLOW}⚠️ No instalado${NC}"
        fi
    done

    local fail_thumb_count=0
    if [ -d "$USER_HOME/.cache/thumbnails/fail" ]; then
        fail_thumb_count=$(find "$USER_HOME/.cache/thumbnails/fail" -type f 2>/dev/null | wc -l || echo "0")
    fi
    if [ "$fail_thumb_count" -gt 0 ]; then
        echo -e "  • Caché de Miniaturas Fallidas      : ${YELLOW}⚠️ $fail_thumb_count archivos pendientes de regenerar${NC}"
    else
        echo -e "  • Caché de Miniaturas Fallidas      : ${GREEN}✅ Limpia (0 fallos)${NC}"
    fi

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}📺 Reproductores y Aplicaciones Multimedia GNOME Wayland:${NC}"
    for app in showtime celluloid mpv vlc loupe snapshot soundconverter; do
        if is_pkg_installed "$app" || command -v "$app" &>/dev/null; then
            echo -e "  • $(printf '%-34s' "$app"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-34s' "$app"): ${YELLOW}⚠️ No instalado${NC}"
        fi
    done

    # Amberol (reproductor de música GNOME)
    if is_pkg_installed amberol || command -v amberol &>/dev/null; then
        echo -e "  • $(printf '%-34s' "amberol"): ${GREEN}✅ Instalado (RPM)${NC}"
    elif flatpak list --app 2>/dev/null | grep -qi "io.bassi.Amberol"; then
        echo -e "  • $(printf '%-34s' "amberol"): ${GREEN}✅ Instalado (Flatpak)${NC}"
    else
        echo -e "  • $(printf '%-34s' "amberol"): ${YELLOW}⚠️ No instalado (Disponible en Flathub: io.bassi.Amberol)${NC}"
    fi

    [[ -f "$MPV_CONF_DIR/mpv.conf" ]] && echo -e "  • Perfil MPV Vulkan/VA-API          : ${GREEN}✅ Configurado ($MPV_CONF_DIR/mpv.conf)${NC}" || echo -e "  • Perfil MPV Vulkan/VA-API          : ${YELLOW}⚠️ No configurado${NC}"

    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "^io.github.celluloid_player.Celluloid$"; then
        local cell_cfg
        cell_cfg=$(run_as_user gsettings get io.github.celluloid_player.Celluloid mpv-config-enable 2>/dev/null || echo "false")
        if [ "$cell_cfg" = "true" ]; then
            echo -e "  • Integración MPV en Celluloid      : ${GREEN}✅ Habilitada (mpv-config-enable = true)${NC}"
        else
            echo -e "  • Integración MPV en Celluloid      : ${YELLOW}⚠️ Deshabilitada${NC}"
        fi
    fi
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. CONFIGURACIÓN DE MPV, CELLULOID Y VARIABLES DE ENTORNO
# ------------------------------------------------------------------------------
configure_mpv_and_env() {
    log_info "Configurando MPV (gpu-next + Vulkan Wayland + VA-API + PipeWire) en $MPV_CONF_DIR..."
    mkdir -p "$MPV_CONF_DIR" "$ENV_D_DIR"

    # Detección de carpeta de capturas de pantalla de usuario
    local pic_dir
    pic_dir=$(run_as_user xdg-user-dir PICTURES 2>/dev/null || true)
    if [ -z "$pic_dir" ] || [ ! -d "$pic_dir" ]; then
        if [ -d "$USER_HOME/Imágenes" ]; then
            pic_dir="$USER_HOME/Imágenes"
        else
            pic_dir="$USER_HOME/Pictures"
        fi
    fi
    local screenshot_dir="$pic_dir/Screenshots"
    mkdir -p "$screenshot_dir"

    cat << EOF > "$MPV_CONF_DIR/mpv.conf"
# ==============================================================================
#  MPV Configuration - Fedora Workstation (GNOME Wayland / AMD Radeon RADV)
#  Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8)
# ==============================================================================

# Renderizado de vídeo nativo Wayland + Vulkan
vo=gpu-next
gpu-api=vulkan
gpu-context=waylandvk,wayland
hwdec=auto-safe
hwdec-codecs=all

# Calidad de escalado de imagen equilibrada para AMD Radeon Vega 8
profile=high-quality
scale=ewa_lanczos
cscale=ewa_lanczos
video-sync=display-resample
interpolation=yes
tscale=oversample

# Audio nativo PipeWire de baja latencia
ao=pipewire
volume=100
volume-max=150
audio-pitch-correction=yes

# Interfaz visual y subtítulos nítidos
osc=yes
osd-bar=yes
sub-auto=fuzzy
sub-font="Sans"
sub-font-size=40
demuxer-mkv-subtitle-preroll=yes
slang=es,spa,en,eng
alang=es,spa,en,eng

# Comportamiento general
save-position-on-quit=yes
keep-open=yes
cursor-autohide=1000

# Capturas de pantalla optimizadas en WebP sin pérdida
screenshot-format=webp
screenshot-webp-lossless=yes
screenshot-directory="$screenshot_dir"

# ------------------------------------------------------------------------------
# Perfiles condicionales
# ------------------------------------------------------------------------------
[protocol.https]
cache=yes
demuxer-max-bytes=150MiB
demuxer-max-back-bytes=50MiB

[protocol.http]
cache=yes
demuxer-max-bytes=150MiB
demuxer-max-back-bytes=50MiB

[4k]
profile-cond=width >= 3840 or height >= 2160
scale=bilinear
cscale=bilinear
interpolation=no
EOF

    cat << 'EOF' > "$MPV_CONF_DIR/input.conf"
# ==============================================================================
#  MPV Keybindings - Controles interactivos y accesos rápidos
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
S             screenshot video
m             cycle mute
SPACE         cycle pause
[             multiply speed 0.9091
]             multiply speed 1.1
BS            set speed 1.0
j             cycle sub
v             cycle sub-visibility
a             cycle audio
i             script-binding stats/display-stats-toggle
l             ab-loop
q             quit-watch-later
EOF

    # Configurar Celluloid para usar la configuración de MPV
    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "^io.github.celluloid_player.Celluloid$"; then
        run_as_user gsettings set io.github.celluloid_player.Celluloid mpv-config-enable true 2>/dev/null || true
        run_as_user gsettings set io.github.celluloid_player.Celluloid mpv-config-file "file://$MPV_CONF_DIR/mpv.conf" 2>/dev/null || true
    fi

    # Variables de entorno multimedia para sesión Wayland (nivel usuario)
    cat << 'EOF' > "$ENV_D_FILE"
# ==============================================================================
# Variables de entorno multimedia - Fedora Workstation (Wayland)
# Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# ==============================================================================
LIBVA_DRIVER_NAME=radeonsi
VDPAU_DRIVER=radeonsi
AMD_VULKAN_ICD=RADV
MOZ_ENABLE_WAYLAND=1
GST_VAAPI_ALL_DRIVERS=1
EOF

    # Si se ejecuta con permisos de superusuario, asegurar también a nivel sistema
    if [ "$EUID" -eq 0 ]; then
        mkdir -p "$SYS_ENV_D_DIR"
        cp -f "$ENV_D_FILE" "$SYS_ENV_D_FILE" 2>/dev/null || true
    fi

    if [ "$EUID" -eq 0 ] && [ "$REAL_USER" != "root" ]; then
        chown -R "$REAL_USER:$REAL_USER" "$MPV_CONF_DIR" "$ENV_D_DIR" "$screenshot_dir" 2>/dev/null || true
    fi
    log_ok "MPV, Celluloid y variables de entorno multimedia configurados con éxito."
}

# ------------------------------------------------------------------------------
# 5. GESTIÓN DE REPOSITORIOS RPM FUSION
# ------------------------------------------------------------------------------
ensure_rpmfusion() {
    if ! is_pkg_installed rpmfusion-free-release || ! is_pkg_installed rpmfusion-nonfree-release; then
        log_info "Asegurando repositorios obligatorios de RPM Fusion..."
        if [ -x "$SCRIPT_DIR/rpmfusion.sh" ]; then
            "$SCRIPT_DIR/rpmfusion.sh"
        else
            local fed_ver
            fed_ver=$(rpm -E %fedora 2>/dev/null || echo "45")
            $SUDO "$DNF_BIN" install -y \
                "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fed_ver}.noarch.rpm" \
                "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fed_ver}.noarch.rpm"
            $SUDO "$DNF_BIN" config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
            $SUDO "$DNF_BIN" install -y --skip-unavailable \
                rpmfusion-free-appstream-data \
                rpmfusion-nonfree-appstream-data \
                rpmfusion-free-release-tainted \
                rpmfusion-nonfree-release-tainted
        fi
        log_ok "Repositorios RPM Fusion verificados."
    else
        log_ok "Repositorios RPM Fusion ya están presentes en el sistema."
    fi
}

# ------------------------------------------------------------------------------
# 6. ACELERACIÓN POR HARDWARE AMD RADEON (MESA FREEWORLD)
# ------------------------------------------------------------------------------
install_hwaccel() {
    log_info "Configurando aceleración por hardware AMD Radeon (Mesa Freeworld)..."
    ensure_rpmfusion

    # Intercambio de mesa-va-drivers a versión freeworld
    if is_pkg_installed mesa-va-drivers && ! is_pkg_installed mesa-va-drivers-freeworld; then
        log_info "Sustituyendo mesa-va-drivers por mesa-va-drivers-freeworld (--allowerasing)..."
        $SUDO "$DNF_BIN" swap -y mesa-va-drivers mesa-va-drivers-freeworld --allowerasing 2>/dev/null || \
            $SUDO "$DNF_BIN" install -y --allowerasing mesa-va-drivers-freeworld
        log_ok "mesa-va-drivers-freeworld activado."
    elif is_pkg_installed mesa-va-drivers-freeworld; then
        log_ok "mesa-va-drivers-freeworld ya se encuentra activo."
    else
        log_info "Instalando mesa-va-drivers-freeworld..."
        $SUDO "$DNF_BIN" install -y --allowerasing mesa-va-drivers-freeworld 2>/dev/null || true
    fi

    # Soporte 32-bit (i686) para Gaming / Steam si aplica
    if is_pkg_installed "mesa-va-drivers.i686" && ! is_pkg_installed "mesa-va-drivers-freeworld.i686"; then
        log_info "Sustituyendo mesa-va-drivers.i686 por mesa-va-drivers-freeworld.i686..."
        $SUDO "$DNF_BIN" swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 --allowerasing 2>/dev/null || true
    fi

    # Manejo retrocompatible para VDPAU si la distribución lo provee
    if is_pkg_installed "mesa-vdpau-drivers" && ! is_pkg_installed "mesa-vdpau-drivers-freeworld"; then
        log_info "Sustituyendo mesa-vdpau-drivers por mesa-vdpau-drivers-freeworld..."
        $SUDO "$DNF_BIN" swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld --allowerasing 2>/dev/null || true
    fi

    # Utilidades de aceleración por hardware y diagnóstico
    local HW_UTILS=(libva libva-utils vulkan-tools)
    local missing_hw=()
    for u in "${HW_UTILS[@]}"; do
        if ! is_pkg_installed "$u"; then
            missing_hw+=("$u")
        fi
    done
    if [ ${#missing_hw[@]} -gt 0 ]; then
        log_info "Instalando utilidades de aceleración HW (${missing_hw[*]})..."
        $SUDO "$DNF_BIN" install -y --skip-unavailable "${missing_hw[@]}"
    fi

    configure_mpv_and_env
    log_ok "Aceleración por hardware AMD Radeon configurada correctamente."
}

# ------------------------------------------------------------------------------
# 7. MINIATURAS E IMÁGENES PARA GNOME NAUTILUS
# ------------------------------------------------------------------------------
clean_thumbnail_cache() {
    log_info "Limpiando caché de miniaturas fallidas en $USER_HOME/.cache/thumbnails/fail..."
    rm -rf "$USER_HOME/.cache/thumbnails/fail" 2>/dev/null || true
    if [ "$EUID" -eq 0 ] && [ "$REAL_USER" != "root" ]; then
        chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.cache/thumbnails" 2>/dev/null || true
    fi
    log_ok "Caché de miniaturas fallidas limpiada."
}

install_thumbnails() {
    log_info "Instalando y optimizando generadores de miniaturas para GNOME Nautilus..."
    local THUMB_PKGS=(
        ffmpegthumbnailer
        glycin-loaders
        gdk-pixbuf2-modules-extra
        libheif-freeworld
        libheif-tools
        libwebp-tools
        ImageMagick
    )
    local missing_thumb=()
    for pkg in "${THUMB_PKGS[@]}"; do
        if ! is_pkg_installed "$pkg"; then
            missing_thumb+=("$pkg")
        fi
    done

    if [ ${#missing_thumb[@]} -gt 0 ]; then
        log_info "Instalando paquetes de miniaturas faltantes (${#missing_thumb[@]} paquetes)..."
        $SUDO "$DNF_BIN" install -y --skip-unavailable "${missing_thumb[@]}"
    else
        log_ok "Todos los generadores de miniaturas ya están instalados."
    fi

    # Registrar thumbnailer de ffmpegthumbnailer si no está presente en el sistema
    local thumb_file="/usr/share/thumbnailers/ffmpegthumbnailer.thumbnailer"
    if command -v ffmpegthumbnailer &>/dev/null && [ ! -f "$thumb_file" ]; then
        log_info "Registrando thumbnailer de ffmpegthumbnailer para Nautilus..."
        $SUDO tee "$thumb_file" >/dev/null << 'EOF_THUMB'
[Thumbnailer Entry]
TryExec=ffmpegthumbnailer
Exec=ffmpegthumbnailer -i %i -o %o -s %s -f
MimeType=video/jpeg;video/mp4;video/mpeg;video/quicktime;video/x-ms-asf;video/x-ms-wmv;video/x-msvideo;video/x-flv;video/x-matroska;video/webm;video/mp2t;video/3gpp;video/ogg;
EOF_THUMB
    fi

    clean_thumbnail_cache
    log_ok "Generadores de miniaturas de Nautilus configurados."
}

# ------------------------------------------------------------------------------
# 8. INSTALACIÓN DE CÓDECS, FFmpeg Y GSTREAMER
# ------------------------------------------------------------------------------
install_codecs() {
    ensure_rpmfusion

    # Paso 1: Intercambio a FFmpeg completo según Howto oficial de RPM Fusion
    if is_pkg_installed ffmpeg-free || ! is_pkg_installed ffmpeg; then
        log_info "Sustituyendo ffmpeg-free por FFmpeg completo de RPM Fusion (--allowerasing)..."
        $SUDO "$DNF_BIN" swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null || \
            $SUDO "$DNF_BIN" install -y --allowerasing ffmpeg ffmpeg-libs
        log_ok "FFmpeg completo instalado."
    else
        log_ok "FFmpeg completo de RPM Fusion ya se encuentra activo."
    fi

    # Paso 2: Aceleración por hardware AMD Radeon
    install_hwaccel

    # Paso 3: Actualizar grupos Multimedia de RPM Fusion
    log_info "Actualizando grupos Multimedia de RPM Fusion..."
    $SUDO "$DNF_BIN" group upgrade --with-optional Multimedia --setopt="install_weak_deps=False" -y 2>/dev/null || true
    $SUDO "$DNF_BIN" group upgrade --with-optional sound-and-video -y 2>/dev/null || true

    # Paso 4: Paquetes esenciales de GStreamer, códecs de audio y utilidades
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
        gstreamer1-plugin-dav1d
        gstreamer1-vaapi
        mozilla-openh264
        pipewire-codec-aptx
        pipewire-gstreamer
        lame
        flac
        opus-tools
        vorbis-tools
        sox
        mediainfo
    )

    local missing_codecs=()
    for pkg in "${CODECS_PKGS[@]}"; do
        if ! is_pkg_installed "$pkg"; then
            missing_codecs+=("$pkg")
        fi
    done

    if [ ${#missing_codecs[@]} -gt 0 ]; then
        log_info "Instalando paquetes de códecs faltantes (${#missing_codecs[@]} paquetes)..."
        $SUDO "$DNF_BIN" install -y --skip-unavailable "${missing_codecs[@]}"
        log_ok "Paquetes de códecs instalados."
    else
        log_ok "Todos los plugins GStreamer y códecs de audio ya están instalados."
    fi

    # Paso 5: Miniaturas e imágenes para Nautilus
    install_thumbnails

    # Paso 6: DVD con cifrado CSS desde repositorio Tainted
    if ! is_pkg_installed libdvdcss; then
        log_info "Instalando soporte de DVD (libdvdcss) desde RPM Fusion Tainted..."
        $SUDO "$DNF_BIN" install -y --enablerepo=rpmfusion-free-tainted libdvdcss 2>/dev/null || true
        log_ok "libdvdcss instalado."
    else
        log_ok "libdvdcss ya está instalado."
    fi

    # Configurar MPV y variables de entorno
    configure_mpv_and_env

    log_ok "Códecs, aceleración HW para AMD Radeon y miniaturas GNOME configurados con éxito."
}

# ------------------------------------------------------------------------------
# 9. INSTALACIÓN DE REPRODUCTORES NATIVOS GNOME WAYLAND
# ------------------------------------------------------------------------------
install_players() {
    log_info "Instalando reproductores multimedia nativos GNOME / Wayland..."
    local PLAYERS_PKGS=(
        mpv
        celluloid
        vlc
        vlc-plugins-freeworld
        showtime
        loupe
        snapshot
        soundconverter
    )
    local missing_players=()
    for app in "${PLAYERS_PKGS[@]}"; do
        if ! is_pkg_installed "$app"; then
            missing_players+=("$app")
        fi
    done

    if [ ${#missing_players[@]} -gt 0 ]; then
        log_info "Instalando reproductores multimedia faltantes (${#missing_players[@]} paquetes)..."
        $SUDO "$DNF_BIN" install -y --skip-unavailable "${missing_players[@]}"
        log_ok "Reproductores multimedia instalados."
    else
        log_ok "Todos los reproductores multimedia vía RPM ya están instalados."
    fi

    # Sugerir Amberol si no está instalado vía Flatpak ni RPM
    if ! is_pkg_installed amberol && ! flatpak list --app 2>/dev/null | grep -qi "io.bassi.Amberol"; then
        log_info "Amberol (reproductor de música GNOME) está disponible en Flathub:"
        log_info "  flatpak install -y flathub io.bassi.Amberol"
    fi

    configure_mpv_and_env
    log_ok "Reproductores multimedia instalados y configurados con éxito."
}

# ------------------------------------------------------------------------------
# 10. PARSEO DE ARGUMENTOS Y EJECUCIÓN
# ------------------------------------------------------------------------------
ACTION="all"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)     ACTION="status"; shift ;;
        -c|--codecs)     ACTION="codecs"; shift ;;
        -p|--players)    ACTION="players"; shift ;;
        -m|--mpv-only)   ACTION="mpv-only"; shift ;;
        --hwaccel|--amd) ACTION="hwaccel"; shift ;;
        --thumbnails)    ACTION="thumbnails"; shift ;;
        -h|--help)       show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; echo ""; show_help; exit 1 ;;
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
    thumbnails)
        check_sudo
        install_thumbnails
        show_status
        ;;
    hwaccel)
        check_sudo
        install_hwaccel
        show_status
        ;;
    codecs)
        check_sudo
        install_codecs
        show_status
        ;;
    players)
        check_sudo
        install_players
        show_status
        ;;
    all)
        check_sudo
        install_codecs
        install_players
        show_status
        ;;
esac
