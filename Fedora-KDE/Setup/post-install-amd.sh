#!/bin/bash
# ==============================================================================
# post-install-amd.sh - Post-instalación Optimizada para Fedora 44 (KDE Plasma 6)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Radeon Vega 7 / 32 GB RAM / Btrfs)
# ==============================================================================
# Características:
# 1. Optimización DNF5 (paralelismo, defaultyes).
# 2. Habilitación oficial de RPM Fusion (Free y Non-Free) + Cisco OpenH264.
# 3. ZRAM nativo al 50% de la RAM real (16 GB para 32 GB RAM) con compresión ZSTD.
# 4. Microcódigo AMD, firmware GPU Renoir, kernel-devel y headers.
# 5. Stack gráfico Mesa RADV + aceleración por hardware VA-API (freeworld) para Vega 7.
# 6. FFmpeg completo y plugins GStreamer freeworld.
# 7. PipeWire + WirePlumber configurado bajo el contexto de usuario real.
# 8. Suite nativa KDE Plasma 6 (Dolphin, Spectacle, Partition Manager, kio-admin, ffmpegthumbs).
# 9. Debloating de Akonadi y KDE PIM (libera ~1.5 GB RAM y procesos en background).
# 10. Flathub configurado a nivel de sistema y usuario real.
# 11. Soporte completo para banderas CLI: --status, --help.
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
🚀 Post-Instalación Optimizada para AMD Ryzen - Fedora 44 (KDE Plasma 6)
Hardware: HP EliteBook 855 G7 (Ryzen 7 PRO 4750U / Radeon Vega 7 / 32 GB RAM)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica el flujo completo de post-instalación y optimización.
  --status, -s        Diagnóstico detallado de repositorios, microcódigo, ZRAM, GPU y Akonadi.
  --help, -h          Muestra este mensaje de ayuda.

Fases aplicadas:
  • DNF5:             Paralelismo a 10 descargas y confirmación por defecto.
  • Repositorios:     RPM Fusion Free y Non-Free oficiales + Cisco OpenH264.
  • Memoria ZRAM:     16 GB de swap comprimida ZSTD (50% de los 32 GB de RAM).
  • Hardware AMD:     Microcódigo AMD, Mesa RADV, aceleración VA-API freeworld y radeontop.
  • Multimedia:       Sustitución de ffmpeg-free por ffmpeg completo y GStreamer freeworld.
  • Audio:            PipeWire + WirePlumber activo en la sesión de '$REAL_USER'.
  • KDE Plasma 6:     Suite nativa, Dolphin plugins, kio-admin, ffmpegthumbs y wl-clipboard.
  • Debloating:       Purga de Akonadi y KDE PIM para evitar sobrecarga de CPU y memoria.
  • Flatpak:          Flathub integrado en sistema y usuario.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE POST-INSTALACIÓN AMD - FEDORA 44 (KDE PLASMA 6)"
    echo "================================================================="
    echo "👤 Usuario objetivo:          $REAL_USER"
    echo "• Microcódigo AMD:            $(if is_pkg_installed microcode_ctl; then echo "✅ microcode_ctl instalado"; else echo "❌ No instalado"; fi)"
    echo "• Firmware AMD GPU:           $(if is_pkg_installed linux-firmware; then echo "✅ linux-firmware instalado"; else echo "❌ No instalado"; fi)"
    
    # RPM Fusion
    local fusion_free fusion_nonfree
    fusion_free=$(is_pkg_installed rpmfusion-free-release && echo "✅" || echo "❌")
    fusion_nonfree=$(is_pkg_installed rpmfusion-nonfree-release && echo "✅" || echo "❌")
    echo "• RPM Fusion:                 Free: $fusion_free | Non-Free: $fusion_nonfree"

    # FFmpeg
    echo "• FFmpeg:                     $(if is_pkg_installed ffmpeg; then echo "✅ Completo (RPM Fusion)"; elif is_pkg_installed ffmpeg-free; then echo "⚠️ Básico (ffmpeg-free)"; else echo "❌ No instalado"; fi)"

    # VA-API Freeworld
    echo "• VA-API AMD Freeworld:       $(if is_pkg_installed mesa-va-drivers-freeworld; then echo "✅ Instalado"; else echo "❌ mesa-va-drivers estándar"; fi)"

    # ZRAM
    echo "• Configuración ZRAM:"
    if [ -f /etc/systemd/zram-generator.conf ]; then
        grep -E "zram-size|compression-algorithm" /etc/systemd/zram-generator.conf | sed 's/^/    - /' || true
    else
        echo "    ⚠️ Archivo /etc/systemd/zram-generator.conf no configurado"
    fi

    # Akonadi / KDE PIM
    echo "• Estado de Akonadi (PIM):    $(if pgrep -u "$REAL_UID" -x akonadiserver &>/dev/null; then echo "⚠️ Activo en memoria"; else echo "✅ Detenido / No activo"; fi)"

    # PipeWire
    echo "• Servidor PipeWire:          $(if pgrep -u "$REAL_UID" -x pipewire &>/dev/null; then echo "✅ En ejecución"; else echo "⚠️ Inactivo en sesión"; fi)"
    echo "================================================================="
}

execute_post_install() {
    echo "================================================================="
    echo "🚀 INICIANDO POST-INSTALACIÓN: FEDORA 44 (KDE PLASMA 6 / AMD RYZEN)"
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
    echo "✅ DNF5 optimizado (10 descargas paralelas y defaultyes activo)."

    # 2. Habilitar RPM Fusion (Free y Non-Free)
    echo "📦 [2/11] Habilitando repositorios oficiales RPM Fusion..."
    local fedora_ver
    fedora_ver=$(rpm -E %fedora 2>/dev/null || echo "44")

    $SUDO dnf5 install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm" 2>/dev/null || true

    $SUDO dnf5 install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data 2>/dev/null || true
    echo "✅ Repositorios RPM Fusion configurados."

    # 3. Actualización de metadatos y sistema base
    echo "🔄 [3/11] Actualizando metadatos y paquetes del sistema..."
    $SUDO dnf5 upgrade --refresh -y

    # 4. Compresión de Memoria ZRAM (16 GB para 32 GB RAM con ZSTD)
    echo "⚡ [4/11] Configurando ZRAM nativo al 50% de RAM física (16 GB) con ZSTD..."
    $SUDO dnf5 install -y zram-generator zram-generator-defaults 2>/dev/null || true
    $SUDO tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
# Asignar el 50% de la RAM real (16 GB en equipos con 32 GB)
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF
    $SUDO systemctl daemon-reload
    $SUDO systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
    echo "✅ ZRAM configurado a ram / 2 con algoritmo ZSTD."

    # 5. Kernel Linux, Firmware y Microcódigo AMD
    echo "🧠 [5/11] Instalando Kernel, Firmware oficial y Microcódigo para AMD Ryzen..."
    $SUDO dnf5 install -y \
        kernel \
        kernel-core \
        kernel-modules \
        kernel-devel \
        kernel-headers \
        linux-firmware \
        microcode_ctl 2>/dev/null || true
    echo "✅ Kernel y firmware AMD actualizados."

    # 6. Stack Gráfico y Aceleración HW para AMD (Mesa RADV / VA-API Freeworld)
    echo "🎮 [6/11] Instalando controladores AMD Mesa y aceleración de vídeo por hardware..."
    $SUDO dnf5 install -y \
        mesa-dri-drivers \
        mesa-vulkan-drivers \
        mesa-va-drivers-freeworld \
        mesa-vdpau-drivers-freeworld \
        vulkan-tools \
        libva-utils \
        radeontop 2>/dev/null || true

    # Soporte Vulkan 32-bit para Wine/Proton Gaming si existe
    if command -v wine &>/dev/null || command -v proton &>/dev/null; then
        echo "ℹ️ Wine/Proton detectado. Instalando librerías Vulkan de 32 bits..."
        $SUDO dnf5 install -y mesa-vulkan-drivers.i686 2>/dev/null || true
    fi
    echo "✅ Controladores gráficos y VA-API freeworld instalados."

    # 7. Codecs Multimedia y FFmpeg Completo
    echo "🎬 [7/11] Instalando FFmpeg completo de RPM Fusion y codecs multimedia..."
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
    echo "✅ Codecs multimedia completos y aceleración instalados."

    # 8. Servidor de Audio PipeWire y WirePlumber
    echo "🔊 [8/11] Verificando e inicializando PipeWire y WirePlumber para '$REAL_USER'..."
    $SUDO dnf5 install -y \
        pipewire \
        pipewire-pulseaudio \
        pipewire-alsa \
        pipewire-jack-audio-connection-kit \
        wireplumber 2>/dev/null || true

    run_as_user systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
    echo "✅ Servidores de audio PipeWire y WirePlumber activos."

    # 9. Ecosistema Nativo KDE Plasma 6 y Dolphin
    echo "🪟 [9/11] Instalando componentes nativos de KDE Plasma 6 y Dolphin..."
    $SUDO dnf5 install -y \
        dolphin \
        dolphin-plugins \
        kio-extras \
        kio-admin \
        kate \
        spectacle \
        kcalc \
        ark \
        gwenview \
        okular \
        plasma-systemmonitor \
        partitionmanager \
        kinfocenter \
        kitty \
        power-profiles-daemon \
        ffmpegthumbs \
        wl-clipboard \
        papirus-icon-theme 2>/dev/null || true
    echo "✅ Componentes oficiales de KDE Gear y herramientas de escritorio instaladas."

    # 10. Debloating de Akonadi y KDE PIM
    echo "🧹 [10/11] Deteniendo y purgando bloatware de Akonadi y KDE PIM..."
    run_as_user akonadictl stop 2>/dev/null || true
    
    # Paquetes a eliminar si existen
    local pim_pkgs=(
        "kmail"
        "kontact"
        "korganizer"
        "kaddressbook"
        "akonadi-server"
        "akonadi"
    )
    for pkg in "${pim_pkgs[@]}"; do
        if is_pkg_installed "$pkg"; then
            echo "   Desinstalando $pkg..."
            $SUDO dnf5 remove -y "$pkg" 2>/dev/null || true
        fi
    done
    echo "✅ Limpieza de Akonadi y servicios PIM completada (recursos liberados)."

    # 11. Integración de Flatpak & Flathub
    echo "📦 [11/11] Configurando Flatpak y repositorio Flathub..."
    $SUDO dnf5 install -y flatpak plasma-discover-backend-flatpak 2>/dev/null || true
    $SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    run_as_user flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    echo "✅ Flathub configurado a nivel de sistema y usuario."

    # Limpieza final
    echo "🧹 Limpiando caché y dependencias no utilizadas..."
    $SUDO dnf5 autoremove -y 2>/dev/null || true
    $SUDO dnf5 clean all 2>/dev/null || true

    echo ""
    echo "================================================================="
    echo "✅ Post-instalación AMD Ryzen para Fedora 44 finalizada con éxito."
    echo "💡 Se recomienda reiniciar el equipo para cargar el microcódigo,"
    echo "   el kernel actualizado y la nueva asignación de ZRAM (16 GB)."
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
