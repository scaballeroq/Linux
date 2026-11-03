#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  post-install-amd.sh - Post-Instalación Base para Estaciones AMD Ryzen / Radeon
#  Sistema: Fedora 45 Workstation (GNOME Wayland + DNF5 + RPM Fusion Obligatorio)
#  Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics / 32GB)
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

show_help() {
    cat << EOF
${BOLD}🚀 Post-Instalación AMD Ryzen & Radeon - Fedora 45 Workstation (GNOME Wayland)${NC}

Configura DNF5 para descargas paralelas, instala obligatoriamente ${BOLD}RPM Fusion
(Free, Non-Free, Tainted y AppStream)${NC} + Cisco OpenH264, actualiza el sistema,
instala microcódigo y firmware AMD, drivers Vulkan RADV + VA-API Freeworld,
ZRAM (zstd), Flathub y herramientas esenciales de compilación y sistema.

${BOLD}Uso:${NC}
  $0 [--status | --help]
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🚀 ${BOLD}ESTADO DE POST-INSTALACIÓN AMD - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  • Sistema Operativo:         ${GREEN}$(cat /etc/fedora-release 2>/dev/null || echo 'Fedora 45 Workstation')${NC}"
    echo -e "  • Kernel activo:             ${CYAN}$(uname -r)${NC}"
    for repo in rpmfusion-free-release rpmfusion-nonfree-release; do
        if rpm -q "$repo" &>/dev/null; then
            echo -e "  • $(printf '%-26s' "$repo"): ${GREEN}Instalado${NC}"
        else
            echo -e "  • $(printf '%-26s' "$repo"): ${RED}No instalado (OBLIGATORIO)${NC}"
        fi
    done
    for pkg in amd-gpu-firmware amd-ucode-firmware mesa-vulkan-drivers mesa-va-drivers-freeworld ffmpeg zram-generator flatpak just; do
        if rpm -q "$pkg" &>/dev/null; then
            echo -e "  • Paquete $(printf '%-18s' "$pkg"): ${GREEN}Instalado${NC}"
        else
            echo -e "  • Paquete $(printf '%-18s' "$pkg"): ${YELLOW}No instalado${NC}"
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
echo -e "  🚀 ${BOLD}INICIANDO POST-INSTALACIÓN FEDORA 45 WORKSTATION (PERFIL AMD RYZEN)${NC}"
echo -e "${BOLD}======================================================================${NC}"

# 1. Optimización de DNF5 (/etc/dnf/dnf.conf)
log_info "Optimizando DNF5 (max_parallel_downloads=10, fastestmirror=True, keepcache=False)..."
DNF_CONF="/etc/dnf/dnf.conf"
if [[ -f "$DNF_CONF" ]]; then
    grep -q "^max_parallel_downloads=" "$DNF_CONF" || echo "max_parallel_downloads=10" | sudo tee -a "$DNF_CONF" >/dev/null
    grep -q "^fastestmirror=" "$DNF_CONF" || echo "fastestmirror=True" | sudo tee -a "$DNF_CONF" >/dev/null
    grep -q "^defaultyes=" "$DNF_CONF" || echo "defaultyes=True" | sudo tee -a "$DNF_CONF" >/dev/null
fi

# 2. Instalación OBLIGATORIA de RPM Fusion (Free, Non-Free, Tainted & Cisco OpenH264)
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
log_ok "Repositorios RPM Fusion Free, Non-Free, Tainted y AppStream activos."

# 3. Actualización base del sistema
log_info "Actualizando paquetes del sistema Fedora 45 Workstation..."
sudo "$DNF_BIN" upgrade --refresh -y

# 4. Firmware, Microcódigo AMD Ryzen y Gráficos Radeon (Vulkan RADV + VA-API Freeworld)
log_info "Instalando microcódigo AMD Ryzen, firmware Radeon y aceleración gráfica RADV / VA-API Freeworld..."
sudo "$DNF_BIN" install -y --skip-unavailable \
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
    lm_sensors

sudo "$DNF_BIN" swap -y mesa-va-drivers mesa-va-drivers-freeworld 2>/dev/null || \
    sudo "$DNF_BIN" install -y --allowerasing mesa-va-drivers-freeworld
sudo "$DNF_BIN" swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld 2>/dev/null || \
    sudo "$DNF_BIN" install -y --allowerasing mesa-vdpau-drivers-freeworld
sudo "$DNF_BIN" install -y --allowerasing ffmpeg ffmpeg-libs

# 5. Herramientas esenciales de sistema, desarrollo y GNOME Wayland
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
sudo "$DNF_BIN" install -y --skip-unavailable "${BASE_PKGS[@]}"

# 6. Configurar ZRAM Swap (zstd, 50% RAM)
if [[ -x "$SCRIPT_DIR/zram-setup.sh" ]]; then
    "$SCRIPT_DIR/zram-setup.sh"
fi

# 7. Configurar repositorio oficial Flathub
if command -v flatpak &>/dev/null; then
    log_info "Asegurando repositorio Flathub habilitado..."
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    sudo flatpak remote-modify --enable flathub 2>/dev/null || true
fi

# 8. Activar TRIM periódico para SSD NVMe
sudo systemctl enable --now fstrim.timer 2>/dev/null || true

log_ok "Post-instalación de Fedora 45 Workstation (AMD Ryzen / Radeon) completada con éxito."
show_status
