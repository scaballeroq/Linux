#!/usr/bin/env bash
# ==============================================================================
# multimedia.sh - Suite Multimedia, Códecs y Aceleración HW para Ubuntu Workstation
# Optimizado para Ubuntu 26.10 con Wayland nativo (GNOME Shell 51)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8)
# ==============================================================================
# Características:
#   - Pila completa de códecs oficial: FFmpeg, libavcodec-extra, ubuntu-restricted-addons/extras
#   - Pila GStreamer 1.0 Wayland: plugins-base, good, bad (módulo VA), ugly, libav, gl, gtk4 y pipewire
#   - Aceleración por hardware VA-API / Vulkan en Wayland: libva-wayland2, mesa-va-drivers (radeonsi)
#   - Reproductores Wayland nativos: Showtime (GNOME 51), Celluloid y MPV con config optimizada
#   - Soporte desacoplado Flatpak / Flathub a nivel de sistema para reproductores sandbox
#   - Opciones CLI: --status / -s, --codecs, --players, --flatpak, --help / -h
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PRIVILEGIOS SUDO
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
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="/usr/local/bin:/usr/bin:/bin:$PATH" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🎬 Suite Multimedia y Aceleración Gráfica - Ubuntu 26.10 (GNOME Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica toda la suite: Códecs, VA-API Wayland, Reproductores y Flatpak.
  --status, -s        Muestra diagnóstico detallado de VA-API, códecs, PipeWire y reproductores.
  --codecs            Instala y actualiza únicamente códecs APT, FFmpeg, GStreamer y VA-API.
  --players           Instala y configura reproductores nativos Wayland (Showtime, Celluloid, MPV).
  --flatpak           Configura el repositorio Flathub e instala reproductores desacoplados.
  --help, -h          Muestra este mensaje de ayuda.

Componentes gestionados:
  • Aceleración HW:     Mesa VA-API (radeonsi Gallium), libva-wayland2, Vulkan RADV y vainfo.
  • Códecs Audio/Video: FFmpeg, libavcodec-extra, ubuntu-restricted-addons/extras (EULA automatizada).
  • GStreamer Wayland:  plugins-base, good, bad (VA integrado), ugly, libav, gl, gtk4 y pipewire.
  • Reproductores:      Showtime (GTK4/Adwaita nativo GNOME 51), Celluloid, MPV y VLC.
  • Audio Moderno:      PipeWire y WirePlumber con integración en sinks GStreamer.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO MULTIMEDIA Y ACELERACIÓN WAYLAND - UBUNTU 26.10"
    echo "================================================================="

    echo "• Aceleración Gráfica por Hardware (VA-API / Vulkan):"
    if command -v vainfo &>/dev/null; then
        local va_driver
        va_driver=$(vainfo 2>&1 | grep "Driver version:" | sed "s/.*Driver version: //" || echo "n/a")
        echo "  - Driver VA-API:    $va_driver"
        local va_h264 va_hevc va_vp9
        va_h264=$(vainfo 2>&1 | grep -q "VAProfileH264Main" && echo "✅ Soportado" || echo "❌ No disponible")
        va_hevc=$(vainfo 2>&1 | grep -q "VAProfileHEVCMain" && echo "✅ Soportado" || echo "❌ No disponible")
        va_vp9=$(vainfo 2>&1 | grep -q "VAProfileVP9Profile0" && echo "✅ Soportado" || echo "❌ No disponible")
        echo "  - Decodificación:   H.264: $va_h264 | HEVC (H.265): $va_hevc | VP9: $va_vp9"
        echo "  - libva-wayland2:   $(if dpkg -s libva-wayland2 &>/dev/null; then echo "✅ Instalado (soporte nativo Wayland)"; else echo "❌ No instalado"; fi)"
    else
        echo "  - vainfo no instalado"
    fi

    if command -v vulkaninfo &>/dev/null; then
        echo "  - Vulkan Tools:     ✅ Instalado ($(vulkaninfo --summary 2>/dev/null | grep -i "deviceName" | head -n1 | sed 's/.*= //' || echo "RADV activo"))"
    else
        echo "  - Vulkan Tools:     ❌ No instalado"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Pila de Códecs y FFmpeg:"
    echo "  - FFmpeg:           $(if command -v ffmpeg &>/dev/null; then echo "✅ Instalado ($(ffmpeg -version 2>/dev/null | head -n1 | awk '{print $3}'))"; else echo "❌ No instalado"; fi)"
    echo "  - libavcodec-extra: $(if dpkg -s libavcodec-extra &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - Extras Ubuntu:    $(if dpkg -s ubuntu-restricted-extras &>/dev/null; then echo "✅ ubuntu-restricted-extras"; elif dpkg -s ubuntu-restricted-addons &>/dev/null; then echo "✅ ubuntu-restricted-addons"; else echo "❌ No instalado"; fi)"

    echo "-----------------------------------------------------------------"
    echo "• Pila GStreamer 1.0 (Wayland + PipeWire + GTK4):"
    local gst_bad gst_gtk4 gst_pw
    gst_bad=$(dpkg -s gstreamer1.0-plugins-bad &>/dev/null && echo "✅ Instalado (módulo VA)" || echo "❌ No instalado")
    gst_gtk4=$(dpkg -s gstreamer1.0-gtk4 &>/dev/null && echo "✅ Instalado (gtk4paintablesink)" || echo "❌ No instalado")
    gst_pw=$(dpkg -s gstreamer1.0-pipewire &>/dev/null && echo "✅ Instalado (pipewire-sink)" || echo "❌ No instalado")
    echo "  - Plugins Base/Good:$(if dpkg -s gstreamer1.0-plugins-good &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - Plugins Bad (VA): $gst_bad"
    echo "  - Plugins Ugly/Libav:$(if dpkg -s gstreamer1.0-libav &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - Render Wayland GTK4: $gst_gtk4"
    echo "  - Enlace PipeWire:  $gst_pw"

    echo "-----------------------------------------------------------------"
    echo "• Servidor de Audio PipeWire:"
    local pw_active wp_active
    pw_active=$(run_as_user systemctl --user is-active pipewire 2>/dev/null || echo "inactivo")
    wp_active=$(run_as_user systemctl --user is-active wireplumber 2>/dev/null || echo "inactivo")
    echo "  - PipeWire Audio:   $(if [ "$pw_active" = "active" ]; then echo "✅ Activo"; else echo "⚠️ $pw_active"; fi)"
    echo "  - WirePlumber:      $(if [ "$wp_active" = "active" ]; then echo "✅ Activo"; else echo "⚠️ $wp_active"; fi)"

    echo "-----------------------------------------------------------------"
    echo "• Reproductores Multimedia en Wayland:"
    echo "  - Showtime (GNOME): $(if command -v showtime &>/dev/null; then echo "✅ Instalado (v$(dpkg -s showtime 2>/dev/null | grep -E '^Version:' | awk '{print $2}'))"; else echo "❌ No instalado"; fi)"
    echo "  - Celluloid (GTK):  $(if command -v celluloid &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - MPV Player:       $(if command -v mpv &>/dev/null; then echo "✅ Instalado ($(mpv --version 2>/dev/null | head -n1 | awk '{print $2}'))"; else echo "❌ No instalado"; fi)"
    local vlc_info
    vlc_info=""
    if dpkg -s vlc &>/dev/null; then
        local vlc_v
        vlc_v=$(vlc --version 2>/dev/null | head -n1 | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || echo '3.x')
        vlc_info="✅ Instalado vía APT (v$vlc_v)"
    fi
    if flatpak list 2>/dev/null | grep -q "org.videolan.VLC"; then
        vlc_info="${vlc_info:+$vlc_info | }✅ Instalado vía Flatpak"
    fi
    echo "  - VLC Media Player: ${vlc_info:-❌ No instalado}"

    echo "-----------------------------------------------------------------"
    echo "• Entorno Flatpak / Flathub:"
    local flathub_sys flathub_user
    flathub_sys=$(flatpak remotes --system 2>/dev/null | grep -qi "flathub" && echo "✅ Configurado (system)" || echo "❌ No configurado")
    flathub_user=$(run_as_user flatpak remotes --user 2>/dev/null | grep -qi "flathub" && echo "✅ Configurado (user)" || echo "no configurado")
    echo "  - Remoto Flathub:   $flathub_sys | user: $flathub_user"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. INSTALACIÓN DE CÓDECS Y ACELERACIÓN DE HARDWARE (VA-API / VULKAN)
# ------------------------------------------------------------------------------
install_codecs() {
    echo "🎵 [1/3] Instalando suite de códecs multimedia y aceleración VA-API Wayland..."
    $SUDO apt-get update -qq

    # Aceptar automáticamente la EULA de ttf-mscorefonts-installer para evitar prompts interactivos
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | $SUDO debconf-set-selections 2>/dev/null || true

    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ffmpeg \
        libavcodec-extra \
        ubuntu-restricted-addons \
        ubuntu-restricted-extras \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        gstreamer1.0-gl \
        gstreamer1.0-gtk4 \
        gstreamer1.0-pipewire \
        gstreamer1.0-tools \
        mesa-va-drivers \
        mesa-vdpau-drivers \
        mesa-vulkan-drivers \
        libva-wayland2 \
        vainfo \
        vulkan-tools \
        pipewire-audio \
        wireplumber 2>/dev/null || true

    echo "  ✅ Códecs y aceleración por hardware instalados con éxito."
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN Y CONFIGURACIÓN DE REPRODUCTORES WAYLAND
# ------------------------------------------------------------------------------
install_players() {
    echo "🎬 [2/3] Instalando y optimizando reproductores nativos de Wayland..."
    $SUDO apt-get update -qq
    $SUDO apt-get install -y \
        showtime \
        celluloid \
        mpv \
        vlc 2>/dev/null || true

    # Configuración de rendimiento de MPV para AMD Radeon Vega 8 sobre Wayland y PipeWire
    local mpv_config_dir="$USER_HOME/.config/mpv"
    run_as_user mkdir -p "$mpv_config_dir"
    
    if [ ! -f "$mpv_config_dir/mpv.conf" ]; then
        echo "⚙️ Configurando opciones óptimas de MPV para Wayland y VA-API..."
        cat <<'EOF' | run_as_user tee "$mpv_config_dir/mpv.conf" > /dev/null
# ==============================================================================
# mpv.conf - Optimizado para Ubuntu Workstation (GNOME Shell Wayland)
# Hardware: AMD Ryzen 7 7730U / Radeon Vega 8 (Barcelo-R)
# ==============================================================================

# Contexto de vídeo nativo Wayland sin dependencias de X11
gpu-context=wayland
vo=gpu-next
hwdec=vaapi

# Servidor de audio PipeWire de baja latencia
ao=pipewire

# Calidad y sincronización de tasa de refresco
profile=fast
video-sync=display-resample
interpolation=no

# Capturas de pantalla en PNG sin compresión lenta
screenshot-format=png
screenshot-high-bit-depth=yes
screenshot-directory=~/Pictures
EOF
    fi

    echo "  ✅ Reproductores nativos (Showtime, Celluloid, MPV, VLC) asegurados."
}

# ------------------------------------------------------------------------------
# 5. INTEGRACIÓN DE FLATPAK Y FLATHUB
# ------------------------------------------------------------------------------
setup_flatpak() {
    echo "📦 [3/3] Verificando soporte Flatpak y repositorio Flathub..."
    $SUDO apt-get update -qq
    $SUDO apt-get install -y flatpak gnome-software-plugin-flatpak 2>/dev/null || true

    # Registrar Flathub a nivel de sistema para acceso universal y desacoplado
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

    echo "  ✅ Integración de Flatpak y Flathub verificada."
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
        echo "🎬 CONFIGURANDO SUITE MULTIMEDIA Y WAYLAND EN UBUNTU 26.10"
        echo "================================================================="
        install_codecs
        install_players
        setup_flatpak
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Configuración multimedia completada con éxito."
        echo "================================================================="
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
