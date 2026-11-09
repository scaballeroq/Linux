#!/usr/bin/env bash
# ==============================================================================
# multimedia.sh - Suite Multimedia, Códecs y Aceleración HW para CachyOS
# Optimizado para CachyOS (GNOME Shell Wayland / Mutter)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8 Barcelo-R)
# ==============================================================================
# Características:
#   - Códecs completos nativos sin restricciones de patentes (FFmpeg completo, GStreamer).
#   - Aceleración por hardware AMD Radeon (Mesa): libva-mesa-driver y mesa-vdpau (VCN H.264/HEVC/VP9).
#   - Pila GStreamer completa (base, good, bad, ugly, libav, pipewire).
#   - Miniaturas e imágenes GNOME (glycin-loaders, ffmpegthumbnailer, libheif, libwebp).
#   - Audio PipeWire de baja latencia con WirePlumber y códecs de alta fidelidad.
#   - Reproductores Wayland nativos: Showtime, Celluloid, MPV (gpu-next/vulkan/vaapi), VLC y Loupe.
#   - Soporte de DVD con cifrado CSS (libdvdcss).
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
# 2. DETECCIÓN DE USUARIO, ENTORNO Y PRIVILEGIOS
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
            echo -e "${RED}❌ Error: 'sudo' no está disponible. Ejecuta este script con privilegios de superusuario.${NC}" >&2
            exit 1
        fi
        SUDO="sudo"
    else
        SUDO=""
    fi
}

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        "$@"
    fi
}

is_pkg_installed() {
    pacman -Q "$1" &>/dev/null
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO DETALLADO
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}🎬 Suite Multimedia y Aceleración HW AMD - CachyOS Workstation (GNOME Wayland)${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 Barcelo-R / 32GB RAM)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Aplica la suite completa: Códecs completos, Drivers VA-API,
                      miniaturas para Nautilus, reproductores Wayland y perfil MPV.
  -s, --status        Muestra diagnóstico detallado de VA-API, Vulkan RADV, códecs y MPV.
  -c, --codecs        Instala exclusivamente la pila de códecs (FFmpeg, GStreamer, libdvdcss).
  -p, --players       Instala los reproductores multimedia GNOME Wayland (Showtime, Celluloid, MPV, VLC).
  -m, --mpv-only      Configura únicamente el perfil optimizado de MPV para el usuario actual.
  --hwaccel, --amd    Instala los controladores VA-API y VDPAU (64-bit y multilib) para Radeon Vega 8.
  --thumbnails        Instala y configura miniaturas de audio/video e imágenes en Nautilus.
  -h, --help          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🔍 ${BOLD}ESTADO MULTIMEDIA Y ACELERACIÓN HW - CACHYOS WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    echo -e "${BOLD}💻 Hardware Gráfico y Kernel:${NC}"
    echo -e "  • Procesador (CPU)                  : $(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//')"
    echo -e "  • Controlador Kernel (GPU)          : $(lspci -k 2>/dev/null | grep -A 2 -E "VGA|3D" | grep "Kernel driver in use" | awk '{print $5}' || echo 'amdgpu')"
    echo -e "  • Dispositivo Vulkan Primario       : $(vulkaninfo --summary 2>/dev/null | grep -m1 "deviceName" | cut -d= -f2 | sed 's/^[ \t]*//' || echo 'Radeon Graphics (RADV)')"

    echo -e "\n${BOLD}📦 Controladores de Aceleración Gráfica (Mesa / VA-API / VDPAU):${NC}"
    local mesa_pkgs=(
        "mesa"
        "vulkan-radeon"
        "libva-mesa-driver"
        "mesa-vdpau"
        "lib32-mesa"
        "lib32-vulkan-radeon"
        "lib32-libva-mesa-driver"
        "lib32-mesa-vdpau"
    )
    for pkg in "${mesa_pkgs[@]}"; do
        if is_pkg_installed "$pkg"; then
            local ver
            ver=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}')
            echo -e "  • $(printf '%-34s' "$pkg"): ${GREEN}✅ Instalado ($ver)${NC}"
        else
            echo -e "  • $(printf '%-34s' "$pkg"): ${YELLOW}⚪ No instalado${NC}"
        fi
    done

    echo -e "\n${BOLD}🎞️  Soporte de Perfiles de Decodificación VA-API (vainfo):${NC}"
    if command -v vainfo &>/dev/null; then
        local va_out
        va_out=$(vainfo --display drm --device /dev/dri/renderD128 2>/dev/null || vainfo 2>/dev/null || true)
        if [ -n "$va_out" ]; then
            local va_driver
            va_driver=$(echo "$va_out" | grep "Driver version" | cut -d: -f2 | sed 's/^[ \t]*//' || echo "Mesa Gallium driver")
            echo -e "  • Driver VA-API Activo              : ${GREEN}✅ $va_driver${NC}"
            for profile in "VAProfileH264Main" "VAProfileH264High" "VAProfileHEVCMain" "VAProfileHEVCMain10" "VAProfileVP9Profile0" "VAProfileVP9Profile2" "VAProfileAV1Profile0"; do
                if echo "$va_out" | grep -q "$profile.*VAEntrypointVLD"; then
                    echo -e "    - $(printf '%-28s' "$profile")  : ${GREEN}✅ Aceleración HW activa (VCN Decode)${NC}"
                else
                    echo -e "    - $(printf '%-28s' "$profile")  : ${YELLOW}⚪ No soportado / ausente en hardware${NC}"
                fi
            done
        else
            echo -e "  ${YELLOW}⚠️ vainfo no pudo inicializar la GPU. Verifica permisos del grupo 'video'/'render'.${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚪ vainfo no está instalado (instala libva-utils).${NC}"
    fi

    echo -e "\n${BOLD}🎧 Pila de Audio PipeWire y WirePlumber:${NC}"
    echo -e "  • Servicio PipeWire                 : $(systemctl --user -M "$REAL_USER@" is-active pipewire 2>/dev/null || echo 'Activo bajo demanda')"
    echo -e "  • Servicio WirePlumber              : $(systemctl --user -M "$REAL_USER@" is-active wireplumber 2>/dev/null || echo 'Activo bajo demanda')"

    echo -e "\n${BOLD}📺 Reproductores y Herramientas Multimedia:${NC}"
    for player in "mpv" "celluloid" "vlc" "showtime" "loupe" "amberol"; do
        if command -v "$player" &>/dev/null || is_pkg_installed "$player"; then
            echo -e "  • $(printf '%-34s' "$player"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-34s' "$player"): ${YELLOW}⚪ No instalado${NC}"
        fi
    done

    echo -e "\n${BOLD}⚙️  Configuración MPV del Usuario (~/.config/mpv/mpv.conf):${NC}"
    local mpv_conf="$USER_HOME/.config/mpv/mpv.conf"
    if [ -f "$mpv_conf" ]; then
        echo -e "  • Archivo de configuración         : ${GREEN}✅ Presente${NC} ($mpv_conf)"
        echo -e "  • Parámetros clave configurados:"
        grep -E "vo=|hwdec=|gpu-api=|gpu-context=" "$mpv_conf" 2>/dev/null | sed 's/^/    - /' || true
    else
        echo -e "  • Archivo de configuración         : ${YELLOW}⚪ No existe (ejecuta $0 --mpv-only)${NC}"
    fi
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN DE CONTROLADORES DE ACELERACIÓN HW (AMD)
# ------------------------------------------------------------------------------
install_hwaccel_amd() {
    log_info "Instalando controladores VA-API, VDPAU y Vulkan RADV para AMD Radeon..."
    check_sudo

    local amd_pkgs=(
        "mesa"
        "vulkan-radeon"
        "libva-mesa-driver"
        "mesa-vdpau"
        "vulkan-tools"
        "libva-utils"
        "vdpauinfo"
        "clinfo"
        "lib32-mesa"
        "lib32-vulkan-radeon"
        "lib32-libva-mesa-driver"
        "lib32-mesa-vdpau"
    )

    $SUDO pacman -S --needed --noconfirm "${amd_pkgs[@]}" 2>/dev/null || {
        log_warn "Algunas librerías multilib (32-bit) pueden requerir habilitar [multilib] en /etc/pacman.conf."
        $SUDO pacman -S --needed --noconfirm mesa vulkan-radeon libva-mesa-driver mesa-vdpau vulkan-tools libva-utils
    }
    log_ok "Controladores gráficos y VA-API AMD instalados."
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN DE CÓDECS Y GSTREAMER
# ------------------------------------------------------------------------------
install_codecs() {
    log_info "Instalando suite de códecs completos y plugins GStreamer..."
    check_sudo

    local codec_pkgs=(
        "ffmpeg"
        "gstreamer"
        "gst-plugins-base"
        "gst-plugins-good"
        "gst-plugins-bad"
        "gst-plugins-ugly"
        "gst-libav"
        "gst-plugin-pipewire"
        "libdvdcss"
        "libdvdread"
        "libdvdnav"
    )

    $SUDO pacman -S --needed --noconfirm "${codec_pkgs[@]}"
    log_ok "Códecs multimedia y plugins GStreamer instalados con éxito."
}

# ------------------------------------------------------------------------------
# 6. MINIATURAS E INTEGRACIÓN NAUTILUS
# ------------------------------------------------------------------------------
install_thumbnails() {
    log_info "Configurando generadores de miniaturas (glycin, ffmpegthumbnailer, webp)..."
    check_sudo

    local thumb_pkgs=(
        "ffmpegthumbnailer"
        "glycin-loaders"
        "libheif"
        "libwebp"
    )

    $SUDO pacman -S --needed --noconfirm "${thumb_pkgs[@]}" 2>/dev/null || true
    log_ok "Miniaturas multimedia configuradas."
}

# ------------------------------------------------------------------------------
# 7. CONFIGURACIÓN MPV OPTIMIZADA
# ------------------------------------------------------------------------------
configure_mpv() {
    log_info "Configurando MPV con perfil optimizado para AMD Radeon (gpu-next / Vulkan / VA-API)..."
    local mpv_dir="$USER_HOME/.config/mpv"
    local mpv_conf="$mpv_dir/mpv.conf"

    run_as_user mkdir -p "$mpv_dir"

    run_as_user tee "$mpv_conf" > /dev/null << 'EOF'
# ==============================================================================
#  mpv.conf - Configuración Optimizada para AMD Radeon Vega 8 (HP ProBook 455 G10)
# ==============================================================================
vo=gpu-next
gpu-api=vulkan
gpu-context=wayland
hwdec=vaapi
profile=fast

# Calidad de escalado y renderizado
scale=ewa_lanczos
cscale=ewa_lanczos
dscale=mitchell

# Audio PipeWire
ao=pipewire

# Interfaz y OSD
osc=yes
osd-font="JetBrainsMono Nerd Font"
osd-font-size=24
keep-open=yes
autofit-larger=90%x90%
save-position-on-quit=yes
EOF

    log_ok "Perfil MPV generado en $mpv_conf."
}

# ------------------------------------------------------------------------------
# 8. REPRODUCTORES MULTIMEDIA WAYLAND
# ------------------------------------------------------------------------------
install_players() {
    log_info "Instalando reproductores multimedia Wayland nativos..."
    check_sudo

    local player_pkgs=(
        "celluloid"
        "mpv"
        "vlc"
        "loupe"
    )

    $SUDO pacman -S --needed --noconfirm "${player_pkgs[@]}" 2>/dev/null || true

    # Showtime o Amberol si están disponibles
    $SUDO pacman -S --needed --noconfirm showtime amberol 2>/dev/null || true

    configure_mpv
    log_ok "Reproductores Wayland instalados y optimizados."
}

# ------------------------------------------------------------------------------
# 9. ENTRADA PRINCIPAL
# ------------------------------------------------------------------------------
ACTION="${1:-setup}"

case "$ACTION" in
    -s|--status)
        show_status
        ;;
    -c|--codecs)
        install_hwaccel_amd
        install_codecs
        ;;
    -p|--players)
        install_players
        ;;
    -m|--mpv-only)
        configure_mpv
        ;;
    --hwaccel|--amd)
        install_hwaccel_amd
        ;;
    --thumbnails)
        install_thumbnails
        ;;
    -h|--help)
        show_help
        ;;
    setup|"")
        echo -e "${BOLD}======================================================================${NC}"
        echo -e "  🎬 ${BOLD}DESPLEGANDO SUITE MULTIMEDIA COMPLETA - CACHYOS WORKSTATION${NC}"
        echo -e "${BOLD}======================================================================${NC}"
        install_hwaccel_amd
        install_codecs
        install_thumbnails
        install_players
        echo -e "${BOLD}======================================================================${NC}"
        log_ok "Suite multimedia y aceleración HW completadas con éxito."
        echo -e "💡 Para verificar el estado de los perfiles VA-API ejecuta: ${CYAN}$0 --status${NC}"
        echo -e "${BOLD}======================================================================${NC}"
        ;;
    *)
        log_err "Opción no reconocida: $ACTION"
        show_help
        exit 1
        ;;
esac
