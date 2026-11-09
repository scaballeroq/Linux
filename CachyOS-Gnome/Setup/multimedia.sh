#!/usr/bin/env bash
# ==============================================================================
# multimedia.sh - Suite Multimedia, Códecs y Aceleración HW para CachyOS
# Optimizado para CachyOS Workstation (GNOME Shell Wayland / Mutter)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 Barcelo-R)
# ==============================================================================
# Características:
#   - Códecs completos nativos sin restricciones de patentes (FFmpeg completo, GStreamer).
#   - Aceleración por hardware AMD Radeon (Mesa): libva-mesa-driver (VCN H.264/HEVC/VP9 decode y H.264/HEVC encode).
#   - Pila GStreamer completa (base, good, bad, ugly, libav, pipewire y gst-plugin-va nativo).
#   - Generación de miniaturas GNOME (glycin, ffmpegthumbnailer, webp-pixbuf-loader, libheif, libwebp).
#   - Ajuste de Nautilus para previsualizar vídeos pesados (límite 500 MB) y limpieza de caché corrupta.
#   - Audio PipeWire de baja latencia con WirePlumber y códecs de alta fidelidad.
#   - Reproductores Wayland nativos: Showtime, Celluloid, MPV (gpu-next/vulkan/vaapi), Loupe, Amberol y VLC.
#   - Soporte de DVD con cifrado CSS (libdvdcss, libdvdread, libdvdnav).
#   - Ejecución sin sudo para diagnósticos (--status), limpieza de caché (--clean-cache) y configuración de usuario (--mpv-only).
#   - Opciones CLI: --status / -s, --codecs / -c, --players / -p, --mpv-only / -m,
#                   --hwaccel / --amd, --thumbnails, --clean-cache, --help / -h.
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
  (sin argumentos)       Aplica la suite completa: Códecs completos, Drivers VA-API,
                         miniaturas para Nautilus, reproductores Wayland y perfil MPV.
  -s, --status           Muestra diagnóstico detallado de VA-API, Vulkan RADV, códecs y MPV.
  -c, --codecs           Instala exclusivamente la pila de códecs (FFmpeg, GStreamer, libdvdcss).
  -p, --players          Instala los reproductores multimedia GNOME Wayland (Showtime, Celluloid, MPV, VLC, Amberol).
  -m, --mpv-only         Configura únicamente el perfil optimizado de MPV para el usuario actual.
  --hwaccel, --amd       Instala controladores VA-API, Vulkan RADV y librerías multilib para Radeon Vega 8.
  --thumbnails           Instala y configura miniaturas de audio/video e imágenes en Nautilus.
  --clean-cache          Limpia cachés corruptas de miniaturas (~/.cache/thumbnails) y reinicia Nautilus.
  -h, --help             Muestra este mensaje de ayuda.
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

    echo -e "\n${BOLD}📦 Controladores de Aceleración Gráfica (Mesa / VA-API / Vulkan):${NC}"
    local mesa_pkgs=(
        "mesa"
        "vulkan-radeon"
        "vulkan-tools"
        "libva-utils"
        "vdpauinfo"
        "libvdpau-va-gl"
        "lib32-mesa"
        "lib32-vulkan-radeon"
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

    echo -e "\n${BOLD}🎞️  Soporte de Perfiles de Decodificación y Codificación VA-API (vainfo):${NC}"
    if command -v vainfo &>/dev/null; then
        local va_out
        va_out=$(vainfo --display drm --device /dev/dri/renderD128 2>/dev/null || vainfo 2>/dev/null || true)
        if [ -n "$va_out" ]; then
            local va_driver
            va_driver=$(echo "$va_out" | grep -i "Driver version" | sed -E 's/.*Driver version:[[:space:]]*//' || echo "Mesa Gallium driver")
            echo -e "  • Driver VA-API Activo              : ${GREEN}✅ $va_driver${NC}"
            
            echo -e "  ${BOLD}Decodificación Hardware (VCN Decode):${NC}"
            local dec_profiles=(
                "VAProfileH264Main:H.264 / AVC Main"
                "VAProfileH264High:H.264 / AVC High"
                "VAProfileHEVCMain:HEVC / H.265 Main (8-bit)"
                "VAProfileHEVCMain10:HEVC / H.265 Main 10 (10-bit)"
                "VAProfileVP9Profile0:VP9 Profile 0 (8-bit)"
                "VAProfileVP9Profile2:VP9 Profile 2 (10-bit)"
                "VAProfileMPEG2Main:MPEG-2 Main"
                "VAProfileVC1Advanced:VC-1 Advanced"
            )
            for item in "${dec_profiles[@]}"; do
                local prof="${item%%:*}"
                local desc="${item##*:}"
                if echo "$va_out" | grep -q "$prof.*VAEntrypointVLD"; then
                    echo -e "    - $(printf '%-32s' "$desc"): ${GREEN}✅ Aceleración HW activa${NC}"
                else
                    echo -e "    - $(printf '%-32s' "$desc"): ${YELLOW}⚪ No soportado${NC}"
                fi
            done
            if echo "$va_out" | grep -q "VAProfileAV1Profile0.*VAEntrypointVLD"; then
                echo -e "    - $(printf '%-32s' "AV1 Profile 0 (Hardware)"): ${GREEN}✅ Aceleración HW activa${NC}"
            else
                echo -e "    - $(printf '%-32s' "AV1 (Vega 8 Barcelo-R)"): ${CYAN}ℹ️  Software CPU dav1d (16 hilos Zen 3)${NC}"
            fi

            echo -e "  ${BOLD}Codificación Hardware (VCN Encode):${NC}"
            local enc_profiles=(
                "VAProfileH264Main:H.264 / AVC Main Encode"
                "VAProfileH264High:H.264 / AVC High Encode"
                "VAProfileHEVCMain:HEVC / H.265 Main Encode"
                "VAProfileHEVCMain10:HEVC / H.265 Main 10 Encode"
            )
            for item in "${enc_profiles[@]}"; do
                local prof="${item%%:*}"
                local desc="${item##*:}"
                if echo "$va_out" | grep -q "$prof.*VAEntrypointEncSlice"; then
                    echo -e "    - $(printf '%-32s' "$desc"): ${GREEN}✅ Encode HW activo${NC}"
                else
                    echo -e "    - $(printf '%-32s' "$desc"): ${YELLOW}⚪ No soportado${NC}"
                fi
            done
        else
            echo -e "  ${YELLOW}⚠️ vainfo no pudo inicializar la GPU. Verifica permisos del grupo 'video'/'render'.${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚪ vainfo no está instalado (instala libva-utils).${NC}"
    fi

    echo -e "\n${BOLD}🎼 Pila de Códecs y Frameworks Multimedia:${NC}"
    local codec_check=(
        "ffmpeg"
        "gstreamer"
        "gst-plugin-va"
        "gst-plugin-pipewire"
        "dav1d"
        "svt-av1"
        "libdvdcss"
    )
    for pkg in "${codec_check[@]}"; do
        if is_pkg_installed "$pkg"; then
            local ver
            ver=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}')
            echo -e "  • $(printf '%-34s' "$pkg"): ${GREEN}✅ Instalado ($ver)${NC}"
        else
            echo -e "  • $(printf '%-34s' "$pkg"): ${YELLOW}⚪ No instalado${NC}"
        fi
    done

    echo -e "\n${BOLD}🖼️  Generadores de Miniaturas Nautilus / GNOME:${NC}"
    local thumb_check=(
        "ffmpegthumbnailer"
        "glycin"
        "webp-pixbuf-loader"
        "libheif"
    )
    for pkg in "${thumb_check[@]}"; do
        if is_pkg_installed "$pkg"; then
            local ver
            ver=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}')
            echo -e "  • $(printf '%-34s' "$pkg"): ${GREEN}✅ Instalado ($ver)${NC}"
        else
            echo -e "  • $(printf '%-34s' "$pkg"): ${YELLOW}⚪ No instalado${NC}"
        fi
    done

    echo -e "\n${BOLD}🎧 Pila de Audio PipeWire y WirePlumber:${NC}"
    local pw_status wp_status
    if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        pw_status=$(systemctl --user -M "$REAL_USER@" is-active pipewire 2>/dev/null || echo 'inactivo')
        wp_status=$(systemctl --user -M "$REAL_USER@" is-active wireplumber 2>/dev/null || echo 'inactivo')
    else
        pw_status=$(systemctl --user is-active pipewire 2>/dev/null || echo 'inactivo')
        wp_status=$(systemctl --user is-active wireplumber 2>/dev/null || echo 'inactivo')
    fi
    echo -e "  • Servicio PipeWire                 : $([ "$pw_status" = "active" ] && echo "${GREEN}✅ activo${NC}" || echo "${YELLOW}⚪ $pw_status${NC}")"
    echo -e "  • Servicio WirePlumber              : $([ "$wp_status" = "active" ] && echo "${GREEN}✅ activo${NC}" || echo "${YELLOW}⚪ $wp_status${NC}")"
    if command -v wpctl &>/dev/null; then
        local active_sink active_source
        active_sink=$(wpctl status 2>/dev/null | awk '/Sinks:/{flag=1; next} /Sources:/{flag=0} flag && /\*/{print $0}' | sed -E 's/.*[*][[:space:]]*[0-9]+\.[[:space:]]*//' | head -n1 || echo 'Por defecto')
        active_source=$(wpctl status 2>/dev/null | awk '/Sources:/{flag=1; next} /Filters:/{flag=0} flag && /\*/{print $0}' | sed -E 's/.*[*][[:space:]]*[0-9]+\.[[:space:]]*//' | head -n1 || echo 'Por defecto')
        [ -n "$active_sink" ] && echo -e "  • Salida de Audio Activa (Sink)     : ${CYAN}$active_sink${NC}"
        [ -n "$active_source" ] && echo -e "  • Entrada de Audio Activa (Source)  : ${CYAN}$active_source${NC}"
    fi

    echo -e "\n${BOLD}📺 Reproductores y Herramientas Multimedia:${NC}"
    for player in "celluloid" "mpv" "showtime" "loupe" "amberol" "vlc" "yt-dlp"; do
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
        grep -E "^(vo|hwdec|gpu-api|gpu-context|ao|scale|interpolation)=" "$mpv_conf" 2>/dev/null | sed 's/^/    - /' || true
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
        "vulkan-tools"
        "vulkan-icd-loader"
        "libva-utils"
        "vdpauinfo"
        "libvdpau-va-gl"
        "clinfo"
        "lib32-mesa"
        "lib32-vulkan-radeon"
        "lib32-vulkan-icd-loader"
    )

    if ! $SUDO pacman -S --needed --noconfirm "${amd_pkgs[@]}"; then
        log_warn "Algunas librerías multilib (32-bit) pueden requerir habilitar [multilib] en /etc/pacman.conf."
        log_info "Reintentando instalación con paquetes base de 64 bits..."
        $SUDO pacman -S --needed --noconfirm mesa vulkan-radeon vulkan-tools vulkan-icd-loader libva-utils vdpauinfo libvdpau-va-gl clinfo
    fi
    log_ok "Controladores gráficos y VA-API AMD instalados."
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN DE CÓDECS Y GSTREAMER
# ------------------------------------------------------------------------------
install_codecs() {
    log_info "Instalando suite de códecs completos, decodificadores AV1 y plugins GStreamer..."
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
        "gst-plugin-va"
        "dav1d"
        "svt-av1"
        "lame"
        "flac"
        "opus"
        "libdvdcss"
        "libdvdread"
        "libdvdnav"
    )

    $SUDO pacman -S --needed --noconfirm "${codec_pkgs[@]}"
    log_ok "Códecs multimedia, decodificador AV1 y plugins GStreamer instalados con éxito."
}

# ------------------------------------------------------------------------------
# 6. MINIATURAS E INTEGRACIÓN NAUTILUS
# ------------------------------------------------------------------------------
install_thumbnails() {
    log_info "Configurando generadores de miniaturas (ffmpegthumbnailer, glycin, webp, heif)..."
    check_sudo

    # Se usa 'glycin' (nombre correcto en Arch/CachyOS) y webp-pixbuf-loader para GTK/Nautilus
    local thumb_pkgs=(
        "ffmpegthumbnailer"
        "glycin"
        "libheif"
        "libwebp"
        "webp-pixbuf-loader"
    )

    $SUDO pacman -S --needed --noconfirm "${thumb_pkgs[@]}"

    log_info "Optimizando preferencias de miniaturas en GNOME Nautilus (límite 500 MB)..."
    run_as_user gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always' 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences thumbnail-limit 500 2>/dev/null || true

    log_ok "Miniaturas multimedia e integración con Nautilus configuradas."
}

# ------------------------------------------------------------------------------
# 7. LIMPIEZA DE CACHÉ DE MINIATURAS
# ------------------------------------------------------------------------------
clean_thumbnail_cache() {
    log_info "Limpiando miniaturas corruptas o fallidas en el espacio de usuario..."
    local thumb_cache="$USER_HOME/.cache/thumbnails"
    if [ -d "$thumb_cache" ]; then
        rm -rf "$thumb_cache/fail" "$thumb_cache/normal" 2>/dev/null || true
        log_ok "Caché de miniaturas ($thumb_cache) reseteada."
    fi

    if pgrep -x nautilus &>/dev/null; then
        log_info "Reiniciando Nautilus para actualizar las previsualizaciones..."
        run_as_user nautilus -q 2>/dev/null || true
    fi
    log_ok "Generadores de miniaturas listos para regenerar previsualizaciones."
}

# ------------------------------------------------------------------------------
# 8. CONFIGURACIÓN MPV Y CELLULOID OPTIMIZADA
# ------------------------------------------------------------------------------
configure_mpv() {
    log_info "Configurando MPV con perfil equilibrado para AMD Radeon Vega 8 (gpu-next / Vulkan / VA-API)..."
    local mpv_dir="$USER_HOME/.config/mpv"
    local mpv_conf="$mpv_dir/mpv.conf"

    run_as_user mkdir -p "$mpv_dir"
    [ -d "$USER_HOME/Imágenes" ] || run_as_user mkdir -p "$USER_HOME/Imágenes"

    run_as_user tee "$mpv_conf" > /dev/null << 'EOF'
# ==============================================================================
#  mpv.conf - Configuración Optimizada para AMD Radeon Vega 8 (HP ProBook 455 G10)
#  Compositor: GNOME Shell Wayland / Mutter | Salida: vo=gpu-next / Vulkan
# ==============================================================================

# Backend de vídeo y aceleración hardware
vo=gpu-next
gpu-api=vulkan
gpu-context=wayland
hwdec=auto-safe

# Calidad de escalado y renderizado (Equilibrado y eficiente para Vega 8 Barcelo-R)
scale=spline36
cscale=spline36
dscale=mitchell
correct-downscaling=yes
linear-downscaling=yes
dither-depth=auto

# Sincronización y fluidez en pantallas Wayland 60Hz
video-sync=display-resample
interpolation=yes
tscale=oversample

# Audio PipeWire nativo de baja latencia con respaldo a PulseAudio
ao=pipewire,pulse
audio-file-auto=fuzzy

# Interfaz Moderna y OSD
osc=yes
osd-font="JetBrainsMono Nerd Font"
osd-font-size=24
osd-color="#cdd6f4"
osd-border-color="#11111b"
osd-border-size=2
osd-bar=yes
osd-bar-w=60
osd-bar-h=2

# Subtítulos de alta legibilidad
sub-auto=fuzzy
sub-font="JetBrainsMono Nerd Font"
sub-font-size=36
sub-color="#ffffff"
sub-border-color="#000000"
sub-border-size=2.5

# Comportamiento de ventana y reproducción
keep-open=yes
autofit-larger=90%x90%
save-position-on-quit=yes

# Buffer y Cache para streaming y ficheros de red
cache=yes
demuxer-max-bytes=150MiB
demuxer-max-back-bytes=50MiB

# Capturas de pantalla
screenshot-format=webp
screenshot-directory="~/Imágenes"
screenshot-template="mpv-%F-%P"
EOF

    # Vincular configuración de MPV en Celluloid si está instalado
    if is_pkg_installed "celluloid"; then
        log_info "Configurando Celluloid para heredar el perfil optimizado de MPV..."
        run_as_user gsettings set io.github.celluloid-player.Celluloid load-mpv-config true 2>/dev/null || true
        run_as_user gsettings set io.github.celluloid-player.Celluloid mpv-config-file "$mpv_conf" 2>/dev/null || true
    fi

    log_ok "Perfil MPV generado en $mpv_conf."
}

# ------------------------------------------------------------------------------
# 9. REPRODUCTORES MULTIMEDIA WAYLAND
# ------------------------------------------------------------------------------
install_players() {
    log_info "Instalando reproductores multimedia Wayland nativos (Celluloid, MPV, VLC, Showtime, Loupe, Amberol)..."
    check_sudo

    local player_pkgs=(
        "celluloid"
        "mpv"
        "vlc"
        "showtime"
        "loupe"
        "amberol"
    )

    $SUDO pacman -S --needed --noconfirm "${player_pkgs[@]}"

    configure_mpv
    log_ok "Reproductores Wayland instalados y optimizados."
}

# ------------------------------------------------------------------------------
# 10. ENTRADA PRINCIPAL
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
    --clean-cache|--clean-thumbnails)
        clean_thumbnail_cache
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
