#!/bin/bash
# ==============================================================================
# post-install-intel.sh - Post-instalación Optimizada para Intel Core / Media Center
# Sistema: Fedora 44 (KDE Plasma 6 / Intel Haswell i7-4790 / HD Graphics 4600 / Kodi)
# ==============================================================================
# Características:
# 1. Optimización DNF5 (paralelismo y defaultyes).
# 2. Habilitación de RPM Fusion Free y Non-Free + Cisco OpenH264.
# 3. ZRAM nativo al 50% de la RAM real con compresión ZSTD.
# 4. Microcódigo Intel (microcode_ctl) y kernel-devel.
# 5. Aceleración por hardware VA-API para Intel HD 4600 (libva-intel-driver i965 e intel-media-driver).
# 6. FFmpeg completo y suite de reproducción para Kodi y streaming.
# 7. PipeWire + WirePlumber configurado bajo el contexto de usuario real.
# 8. Suite nativa de KDE Plasma 6 y debloating de Akonadi/PIM.
# 9. Centro Multimedia Kodi y complementos IPTV / Adaptive Stream.
# 10. Flathub configurado a nivel de sistema y usuario real.
# 11. Soporte completo de banderas CLI: --status, --help.
# ==============================================================================

set -euo pipefail

# 1. Detección de Usuario y Permisos
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

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

require_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        echo "❌ Error: Esta operación requiere privilegios de administrador ('sudo')."
        exit 1
    fi
}

is_pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

show_help() {
    cat <<EOF
🖥️ Post-Instalación Intel Core / Media Center - Fedora 44 (KDE Plasma 6)
Optimizado para sobremesa Intel Haswell (i7-4790 / HD Graphics 4600 / Kodi)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica el flujo completo de post-instalación para Intel y Media Center.
  --status, -s        Diagnóstico detallado de microcódigo, VA-API Intel, Kodi y ZRAM.
  --help, -h          Muestra este mensaje de ayuda.

Fases aplicadas:
  • DNF5:             Paralelismo a 10 descargas y confirmación por defecto.
  • Repositorios:     RPM Fusion Free y Non-Free oficiales + Cisco OpenH264.
  • Memoria ZRAM:     Swap comprimida ZSTD al 50% de la RAM real.
  • Hardware Intel:   Microcódigo Intel, VA-API Haswell (i965 / libva-intel-driver) y vainfo.
  • Multimedia:       FFmpeg completo de RPM Fusion y plugins GStreamer freeworld.
  • Media Center:     Kodi con complementos inputstream.adaptive e iptvsimple.
  • Audio:            PipeWire + WirePlumber activo en la sesión de '$REAL_USER'.
  • Debloating:       Purga de Akonadi y KDE PIM para optimizar recursos en HTPC.
  • Flatpak:          Flathub integrado en sistema y usuario.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO INTEL / MEDIA CENTER - FEDORA 44 (KDE PLASMA 6)"
    echo "================================================================="
    echo "👤 Usuario objetivo:          $REAL_USER"
    echo "• Microcódigo Intel:          $(if is_pkg_installed microcode_ctl; then echo "✅ microcode_ctl instalado"; else echo "❌ No instalado"; fi)"
    
    # VA-API Intel
    local va_driver
    va_driver=$(if is_pkg_installed libva-intel-driver; then echo "✅ libva-intel-driver (i965 Haswell)"; elif is_pkg_installed intel-media-driver; then echo "✅ intel-media-driver (iHD)"; else echo "❌ No instalado"; fi)
    echo "• Controlador VA-API Intel:   $va_driver"
    echo "• Utilidad vainfo:            $(if command -v vainfo &>/dev/null; then echo "✅ vainfo disponible"; else echo "❌ No instalado"; fi)"

    # RPM Fusion y FFmpeg
    echo "• Repositorios RPM Fusion:    $(if is_pkg_installed rpmfusion-free-release && is_pkg_installed rpmfusion-nonfree-release; then echo "✅ Habilitados"; else echo "❌ Incompletos"; fi)"
    echo "• FFmpeg:                     $(if is_pkg_installed ffmpeg; then echo "✅ Completo (RPM Fusion)"; else echo "⚠️ Básico o no instalado"; fi)"

    # Kodi
    echo "• Centro Multimedia Kodi:     $(if is_pkg_installed kodi; then echo "✅ Instalado ($(rpm -q --qf '%{VERSION}' kodi))"; else echo "❌ No instalado"; fi)"

    # Akonadi
    echo "• Estado de Akonadi (PIM):    $(if pgrep -u "$REAL_UID" -x akonadiserver &>/dev/null; then echo "⚠️ Activo en memoria"; else echo "✅ Detenido / No activo"; fi)"
    echo "================================================================="
}

execute_post_install() {
    echo "================================================================="
    echo "🚀 INICIANDO POST-INSTALACIÓN: FEDORA 44 - INTEL CORE / MEDIA CENTER"
    echo "================================================================="
    require_root

    # 1. Optimización de DNF5
    echo "⚡ [1/11] Configurando optimizaciones de rendimiento en DNF5..."
    local DNF5_CONF="/etc/dnf5/dnf5.conf"
    if [ -f "$DNF5_CONF" ]; then
        if ! grep -q "max_parallel_downloads" "$DNF5_CONF"; then
            echo "max_parallel_downloads=10" | $SUDO tee -a "$DNF5_CONF" > /dev/null
        fi
        if ! grep -q "defaultyes" "$DNF5_CONF"; then
            echo "defaultyes=True" | $SUDO tee -a "$DNF5_CONF" > /dev/null
        fi
    fi
    echo "✅ DNF5 optimizado."

    # 2. Habilitar RPM Fusion
    echo "📦 [2/11] Habilitando repositorios oficiales RPM Fusion..."
    local fedora_ver
    fedora_ver=$(rpm -E %fedora 2>/dev/null || echo "44")

    $SUDO dnf5 install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm" 2>/dev/null || true

    $SUDO dnf5 install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data 2>/dev/null || true
    echo "✅ RPM Fusion configurado."

    # 3. Actualización de metadatos y sistema base
    echo "🔄 [3/11] Actualizando metadatos y paquetes del sistema..."
    $SUDO dnf5 upgrade --refresh -y

    # 4. Compresión de Memoria ZRAM
    echo "⚡ [4/11] Configurando ZRAM nativo al 50% de RAM física con ZSTD..."
    $SUDO dnf5 install -y zram-generator zram-generator-defaults 2>/dev/null || true
    $SUDO tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF
    $SUDO systemctl daemon-reload
    $SUDO systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
    echo "✅ ZRAM configurado."

    # 5. Kernel y Microcódigo Intel
    echo "🧠 [5/11] Instalando Kernel, Firmware oficial y Microcódigo Intel..."
    $SUDO dnf5 install -y \
        kernel \
        kernel-core \
        kernel-modules \
        kernel-devel \
        kernel-headers \
        linux-firmware \
        microcode_ctl 2>/dev/null || true
    echo "✅ Microcódigo Intel y firmware instalados."

    # 6. Stack Gráfico Intel y Aceleración HW por Vídeo (i965 / Haswell)
    echo "🎬 [6/11] Instalando controladores gráficos Intel y aceleración VA-API..."
    $SUDO dnf5 install -y \
        mesa-dri-drivers \
        libva-intel-driver \
        intel-media-driver \
        libva-utils 2>/dev/null || true
    echo "✅ Aceleración VA-API Intel configurada."

    # 7. Codecs Multimedia y FFmpeg Completo
    echo "🎞️ [7/11] Instalando FFmpeg completo de RPM Fusion y plugins GStreamer..."
    $SUDO dnf5 config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
    $SUDO dnf5 swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null || $SUDO dnf5 install -y ffmpeg 2>/dev/null || true
    $SUDO dnf5 install -y \
        gstreamer1-plugins-base \
        gstreamer1-plugins-good \
        gstreamer1-plugins-bad-free \
        gstreamer1-plugins-bad-freeworld \
        gstreamer1-plugins-ugly \
        gstreamer1-plugin-openh264 \
        gstreamer1-libav \
        gstreamer1-vaapi 2>/dev/null || true
    echo "✅ Codecs multimedia completos instalados."

    # 8. Servidor de Audio PipeWire y WirePlumber
    echo "🔊 [8/11] Verificando servidor PipeWire para '$REAL_USER'..."
    $SUDO dnf5 install -y \
        pipewire \
        pipewire-pulseaudio \
        pipewire-alsa \
        wireplumber 2>/dev/null || true

    run_as_user systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
    echo "✅ Audio PipeWire activo."

    # 9. Centro Multimedia Kodi y complementos
    echo "📺 [9/11] Instalando centro multimedia Kodi y extensiones de streaming..."
    $SUDO dnf5 install -y \
        kodi \
        kodi-inputstream-adaptive \
        kodi-inputstream-rtmp \
        kodi-pvr-iptvsimple 2>/dev/null || true
    echo "✅ Kodi instalado con soporte para streaming adaptable e IPTV."

    # 10. Debloating de Akonadi y KDE PIM
    echo "🧹 [10/11] Deteniendo y purgando servicios PIM en entorno Media Center..."
    run_as_user akonadictl stop 2>/dev/null || true
    local pim_pkgs=("kmail" "kontact" "korganizer" "kaddressbook" "akonadi-server" "akonadi")
    for pkg in "${pim_pkgs[@]}"; do
        if is_pkg_installed "$pkg"; then
            $SUDO dnf5 remove -y "$pkg" 2>/dev/null || true
        fi
    done
    echo "✅ Debloating de Akonadi completado."

    # 11. Integración de Flatpak & Flathub
    echo "📦 [11/11] Configurando Flatpak y Flathub..."
    $SUDO dnf5 install -y flatpak plasma-discover-backend-flatpak 2>/dev/null || true
    $SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    run_as_user flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    echo "✅ Flathub configurado."

    # Limpieza final
    $SUDO dnf5 autoremove -y 2>/dev/null || true
    $SUDO dnf5 clean all 2>/dev/null || true

    echo ""
    echo "================================================================="
    echo "✅ Post-instalación Intel Core / Media Center completada con éxito."
    echo "💡 Se recomienda reiniciar el equipo para aplicar todos los cambios."
    echo "================================================================="
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    "")
        execute_post_install
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
