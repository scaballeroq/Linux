#!/usr/bin/env bash
# ==============================================================================
# multimedia.sh - Suite Multimedia, Códecs y Aceleración HW para Fedora Workstation
# Optimizado para Fedora Workstation (GNOME Shell Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8)
# ==============================================================================
# Características:
#   - Habilita RPM Fusion (Free, Non-Free y Tainted) y Cisco OpenH264.
#   - Sustituye ffmpeg-free por FFmpeg completo de RPM Fusion.
#   - Pila GStreamer 1.0 Wayland: plugins-base, good, bad-freeworld, ugly, libav, openh264 y vaapi.
#   - Aceleración por hardware VA-API / Vulkan en Wayland: mesa-va-drivers-freeworld, mesa-vdpau-drivers-freeworld.
#   - Reproductores Wayland nativos: Celluloid, MPV (con mpv.conf optimizado) y VLC.
#   - Soporte desacoplado Flatpak / Flathub a nivel de sistema para reproductores sandbox.
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

if command -v dnf5 &>/dev/null; then
    DNF_CMD="dnf5"
else
    DNF_CMD="dnf"
fi

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
🎬 Suite Multimedia y Aceleración Gráfica - Fedora Workstation (GNOME Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica toda la suite: RPM Fusion, Códecs, VA-API, Reproductores y Flatpak.
  --status, -s        Muestra diagnóstico detallado de RPM Fusion, VA-API, FFmpeg, códecs y reproductores.
  --codecs            Instala y actualiza únicamente repositorios RPM Fusion, FFmpeg, GStreamer y VA-API freeworld.
  --players           Instala y configura reproductores nativos Wayland (Celluloid, MPV con config optimizada, VLC).
  --flatpak           Configura el repositorio Flathub e instala reproductores desacoplados.
  --help, -h          Muestra este mensaje de ayuda.

Componentes gestionados:
  • Repositorios:       RPM Fusion (Free, Non-Free, Tainted) y Cisco OpenH264.
  • Aceleración HW:     mesa-va-drivers-freeworld, mesa-vdpau-drivers-freeworld, libva-utils y vulkan-tools.
  • Códecs Audio/Video: FFmpeg completo, GStreamer bad-freeworld/ugly/libav, libdvdcss, x264, x265.
  • Reproductores:      Celluloid (GTK4), MPV (gpu-next + Wayland + PipeWire) y VLC.
  • Audio Moderno:      PipeWire y WirePlumber con integración en MPV.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO MULTIMEDIA Y ACELERACIÓN WAYLAND - FEDORA WORKSTATION"
    echo "================================================================="
    echo "• Repositorios Multimedia y Drivers Propietarios:"
    echo "  - RPM Fusion Free:          $(rpm -q rpmfusion-free-release 2>/dev/null || echo 'No instalado')"
    echo "  - RPM Fusion Non-Free:      $(rpm -q rpmfusion-nonfree-release 2>/dev/null || echo 'No instalado')"
    echo "  - RPM Fusion Free Tainted:  $(rpm -q rpmfusion-free-release-tainted 2>/dev/null || echo 'No instalado')"
    echo "  - RPM Fusion NonFree Tainted: $(rpm -q rpmfusion-nonfree-release-tainted 2>/dev/null || echo 'No instalado')"
    echo "-----------------------------------------------------------------"

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
        echo "  - Mesa VA freeworld: $(rpm -q mesa-va-drivers-freeworld 2>/dev/null || echo 'No instalado')"
    else
        echo "  - vainfo:           ❌ No instalado (ejecuta con --codecs para diagnosticar)"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Pila de Códecs y Bibliotecas:"
    echo "  - FFmpeg:           $(if rpm -q ffmpeg &>/dev/null; then echo "✅ FFmpeg completo ($(rpm -q --qf '%{VERSION}' ffmpeg))"; elif rpm -q ffmpeg-free &>/dev/null; then echo "⚠️ ffmpeg-free (limitado)"; else echo "❌ No instalado"; fi)"
    echo "  - libdvdcss (DVD):  $(rpm -q libdvdcss 2>/dev/null || echo 'No instalado')"
    echo "  - GStreamer Ugly:   $(rpm -q gstreamer1-plugins-ugly 2>/dev/null || echo 'No instalado')"
    echo "  - GStreamer Freeworld: $(rpm -q gstreamer1-plugins-bad-freeworld 2>/dev/null || echo 'No instalado')"

    echo "-----------------------------------------------------------------"
    echo "• Reproductores de Vídeo:"
    local celluloid_info mpv_info vlc_info
    celluloid_info=$(rpm -q celluloid 2>/dev/null || flatpak list 2>/dev/null | grep -i "celluloid" | head -n1 || echo "")
    mpv_info=$(rpm -q mpv 2>/dev/null || echo "")
    vlc_info=$(rpm -q vlc 2>/dev/null || flatpak list 2>/dev/null | grep -i "org.videolan.VLC" | head -n1 || echo "")
    echo "  - Celluloid:        ${celluloid_info:-❌ No instalado}"
    if [ -n "$mpv_info" ]; then
        local mpv_cfg
        mpv_cfg=$([ -f "$USER_HOME/.config/mpv/mpv.conf" ] && echo " (config Wayland activa)" || echo " (sin config personalizada)")
        echo "  - MPV Media Player: ✅ $mpv_info$mpv_cfg"
    else
        echo "  - MPV Media Player: ❌ No instalado"
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
# 3. INSTALACIÓN DE CÓDECS, RPM FUSION Y ACELERACIÓN DE HARDWARE (VA-API / VULKAN)
# ------------------------------------------------------------------------------
install_codecs() {
    echo "🎵 [1/3] Habilitando RPM Fusion, códecs multimedia y aceleración VA-API freeworld..."

    # 1. Habilitar Repositorios Oficiales RPM Fusion (Free y Non-Free)
    echo "  📦 Habilitando repositorios oficiales RPM Fusion (Free y Non-Free)..."
    $SUDO $DNF_CMD install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>/dev/null || true

    $SUDO $DNF_CMD install -y \
        rpmfusion-free-appstream-data \
        rpmfusion-nonfree-appstream-data 2>/dev/null || true

    # 2. Habilitar Repositorios Tainted (libdvdcss y patentes adicionales)
    echo "  🔓 Habilitando repositorios RPM Fusion Tainted..."
    $SUDO $DNF_CMD install -y \
        rpmfusion-free-release-tainted \
        rpmfusion-nonfree-release-tainted 2>/dev/null || true

    # 3. Habilitar repositorio Cisco OpenH264
    echo "  🌐 Habilitando repositorio fedora-cisco-openh264..."
    $SUDO $DNF_CMD config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true

    # 4. Sustituir FFmpeg-free por FFmpeg Completo
    echo "  🔄 Sustituyendo ffmpeg-free por FFmpeg completo de RPM Fusion..."
    $SUDO $DNF_CMD swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null || \
        $SUDO $DNF_CMD install -y ffmpeg --allowerasing 2>/dev/null || true

    # 5. Instalar controladores freeworld con soporte completo de aceleración HW
    echo "  ⚡ Instalando controladores freeworld con soporte completo VA-API/VDPAU..."
    local CPU_VENDOR
    CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || true)

    $SUDO $DNF_CMD install -y \
        mesa-va-drivers-freeworld \
        mesa-vdpau-drivers-freeworld \
        libva-utils \
        vulkan-tools 2>/dev/null || true

    if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
        echo "  ℹ️ CPU Intel detectada: instalando intel-media-driver..."
        $SUDO $DNF_CMD install -y \
            intel-media-driver \
            libva-intel-driver 2>/dev/null || true
    fi

    # 6. Pila Completa de Plugins GStreamer, Codecs Privativos y Reproducción DVD
    echo "  🎵 Instalando codecs multimedia y plugins GStreamer..."
    $SUDO $DNF_CMD install -y \
        gstreamer1-plugins-base \
        gstreamer1-plugins-good \
        gstreamer1-plugins-bad-free \
        gstreamer1-plugins-bad-freeworld \
        gstreamer1-plugins-ugly \
        gstreamer1-plugin-openh264 \
        gstreamer1-vaapi \
        gstreamer1-libav \
        lame \
        lame-mp3x \
        faac \
        faad2 \
        x264 \
        x265 \
        libde265 \
        libdvdcss \
        libdvdread \
        libdvdnav \
        libheif-ffmpeg \
        lsdvd 2>/dev/null || true

    # Resolver conflicto de versión libheif-freeworld si existiera
    if rpm -q libheif-freeworld &>/dev/null; then
        $SUDO $DNF_CMD swap -y libheif-freeworld libheif-ffmpeg --allowerasing 2>/dev/null || true
    fi

    echo "  ✅ Códecs y aceleración por hardware instalados con éxito."
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN Y CONFIGURACIÓN DE REPRODUCTORES WAYLAND
# ------------------------------------------------------------------------------
install_players() {
    echo "🎬 [2/3] Instalando y optimizando reproductores nativos de Wayland..."
    $SUDO $DNF_CMD install -y \
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
# mpv.conf - Optimizado para Fedora Workstation (GNOME Shell Wayland)
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

    echo "  ✅ Reproductores nativos (Celluloid, MPV, VLC) asegurados."
}

# ------------------------------------------------------------------------------
# 5. INTEGRACIÓN DE FLATPAK Y FLATHUB
# ------------------------------------------------------------------------------
setup_flatpak() {
    echo "📦 [3/3] Verificando soporte Flatpak y repositorio Flathub..."
    $SUDO $DNF_CMD install -y flatpak 2>/dev/null || true

    # Registrar Flathub a nivel de sistema para acceso universal y desacoplado
    if ! flatpak remotes --system 2>/dev/null | grep -qi "flathub"; then
        $SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    fi

    # Registrar Flathub para el usuario actual (idempotente)
    run_as_user flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

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
        echo "🎬 CONFIGURANDO SUITE MULTIMEDIA Y WAYLAND EN FEDORA WORKSTATION"
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
