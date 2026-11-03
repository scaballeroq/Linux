#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  post-install-intel.sh - Post-Instalación Base para Sistemas Intel Core / Media
#  Sistema: Fedora 45 Workstation (GNOME Wayland + DNF5 + RPM Fusion Obligatorio)
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "-s" || "${1:-}" == "--status" ]]; then
    echo -e "${BOLD}🚀 Estado Post-Instalación Intel - Fedora 45 Workstation:${NC}"
    rpm -q rpmfusion-free-release rpmfusion-nonfree-release microcode_ctl intel-media-driver libva-intel-driver ffmpeg || true
    exit 0
fi

echo -e "${BOLD}======================================================================${NC}"
echo -e "  🚀 ${BOLD}INICIANDO POST-INSTALACIÓN FEDORA 45 WORKSTATION (PERFIL INTEL)${NC}"
echo -e "${BOLD}======================================================================${NC}"

# 1. Optimización de DNF5
DNF_CONF="/etc/dnf/dnf.conf"
if [[ -f "$DNF_CONF" ]]; then
    grep -q "^max_parallel_downloads=" "$DNF_CONF" || echo "max_parallel_downloads=10" | sudo tee -a "$DNF_CONF" >/dev/null
    grep -q "^fastestmirror=" "$DNF_CONF" || echo "fastestmirror=True" | sudo tee -a "$DNF_CONF" >/dev/null
    grep -q "^defaultyes=" "$DNF_CONF" || echo "defaultyes=True" | sudo tee -a "$DNF_CONF" >/dev/null
fi

# 2. Instalación OBLIGATORIA de RPM Fusion (Free, Non-Free & Tainted)
FEDORA_VER=$(rpm -E %fedora)
log_info "Activando repositorios obligatorios RPM Fusion (Free y Non-Free) para Fedora ${FEDORA_VER}..."
if ! rpm -q rpmfusion-free-release &>/dev/null || ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
    sudo "$DNF_BIN" install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"
fi

sudo "$DNF_BIN" config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
sudo "$DNF_BIN" install -y --skip-unavailable \
    rpmfusion-free-appstream-data \
    rpmfusion-nonfree-appstream-data \
    rpmfusion-free-release-tainted \
    rpmfusion-nonfree-release-tainted

# 3. Actualización del sistema
sudo "$DNF_BIN" upgrade --refresh -y

# 4. Microcódigo Intel, VA-API (iHD + i965), Vulkan ANV y FFmpeg completo
log_info "Instalando microcódigo Intel, aceleración VA-API (intel-media-driver / libva-intel-driver) y FFmpeg..."
sudo "$DNF_BIN" install -y --skip-unavailable \
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

sudo "$DNF_BIN" install -y --allowerasing ffmpeg ffmpeg-libs
sudo systemctl enable --now thermald.service 2>/dev/null || true
sudo systemctl enable --now fstrim.timer 2>/dev/null || true

if [[ -x "$SCRIPT_DIR/zram-setup.sh" ]]; then
    "$SCRIPT_DIR/zram-setup.sh"
fi

if command -v flatpak &>/dev/null; then
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    sudo flatpak remote-modify --enable flathub 2>/dev/null || true
fi

log_ok "Post-instalación de Fedora 45 Workstation (Perfil Intel) completada."
