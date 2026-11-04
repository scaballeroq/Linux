#!/usr/bin/env bash
# ==============================================================================
# post-install-intel.sh - Post-Instalación Base para Sistemas Intel Core / Media
# Sistema: Fedora 45 Workstation (GNOME Wayland + DNF5 + RPM Fusion Obligatorio)
# ==============================================================================
# Características:
#   - Optimización de DNF5 (/etc/dnf/dnf.conf) para descargas paralelas.
#   - Integración modular con Setup/rpmfusion.sh (Free, Non-Free, Tainted, AppStream).
#   - Sustitución de ffmpeg-free por FFmpeg completo (--allowerasing).
#   - Microcódigo Intel (microcode_ctl), VA-API (intel-media-driver y libva-intel-driver).
#   - Control térmico (thermald), Vulkan ANV, ZRAM Swap (zstd) y Flathub.
#   - Opciones CLI: --status / -s, --help / -h.
# ==============================================================================

set -euo pipefail

BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

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

show_help() {
    cat << EOF
${BOLD}🚀 Post-Instalación Intel Core / Media Center - Fedora 45 Workstation${NC}

Configura DNF5 para descargas paralelas, activa ${BOLD}RPM Fusion${NC}, instala microcódigo
Intel, drivers de aceleración VA-API (intel-media-driver + libva-intel-driver), Vulkan ANV,
FFmpeg completo, thermald, ZRAM y Flathub.

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)   Ejecuta toda la configuración post-instalación de Intel
  -s, --status       Muestra el estado de RPM Fusion, hardware Intel y codecs
  -h, --help         Muestra esta ayuda
EOF
}

is_pkg_installed() {
    rpm -q "$1" &>/dev/null
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🚀 ${BOLD}ESTADO DE POST-INSTALACIÓN INTEL - FEDORA ${FEDORA_VER} WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  • Sistema Operativo:         ${GREEN}$(cat /etc/fedora-release 2>/dev/null || echo 'Fedora Linux')${NC}"
    echo -e "  • Kernel activo:             ${CYAN}$(uname -r)${NC}"

    local cpu_model
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "Intel Core")
    echo -e "  • Procesador CPU:            ${CYAN}${cpu_model}${NC}"

    echo ""
    echo -e "${BOLD}📦 Repositorios RPM Fusion:${NC}"
    for repo in rpmfusion-free-release rpmfusion-nonfree-release rpmfusion-free-release-tainted; do
        if is_pkg_installed "$repo"; then
            echo -e "  • $(printf '%-30s' "$repo"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-30s' "$repo"): ${RED}❌ No instalado${NC}"
        fi
    done

    echo ""
    echo -e "${BOLD}⚡ Drivers Intel y Aceleración VA-API:${NC}"
    for pkg in microcode_ctl intel-media-driver libva-intel-driver mesa-vulkan-drivers ffmpeg thermald; do
        if is_pkg_installed "$pkg"; then
            echo -e "  • $(printf '%-30s' "$pkg"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-30s' "$pkg"): ${YELLOW}⚠️ No instalado${NC}"
        fi
    done
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
echo -e "  🚀 ${BOLD}INICIANDO POST-INSTALACIÓN FEDORA ${FEDORA_VER} (PERFIL INTEL CORE)${NC}"
echo -e "${BOLD}======================================================================${NC}"

# 1. Optimización de DNF5
DNF_CONF="/etc/dnf/dnf.conf"
if [[ -f "$DNF_CONF" ]]; then
    grep -q "^max_parallel_downloads=" "$DNF_CONF" 2>/dev/null || echo "max_parallel_downloads=10" | $SUDO tee -a "$DNF_CONF" >/dev/null
    grep -q "^fastestmirror=" "$DNF_CONF" 2>/dev/null || echo "fastestmirror=True" | $SUDO tee -a "$DNF_CONF" >/dev/null
    grep -q "^defaultyes=" "$DNF_CONF" 2>/dev/null || echo "defaultyes=True" | $SUDO tee -a "$DNF_CONF" >/dev/null
fi

# 2. Instalación OBLIGATORIA de RPM Fusion (Free, Non-Free & Tainted)
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

# 3. Actualización del sistema
log_info "Actualizando sistema Fedora ${FEDORA_VER}..."
$SUDO "$DNF_BIN" upgrade --refresh -y

# 4. Microcódigo Intel, VA-API (iHD + i965), Vulkan ANV y FFmpeg completo
log_info "Instalando microcódigo Intel, aceleración VA-API y utilidades..."
$SUDO "$DNF_BIN" install -y --skip-unavailable \
    linux-firmware \
    microcode_ctl \
    intel-media-driver \
    libva-intel-driver \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    vulkan-loader \
    vulkan-tools \
    libva \
    libva-utils \
    thermald \
    lm_sensors \
    just \
    git \
    curl \
    wget \
    jq \
    btop \
    fastfetch \
    wl-clipboard \
    flatpak

$SUDO "$DNF_BIN" swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null || \
    $SUDO "$DNF_BIN" install -y --allowerasing ffmpeg ffmpeg-libs

$SUDO systemctl enable --now thermald.service 2>/dev/null || true
$SUDO systemctl enable --now fstrim.timer 2>/dev/null || true

if [[ -x "$SCRIPT_DIR/zram-setup.sh" ]]; then
    "$SCRIPT_DIR/zram-setup.sh"
fi

if command -v flatpak &>/dev/null; then
    $SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    $SUDO flatpak remote-modify --enable flathub --no-filter 2>/dev/null || true
fi

log_ok "Post-instalación de Fedora ${FEDORA_VER} Workstation (Perfil Intel) completada."
echo ""
show_status
