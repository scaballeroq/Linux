#!/usr/bin/env bash
# ==============================================================================
# multimedia.sh - Pila Multimedia, Codecs, Reproductores y Audio TV
# Sistema: CachyOS (Arch Linux) | Escritorio: GNOME Shell (Wayland)
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD Graphics 4600)
# Pantalla: Sony TV (Salida HDMI / DisplayPort)
# ==============================================================================

set -euo pipefail

# Colores ANSI
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Detección de usuario real
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
${BOLD}🎬 Gestor Multimedia y Audio TV - CachyOS (HP Z230 SFF / Sony TV)${NC}

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala códecs, reproductores, optimizaciones Flatpak y audio HDMI TV.
  --codecs, -c        Instala FFmpeg y la suite completa de plugins GStreamer.
  --players, -p       Instala Kodi nativo, Stremio (Flatpak) y VLC (Flatpak).
  --audio, -a         Aplica optimizaciones de PipeWire y WirePlumber para Sony TV (HDMI).
  --status, -s        Comprueba el estado de codecs, reproductores, VA-API y audio.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

install_codecs() {
    echo -e "${BLUE}🎬 [1/3] Instalando FFmpeg y plugins GStreamer en CachyOS...${NC}"
    $SUDO pacman -S --needed --noconfirm \
        ffmpeg \
        gst-plugins-base \
        gst-plugins-good \
        gst-plugins-bad \
        gst-plugins-ugly \
        gst-libav 2>/dev/null || true
    echo -e "${GREEN}✅ Codecs instalados correctamente.${NC}"
}

install_players() {
    echo -e "${BLUE}🍿 [2/3] Instalando reproductores multimedia (Kodi, Stremio, VLC)...${NC}"
    
    # 1. Kodi Nativo
    $SUDO pacman -S --needed --noconfirm \
        kodi \
        kodi-inputstream-adaptive \
        kodi-inputstream-ffmpegdirect 2>/dev/null || true

    # 2. Flatpaks
    if command -v flatpak &>/dev/null; then
        run_as_user flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
        run_as_user flatpak install -y flathub com.stremio.Stremio 2>/dev/null || true
        run_as_user flatpak install -y flathub org.videolan.VLC 2>/dev/null || true

        # Overrides para Intel Haswell
        run_as_user flatpak override --user \
            --device=dri \
            --socket=wayland \
            --socket=pulseaudio \
            --filesystem=xdg-run/pipewire-0 \
            --talk-name=org.freedesktop.Flatpak \
            --env=VK_DRIVER_FILES=/dev/null \
            --env=VK_ICD_FILENAMES=/dev/null \
            --env=GSK_RENDERER=gl \
            --env=LIBVA_DRIVER_NAME=i965 \
            com.stremio.Stremio 2>/dev/null || true

        run_as_user flatpak override --user \
            --device=dri \
            --socket=wayland \
            --socket=pulseaudio \
            --filesystem=xdg-run/pipewire-0 \
            org.videolan.VLC 2>/dev/null || true
    fi
    echo -e "${GREEN}✅ Reproductores y permisos Flatpak configurados.${NC}"
}

optimize_tv_audio() {
    echo -e "${BLUE}🔊 [3/3] Optimizando fidelidad de audio HDMI para Sony TV (PipeWire/WirePlumber)...${NC}"

    local pw_conf_dir="$USER_HOME/.config/pipewire/pipewire.conf.d"
    local pw_pulse_dir="$USER_HOME/.config/pipewire/pipewire-pulse.conf.d"
    local wp_conf_dir="$USER_HOME/.config/wireplumber/wireplumber.conf.d"
    local stremio_mpv_dir="$USER_HOME/.var/app/com.stremio.Stremio/config/mpv"

    run_as_user mkdir -p "$pw_conf_dir" "$pw_pulse_dir" "$wp_conf_dir"

    # Prevenir buffer underruns y ruidos/chasquidos con un quantum seguro
    cat <<'EOF' | run_as_user tee "$pw_conf_dir/10-htpc-clock.conf" > /dev/null
context.properties = {
    default.clock.rate = 48000
    default.clock.allowed-rates = [ 44100 48000 ]
    default.clock.quantum = 1024
    default.clock.min-quantum = 512
    default.clock.max-quantum = 2048
}
EOF

    # Buffer mínimo para clientes PulseAudio (Flatpaks, Stremio, navegadores)
    cat <<'EOF' | run_as_user tee "$pw_pulse_dir/10-pulse-buffer.conf" > /dev/null
pulse.properties = {
    pulse.min.req = 512/48000
    pulse.min.quantum = 512/48000
}
EOF

    # WirePlumber: normalización automática de downmix 5.1/7.1 a estéreo (evita saturación en altavoces de TV)
    cat <<'EOF' | run_as_user tee "$wp_conf_dir/50-tv-hdmi.conf" > /dev/null
monitor.alsa.rules = [
  {
    matches = [
      {
        node.name = "~alsa_output.pci.*"
      }
    ]
    actions = {
      update-props = {
        channelmix.normalize = true
        channelmix.mix-lfe = true
        channelmix.upmix = false
        api.alsa.period-size = 1024
        api.alsa.headroom = 1024
      }
    }
  }
]
EOF

    # Configuración de audio MPV para Stremio Flatpak
    if [ -d "$USER_HOME/.var/app/com.stremio.Stremio" ]; then
        run_as_user mkdir -p "$stremio_mpv_dir"
        cat <<'EOF' | run_as_user tee "$stremio_mpv_dir/mpv.conf" > /dev/null
# Configuración de audio y video optimizada para Stremio en Sony TV (HDMI Estéreo Haswell)
ao=pulse
audio-channels=stereo
audio-samplerate=48000
audio-format=s16
audio-buffer=0.2
audio-normalize-downmix=yes
volume-max=100
hwdec=vaapi
EOF
    fi

    # Reiniciar servicios de usuario si systemd user está activo
    if run_as_user systemctl --user is-active pipewire &>/dev/null; then
        run_as_user systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || true
    fi

    echo -e "${GREEN}✅ Parámetros de audio TV aplicados (quantum 1024, downmix stereo normalizado y MPV Stremio).${NC}"
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 ESTADO MULTIMEDIA Y AUDIO TV (CACHYOS / HP Z230 SFF)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    echo -e "• Aceleración Gráfica VA-API (Intel HD 4600 Haswell):"
    if command -v vainfo &>/dev/null; then
        local va_driver
        va_driver=$(LIBVA_DRIVER_NAME=i965 vainfo 2>&1 | grep "Driver version" | head -n1 || echo "No detectado")
        echo -e "  - Driver: ${GREEN}$va_driver${NC}"
    else
        echo -e "  - vainfo: ${YELLOW}⚠️ No instalado (instala libva-utils)${NC}"
    fi

    echo -e "-----------------------------------------------------------------"
    echo -e "• Reproductores Multimedia:"
    if command -v kodi &>/dev/null; then
        echo -e "  - Kodi nativo: ${GREEN}✅ Instalado ($(kodi --version 2>/dev/null | head -n1))${NC}"
    else
        echo -e "  - Kodi nativo: ${RED}❌ No instalado${NC}"
    fi

    for app in "com.stremio.Stremio" "org.videolan.VLC"; do
        if command -v flatpak &>/dev/null && flatpak list --app 2>/dev/null | grep -qi "$app"; then
            echo -e "  - $app (Flatpak): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  - $app (Flatpak): ${RED}❌ No instalado${NC}"
        fi
    done

    echo -e "-----------------------------------------------------------------"
    echo -e "• Audio PipeWire & WirePlumber:"
    if systemctl --user is-active pipewire &>/dev/null; then
        echo -e "  - PipeWire:   ${GREEN}✅ Activo${NC}"
    else
        echo -e "  - PipeWire:   ${YELLOW}⚪ Inactivo${NC}"
    fi
    if systemctl --user is-active wireplumber &>/dev/null; then
        echo -e "  - WirePlumber: ${GREEN}✅ Activo${NC}"
    else
        echo -e "  - WirePlumber: ${YELLOW}⚪ Inactivo${NC}"
    fi

    local mpv_conf="$USER_HOME/.var/app/com.stremio.Stremio/config/mpv/mpv.conf"
    if [ -f "$mpv_conf" ]; then
        echo -e "  - Perfil MPV Stremio: ${GREEN}✅ Configurado (Stereo HDMI normalizado)${NC}"
    else
        echo -e "  - Perfil MPV Stremio: ${YELLOW}⚪ No generado${NC}"
    fi
    echo -e "${BOLD}=================================================================${NC}"
}

case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    -c|--codecs|codecs)
        install_codecs
        ;;
    -p|--players|players)
        install_players
        ;;
    -a|--audio|audio)
        optimize_tv_audio
        ;;
    "")
        install_codecs
        install_players
        optimize_tv_audio
        echo ""
        show_status
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac
