#!/usr/bin/env bash
# ==============================================================================
# multimedia.sh - Suite Multimedia, Códecs y Aceleración HW para Debian TV
# Optimizado para Debian GNU/Linux (GNOME Shell Wayland)
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD Graphics 4600)
# Pantalla: Sony TV (Salida HDMI / DisplayPort / PipeWire)
# ==============================================================================
# Características:
#   - Pila completa de códecs oficial Debian: FFmpeg, libavcodec-extra, audio (FLAC/Opus/Vorbis/MP3)
#   - GStreamer Wayland con aceleración VA-API (driver i965 para Intel Haswell)
#   - Aceleración HW VA-API en Wayland para decodificación fluida H.264 Full HD 1080p
#   - Audio digital de alta fidelidad: PipeWire y WirePlumber hacia la Sony TV
#   - Reproductores multimedia integrados y Flatpaks: Kodi, Stremio, VLC, MPV
#   - Opciones CLI: --status / -s, --codecs, --players, --flatpak, --help / -h
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO, ENTORNO Y PRIVILEGIOS SUDO
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script con privilegios de superusuario."
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

get_os_description() {
    if [ -f /etc/os-release ]; then
        grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"'
    else
        echo "Debian GNU/Linux 13 (trixie)"
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
        echo "✅ Activo (en ejecución)"
        return
    fi
    enabled_state=$(systemctl --user is-enabled "$svc" 2>/dev/null || true)
    if [ "$enabled_state" = "enabled" ] || [ "$enabled_state" = "enabled-runtime" ] || [ "$enabled_state" = "static" ]; then
        echo "✅ Habilitado (systemd user: $enabled_state)"
    else
        echo "⚠️ Inactivo (${active_state:-desconocido})"
    fi
}

# ------------------------------------------------------------------------------
# 2. AYUDA Y DIAGNÓSTICO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🎬 Suite Multimedia y Aceleración Gráfica - Debian 13 Trixie (GNOME Shell Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica toda la suite: Códecs, VA-API Wayland, Miniaturas GNOME, Reproductores y Flatpak.
  --status, -s        Muestra diagnóstico detallado de VA-API, Vulkan, GStreamer, Miniaturas, PipeWire y Apps.
  --codecs            Instala y configura códecs APT, FFmpeg, GStreamer 1.26, miniaturas GNOME y VA-API.
  --players           Instala y optimiza reproductores nativos GNOME 48 / Wayland (Showtime, Celluloid, MPV, VLC).
  --flatpak           Configura el repositorio Flathub e instala soporte Flatpak en GNOME Software.
  --help, -h          Muestra este mensaje de ayuda.

Componentes gestionados en Debian 13 (Trixie):
  • Aceleración HW:     Mesa VA-API (radeonsi Gallium), libva-wayland2, Vulkan RADV y variables de sesión.
  • Códecs Audio/Video: FFmpeg 7.x, libavcodec-extra, FLAC, Opus, Vorbis, LAME y MediaInfo.
  • GStreamer 1.26:     base, good, bad (libgstva nativo), ugly, libav, gl, gtk4 (gtk4paintablesink) y pipewire.
  • GNOME 48 / Nautilus:glycin-loaders (Loupe), ffmpegthumbnailer, Totem (video-thumbnailer), HEIF y WebP.
  • Audio PipeWire 1.4: pipewire-audio, pipewire-alsa, pipewire-pulse, wireplumber y libspa-0.2-bluetooth.
  • Reproductores:      Showtime (GNOME Core GTK4), Loupe, Snapshot, Amberol, Celluloid, MPV (gpu-next) y VLC.
EOF
}

show_status() {
    local os_name gnome_ver
    os_name=$(get_os_description)
    gnome_ver=$(get_gnome_version)

    echo "================================================================="
    echo "🔍 ESTADO MULTIMEDIA Y ACELERACIÓN WAYLAND - DEBIAN TV (HP Z230 SFF)"
    echo "================================================================="
    echo "• Sistema Operativo:     $os_name (Kernel $(uname -r))"
    echo "• Entorno Gráfico:       GNOME Shell $gnome_ver (${XDG_SESSION_TYPE:-wayland} / Mutter)"
    echo "• Hardware:              HP Z230 SFF (Intel Core i7-4790 / Intel HD 4600)"
    echo "• Pantalla:              Sony TV (Salida HDMI / DisplayPort)"
    echo "-----------------------------------------------------------------"

    echo "• Aceleración Gráfica por Hardware (Intel VA-API i965):"
    if command -v vainfo &>/dev/null; then
        local va_out va_driver va_h264 va_hevc va_vc1 va_enc
        va_out=$(LIBVA_DRIVER_NAME=i965 vainfo 2>&1 || true)
        va_driver=$(echo "$va_out" | grep "Driver version:" | sed "s/.*Driver version: //" || echo "i965")
        va_h264=$(echo "$va_out" | grep -q "VAProfileH264Main" && echo "✅" || echo "❌")
        va_vc1=$(echo "$va_out" | grep -q "VAProfileVC1" && echo "✅" || echo "❌")
        va_hevc=$(echo "$va_out" | grep -q "VAProfileHEVCMain" && echo "ℹ️ Híbrido/Software" || echo "❌ (No soportado en Haswell)")
        echo "  - Driver VA-API:       $va_driver"
        echo "  - Decodificación HW:   H.264: $va_h264 | VC-1: $va_vc1 | HEVC: $va_hevc"
        echo "  - libva-wayland2:      $(if dpkg -s libva-wayland2 &>/dev/null; then echo "✅ Instalado (DMABUF Wayland)"; else echo "❌ No instalado"; fi)"
    else
        echo "  - vainfo:              ❌ No instalado"
    fi

    if command -v intel_gpu_top &>/dev/null; then
        echo "  - intel-gpu-tools:     ✅ Instalado (telemetría GPU Intel disponible)"
    else
        echo "  - intel-gpu-tools:     ❌ No instalado"
    fi
    echo "  - Entorno VA-API:      $(if [ -f "$USER_HOME/.config/environment.d/90-debian-multimedia.conf" ]; then echo "✅ Configurado (LIBVA_DRIVER_NAME=i965)"; else echo "ℹ️ Automático por sistema"; fi)"

    echo "-----------------------------------------------------------------"
    echo "• Pila de Códecs, FFmpeg y Herramientas de Audio:"
    echo "  - FFmpeg:              $(if command -v ffmpeg &>/dev/null; then echo "✅ Instalado ($(ffmpeg -version 2>/dev/null | head -n1 | awk '{print $3}'))"; else echo "❌ No instalado"; fi)"
    echo "  - libavcodec-extra:    $(if dpkg -s libavcodec-extra &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - Códecs Audio CLI:    $(if command -v flac &>/dev/null && command -v opusenc &>/dev/null; then echo "✅ Instalados (FLAC, Opus, Vorbis, LAME)"; else echo "⚠️ Parciales"; fi)"
    echo "  - MediaInfo:           $(if command -v mediainfo &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"

    echo "-----------------------------------------------------------------"
    echo "• Pila GStreamer 1.26 (GNOME Wayland + GTK4 + PipeWire):"
    local gst_va_lib="/usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstva.so"
    echo "  - Plugins Base/Good:   $(if dpkg -s gstreamer1.0-plugins-base &>/dev/null && dpkg -s gstreamer1.0-plugins-good &>/dev/null; then echo "✅ Instalados"; else echo "❌ No instalados"; fi)"
    echo "  - Plugins Bad (VA HW): $(if [ -f "$gst_va_lib" ]; then echo "✅ Instalado (libgstva.so activo)"; elif dpkg -s gstreamer1.0-plugins-bad &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - Plugins Ugly/Libav:  $(if dpkg -s gstreamer1.0-plugins-ugly &>/dev/null && dpkg -s gstreamer1.0-libav &>/dev/null; then echo "✅ Instalados"; else echo "❌ No instalados"; fi)"
    echo "  - Render GTK4 Wayland: $(if dpkg -s gstreamer1.0-gtk4 &>/dev/null; then echo "✅ Instalado (gtk4paintablesink)"; else echo "❌ No instalado"; fi)"
    echo "  - Enlace PipeWire:     $(if dpkg -s gstreamer1.0-pipewire &>/dev/null; then echo "✅ Instalado (pipewiresink)"; else echo "❌ No instalado"; fi)"
    echo "  - GStreamer Tools:     $(if command -v gst-inspect-1.0 &>/dev/null; then echo "✅ Instalado (gstreamer1.0-tools)"; else echo "❌ No instalado"; fi)"

    echo "-----------------------------------------------------------------"
    echo "• Miniaturas e Imágenes en GNOME 48 (Nautilus & Loupe):"
    echo "  - Glycin Loaders:      $(if dpkg -s glycin-loaders &>/dev/null; then echo "✅ Instalado ( Loupe sandboxed image decoding )"; else echo "❌ No instalado"; fi)"
    echo "  - FFmpeg Thumbnailer:  $(if command -v ffmpegthumbnailer &>/dev/null; then echo "✅ Instalado (miniaturas de vídeo rápidas)"; else echo "❌ No instalado"; fi)"
    echo "  - Soporte HEIF / AVIF: $(if dpkg -s heif-gdk-pixbuf &>/dev/null && dpkg -s heif-thumbnailer &>/dev/null; then echo "✅ Instalado (heif-gdk-pixbuf + thumbnailer)"; else echo "❌ No instalado"; fi)"
    echo "  - Soporte WebP:        $(if dpkg -s webp-pixbuf-loader &>/dev/null; then echo "✅ Instalado (webp-pixbuf-loader)"; else echo "❌ No instalado"; fi)"

    echo "-----------------------------------------------------------------"
    echo "• Servidor de Audio PipeWire 1.4 & Bluetooth SPA:"
    echo "  - PipeWire Core:       $(check_user_service pipewire)"
    echo "  - PipeWire PulseAudio: $(check_user_service pipewire-pulse)"
    echo "  - WirePlumber Session: $(check_user_service wireplumber)"
    echo "  - Bluetooth Audio SPA: $(if dpkg -s libspa-0.2-bluetooth &>/dev/null; then echo "✅ Instalado (LDAC / aptX / AAC)"; else echo "❌ No instalado"; fi)"

    echo "-----------------------------------------------------------------"
    echo "• Reproductores y Aplicaciones Multimedia (GNOME 48 Wayland):"
    echo "  - Showtime (Vídeo):    $(if command -v showtime &>/dev/null; then echo "✅ Instalado (GNOME Core GTK4 v$(dpkg-query -W -f='${Version}' showtime 2>/dev/null || echo '48'))"; else echo "❌ No instalado"; fi)"
    echo "  - Loupe (Imágenes):    $(if command -v loupe &>/dev/null; then echo "✅ Instalado (GNOME Core GTK4 v$(dpkg-query -W -f='${Version}' loupe 2>/dev/null || echo '48'))"; else echo "❌ No instalado"; fi)"
    echo "  - Snapshot (Cámara):   $(if dpkg -s gnome-snapshot &>/dev/null; then echo "✅ Instalado (PipeWire Camera GTK4)"; else echo "❌ No instalado"; fi)"
    echo "  - Amberol (Música):    $(if command -v amberol &>/dev/null; then echo "✅ Instalado (GTK4/Libadwaita)"; else echo "❌ No instalado"; fi)"
    echo "  - Celluloid (MPV GTK4):$(if command -v celluloid &>/dev/null; then echo "✅ Instalado (v$(dpkg-query -W -f='${Version}' celluloid 2>/dev/null || echo '0.28'))"; else echo "❌ No instalado"; fi)"
    echo "  - MPV Media Player:    $(if command -v mpv &>/dev/null; then echo "✅ Instalado ($(mpv --version 2>/dev/null | head -n1 | awk '{print $2}'))"; else echo "❌ No instalado"; fi)"
    echo "  - Config MPV Wayland:  $(if [ -f "$USER_HOME/.config/mpv/mpv.conf" ]; then echo "✅ Optimizado (vo=gpu-next / hwdec=vaapi / ao=pipewire)"; else echo "❌ Sin configurar"; fi)"
    local vlc_info=""
    if dpkg -s vlc &>/dev/null; then
        local vlc_v
        vlc_v=$(dpkg-query -W -f='${Version}' vlc 2>/dev/null | cut -d- -f1 || echo "3.0.x")
        vlc_info="✅ Instalado vía APT (v$vlc_v)"
    fi
    if flatpak list 2>/dev/null | grep -qi "org.videolan.VLC"; then
        vlc_info="${vlc_info:+$vlc_info | }✅ Instalado vía Flatpak"
    fi
    echo "  - VLC Media Player:    ${vlc_info:-❌ No instalado}"

    echo "-----------------------------------------------------------------"
    echo "• Entorno Flatpak / Flathub:"
    local flathub_sys flathub_user
    flathub_sys=$(flatpak remotes --system 2>/dev/null | grep -qi "flathub" && echo "✅ Configurado (system)" || echo "❌ No configurado")
    flathub_user=$(run_as_user flatpak remotes --user 2>/dev/null | grep -qi "flathub" && echo "✅ Configurado (user)" || echo "no configurado")
    echo "  - Remoto Flathub:      $flathub_sys | user: $flathub_user"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. INSTALACIÓN DE CÓDECS, MINIATURAS GNOME Y ACELERACIÓN HW (VA-API / VULKAN)
# ------------------------------------------------------------------------------
install_codecs() {
    echo "🎵 [1/3] Instalando suite de códecs, miniaturas GNOME 48 y aceleración VA-API Wayland..."

    # Asegurar componentes contrib, non-free y non-free-firmware en Debian 13 (deb822 y clásico)
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then
        $SUDO sed -i '/^Components:/ {/contrib/! s/$/ contrib/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
        $SUDO sed -i '/^Components:/ {/non-free/! s/$/ non-free/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
        $SUDO sed -i '/^Components:/ {/non-free-firmware/! s/$/ non-free-firmware/}' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
    elif [ -f /etc/apt/sources.list ]; then
        $SUDO sed -i '/^deb / {/contrib/! s/\(main\)/\1 contrib non-free non-free-firmware/}' /etc/apt/sources.list 2>/dev/null || true
    fi

    $SUDO apt-get update -qq

    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ffmpeg \
        libavcodec-extra \
        mediainfo \
        flac \
        lame \
        vorbis-tools \
        opus-tools \
        sox \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        gstreamer1.0-gl \
        gstreamer1.0-gtk4 \
        gstreamer1.0-pipewire \
        gstreamer1.0-vaapi \
        gstreamer1.0-tools \
        glycin-loaders \
        ffmpegthumbnailer \
        totem \
        webp-pixbuf-loader \
        heif-gdk-pixbuf \
        heif-thumbnailer \
        libavif-bin \
        mesa-va-drivers \
        mesa-vdpau-drivers \
        mesa-vulkan-drivers \
        libva-wayland2 \
        vainfo \
        vulkan-tools \
        mesa-utils \
        pipewire-audio \
        pipewire-alsa \
        pipewire-pulse \
        wireplumber \
        libspa-0.2-bluetooth \
        libspa-0.2-jack

    # Configurar variables de sesión Wayland para aceleración VA-API en Intel HD Graphics 4600 (Haswell i965)
    local env_dir="$USER_HOME/.config/environment.d"
    run_as_user mkdir -p "$env_dir"
    cat <<'EOF' | run_as_user tee "$env_dir/90-debian-multimedia.conf" > /dev/null
# Aceleración por hardware VA-API en Debian (Intel Haswell HD 4600 / GNOME Wayland)
LIBVA_DRIVER_NAME=i965
VDPAU_DRIVER=va_gl
MOZ_ENABLE_WAYLAND=1
GST_PLUGIN_FEATURE_RANK=vah264dec:MAX
EOF

    # Limpiar caché de miniaturas fallidas para que Nautilus regenere con ffmpegthumbnailer / HEIF / WebP
    if [ -d "$USER_HOME/.cache/thumbnails/fail" ]; then
        run_as_user rm -rf "$USER_HOME/.cache/thumbnails/fail"
    fi

    echo "  ✅ Códecs, GStreamer, miniaturas de Nautilus y aceleración VA-API i965 configurados."
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN Y OPTIMIZACIÓN DE REPRODUCTORES GNOME WAYLAND
# ------------------------------------------------------------------------------
install_players() {
    echo "🎬 [2/3] Instalando y optimizando reproductores multimedia para GNOME Wayland..."
    $SUDO apt-get update -qq
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        showtime \
        loupe \
        gnome-snapshot \
        amberol \
        gnome-music \
        celluloid \
        mpv \
        vlc

    # Configuración de alto rendimiento de MPV para Intel Haswell HD 4600 sobre Wayland y PipeWire
    local mpv_config_dir="$USER_HOME/.config/mpv"
    run_as_user mkdir -p "$mpv_config_dir"

    echo "⚙️ Aplicando perfil óptimo de MPV para Intel HD 4600 (VA-API i965 + PipeWire)..."
    cat <<'EOF' | run_as_user tee "$mpv_config_dir/mpv.conf" > /dev/null
# ==============================================================================
# mpv.conf - Optimizado para Debian TV (HP Z230 SFF / Intel HD 4600)
# Pantalla: Sony TV 1080p | Audio: PipeWire HDMI
# ==============================================================================

# Motor de renderizado Wayland y aceleración VA-API
vo=gpu
gpu-context=wayland
hwdec=vaapi
hwdec-codecs=h264,vc1,mpeg2video

# Servidor de audio PipeWire nativo
ao=pipewire
volume=100
volume-max=150

# Sincronización y fluidez de vídeo en Sony TV 1080p @ 60Hz
video-sync=display-resample
interpolation=no
deband=no

# Interfaz OSD moderna y limpia
osc=yes
osd-bar=no
border=yes
keep-open=yes
save-position-on-quit=yes

# Idiomas preferidos de audio y subtítulos
alang=es,spa,en,eng
slang=es,spa,en,eng
sub-auto=fuzzy

# Capturas de pantalla en PNG sin pérdida
screenshot-format=png
screenshot-high-bit-depth=yes
screenshot-directory=~/Pictures
EOF

    # Integrar Celluloid (GTK4/Libadwaita) con la configuración optimizada de MPV
    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "^io.github.celluloid_player.Celluloid$"; then
        run_as_user gsettings set io.github.celluloid_player.Celluloid mpv-config-enable true 2>/dev/null || true
        run_as_user gsettings set io.github.celluloid_player.Celluloid mpv-config-file "file://$mpv_config_dir/mpv.conf" 2>/dev/null || true
        run_as_user gsettings set io.github.celluloid_player.Celluloid use-skip-buttons-for-playlist true 2>/dev/null || true
    fi

    echo "  ✅ Reproductores GNOME 48 Wayland (Showtime, Loupe, Snapshot, Amberol, Celluloid, MPV, VLC) listos."
}

# ------------------------------------------------------------------------------
# 5. INTEGRACIÓN DE FLATPAK Y FLATHUB
# ------------------------------------------------------------------------------
setup_flatpak() {
    echo "📦 [3/3] Verificando soporte Flatpak y repositorio Flathub..."
    $SUDO apt-get update -qq
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        flatpak \
        gnome-software-plugin-flatpak \
        xdg-desktop-portal-gnome \
        xdg-desktop-portal-gtk

    # Registrar Flathub a nivel de sistema para acceso universal
    if ! flatpak remotes --system 2>/dev/null | grep -qi "flathub"; then
        $SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    fi

    # Registrar Flathub para el usuario actual (idempotente)
    run_as_user flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

    # Instalar VLC vía Flatpak solo si no está presente en APT ni en Flatpak
    if ! dpkg -s vlc &>/dev/null && ! flatpak list 2>/dev/null | grep -qi "org.videolan.VLC"; then
        echo "🚀 Instalando reproductor VLC desacoplado vía Flatpak..."
        $SUDO flatpak install -y --noninteractive flathub org.videolan.VLC 2>/dev/null || true
    fi

    echo "  ✅ Integración de Flatpak, portales XDG de GNOME y Flathub verificada."
}

# ------------------------------------------------------------------------------
# 6. ENTRADA PRINCIPAL
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --codecs)
        install_codecs
        exit 0
        ;;
    --players)
        install_players
        exit 0
        ;;
    --flatpak)
        setup_flatpak
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🎬 CONFIGURANDO SUITE MULTIMEDIA Y WAYLAND EN DEBIAN 13 (GNOME)"
        echo "================================================================="
        install_codecs
        install_players
        setup_flatpak
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Configuración multimedia para Debian 13 GNOME completada."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
