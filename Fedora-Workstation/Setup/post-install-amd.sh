#!/usr/bin/env bash
# ==============================================================================
# post-install-amd.sh - Post-Instalación Base para Estaciones AMD Ryzen / Radeon
# Sistema: Fedora 45 Workstation (GNOME Wayland + DNF5 + RPM Fusion Obligatorio)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics / 32GB RAM)
# Referencias Oficiales:
#   - https://rpmfusion.org/Configuration
#   - https://rpmfusion.org/Howto/Multimedia
# ==============================================================================
# Características:
#   - Optimización de DNF5 (/etc/dnf/dnf.conf) para descargas paralelas y espejos rápidos.
#   - Integración modular con Setup/rpmfusion.sh (Free, Non-Free, Tainted, AppStream).
#   - Sustitución de ffmpeg-free por FFmpeg completo y aceleración Mesa Freeworld para AMD.
#   - Microcódigo AMD Ryzen (amd-ucode-firmware) y firmware Radeon (amd-gpu-firmware).
#   - Vulkan RADV (mesa-vulkan-drivers) y utilidades de verificación (vainfo, vulkaninfo).
#   - Despliegue de ZRAM Swap (zstd), Flathub oficial y TRIM periódico para SSD NVMe.
#   - Opciones CLI: --status / -s, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

# ------------------------------------------------------------------------------
# 2. DETECCIÓN DE USUARIO Y GESTOR DE PAQUETES (DNF5)
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

if command -v dnf5 &>/dev/null; then
    DNF_BIN="dnf5"
else
    DNF_BIN="dnf"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEDORA_VER=$(rpm -E %fedora 2>/dev/null || echo "45")

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}🚀 Post-Instalación AMD Ryzen & Radeon - Fedora 45 Workstation (GNOME Wayland)${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8 / 32GB RAM)

Configura DNF5 para descargas paralelas, activa ${BOLD}RPM Fusion (Free, Non-Free, Tainted)${NC},
habilita Cisco OpenH264, actualiza el sistema, instala microcódigo y firmware AMD,
drivers Vulkan RADV + VA-API Freeworld (H.264/HEVC), ZRAM (zstd), Flathub y herramientas base.

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)   Ejecuta toda la configuración post-instalación de AMD
  -s, --status       Muestra el estado detallado de RPM Fusion, hardware AMD, codecs y ZRAM
  -h, --help         Muestra esta ayuda
EOF
}

is_pkg_installed() {
    rpm -q "$1" &>/dev/null
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🚀 ${BOLD}ESTADO DE POST-INSTALACIÓN AMD - FEDORA ${FEDORA_VER} WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  • Sistema Operativo:         ${GREEN}$(cat /etc/fedora-release 2>/dev/null || echo 'Fedora 45 Workstation')${NC}"
    echo -e "  • Kernel activo:             ${CYAN}$(uname -r)${NC}"

    local cpu_model
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "AMD Ryzen")
    echo -e "  • Procesador CPU:            ${CYAN}${cpu_model}${NC}"

    echo ""
    echo -e "${BOLD}📦 Repositorios RPM Fusion Obligatorios:${NC}"
    for repo in rpmfusion-free-release rpmfusion-nonfree-release rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted; do
        if is_pkg_installed "$repo"; then
            echo -e "  • $(printf '%-30s' "$repo"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-30s' "$repo"): ${RED}❌ No instalado${NC}"
        fi
    done

    echo ""
    echo -e "${BOLD}⚡ Firmware AMD, Gráficos RADV y Códecs Freeworld:${NC}"
    for pkg in amd-ucode-firmware amd-gpu-firmware mesa-vulkan-drivers mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld ffmpeg zram-generator flatpak just; do
        if is_pkg_installed "$pkg"; then
            echo -e "  • $(printf '%-30s' "$pkg"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-30s' "$pkg"): ${YELLOW}⚠️ No instalado${NC}"
        fi
    done

    echo ""
    echo -e "${BOLD}🧠 Estado de Memoria y ZRAM Swap:${NC}"
    if systemctl is-active --quiet systemd-zram-setup@zram0.service 2>/dev/null; then
        echo -e "  • ZRAM Swap (zram0):         ${GREEN}✅ Activo${NC}"
    else
        echo -e "  • ZRAM Swap (zram0):         ${YELLOW}⚠️ Inactivo${NC}"
    fi

    echo -e "${BOLD}======================================================================${NC}"
}

if [[ "${1:-}" == "-s" || "${1:-}" == "--status" ]]; then
    show_status
    exit 0
elif [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

echo -e "${BOLD}======================================================================${NC}"
echo -e "  🚀 ${BOLD}INICIANDO POST-INSTALACIÓN FEDORA ${FEDORA_VER} (PERFIL AMD RYZEN)${NC}"
echo -e "${BOLD}======================================================================${NC}"

# 1. Optimización de DNF5 (/etc/dnf/dnf.conf)
log_info "Optimizando DNF5 (max_parallel_downloads=10, fastestmirror=True, defaultyes=True)..."
DNF_CONF="/etc/dnf/dnf.conf"
if [[ -f "$DNF_CONF" ]]; then
    grep -q "^max_parallel_downloads=" "$DNF_CONF" 2>/dev/null || echo "max_parallel_downloads=10" | $SUDO tee -a "$DNF_CONF" >/dev/null
    grep -q "^fastestmirror=" "$DNF_CONF" 2>/dev/null || echo "fastestmirror=True" | $SUDO tee -a "$DNF_CONF" >/dev/null
    grep -q "^defaultyes=" "$DNF_CONF" 2>/dev/null || echo "defaultyes=True" | $SUDO tee -a "$DNF_CONF" >/dev/null
fi

# 2. Configuración OBLIGATORIA de RPM Fusion (Free, Non-Free, Cisco OpenH264, Tainted)
log_info "Configurando repositorios RPM Fusion vía Setup/rpmfusion.sh..."
if [[ -x "$SCRIPT_DIR/rpmfusion.sh" ]]; then
    "$SCRIPT_DIR/rpmfusion.sh"
else
    $SUDO "$DNF_BIN" install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"
    $SUDO "$DNF_BIN" config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
    $SUDO "$DNF_BIN" install -y --skip-unavailable \
        rpmfusion-free-appstream-data \
        rpmfusion-nonfree-appstream-data \
        rpmfusion-free-release-tainted \
        rpmfusion-nonfree-release-tainted
fi

# 3. Actualización base del sistema con metadatos frescos
log_info "Actualizando paquetes del sistema Fedora ${FEDORA_VER} Workstation..."
$SUDO "$DNF_BIN" upgrade --refresh -y

# 4. Firmware, Microcódigo AMD Ryzen y Gráficos Radeon (Vulkan RADV + VA-API Freeworld)
log_info "Instalando microcódigo AMD Ryzen, firmware Radeon y librerías de video Freeworld..."
$SUDO "$DNF_BIN" install -y --skip-unavailable \
    linux-firmware \
    amd-gpu-firmware \
    amd-ucode-firmware \
    microcode_ctl \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    vulkan-loader \
    vulkan-tools \
    libva \
    libva-utils \
    vdpauinfo \
    lm_sensors

log_info "Aplicando swap de drivers Mesa Freeworld y FFmpeg completo desde RPM Fusion..."
$SUDO "$DNF_BIN" swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null || \
    $SUDO "$DNF_BIN" install -y --allowerasing ffmpeg ffmpeg-libs libavcodec-freeworld

$SUDO "$DNF_BIN" swap -y mesa-va-drivers mesa-va-drivers-freeworld 2>/dev/null || \
    $SUDO "$DNF_BIN" install -y --allowerasing mesa-va-drivers-freeworld
$SUDO "$DNF_BIN" swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld 2>/dev/null || \
    $SUDO "$DNF_BIN" install -y --allowerasing mesa-vdpau-drivers-freeworld

# 5. Herramientas esenciales de sistema, desarrollo y utilidades de consola
log_info "Instalando herramientas base de desarrollo, compilación y utilidades de sistema..."
BASE_PKGS=(
    gcc
    gcc-c++
    make
    cmake
    ninja-build
    pkgconf-pkg-config
    git
    curl
    wget
    jq
    unzip
    zip
    tar
    xz
    zstd
    p7zip
    p7zip-plugins
    unrar
    rsync
    just
    btop
    htop
    fastfetch
    wl-clipboard
    flatpak
    gnome-software
    bash-completion
    bind-utils
    net-tools
    pciutils
    usbutils
    nvme-cli
    smartmontools
    fwupd
)
$SUDO "$DNF_BIN" install -y --skip-unavailable "${BASE_PKGS[@]}"

# 6. Configurar ZRAM Swap (zstd, 50% RAM)
if [[ -x "$SCRIPT_DIR/zram-setup.sh" ]]; then
    log_info "Configurando ZRAM Swap mediante Setup/zram-setup.sh..."
    "$SCRIPT_DIR/zram-setup.sh"
fi

# 7. Configurar repositorio oficial Flathub sin filtros limitados
if command -v flatpak &>/dev/null; then
    log_info "Asegurando repositorio oficial Flathub completo..."
    $SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    $SUDO flatpak remote-modify --enable flathub --no-filter 2>/dev/null || true
fi

# 8. Activar TRIM periódico para SSD NVMe
$SUDO systemctl enable --now fstrim.timer 2>/dev/null || true

log_ok "Post-instalación de Fedora ${FEDORA_VER} Workstation (AMD Ryzen / Radeon) completada con éxito."
echo ""
show_status
