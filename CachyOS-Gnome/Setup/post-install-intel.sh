#!/usr/bin/env bash
# ==============================================================================
# post-install-intel.sh - Post-Instalación Base para Sobremesa / Media Center Intel
# Sistema: CachyOS / Arch Linux (GNOME Shell Wayland + Pacman)
# ==============================================================================

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

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

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        log_err "'sudo' no está disponible. Ejecuta este script con privilegios de superusuario."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
${BOLD}🚀 Post-Instalación Intel Core & Intel Graphics - CachyOS (GNOME Wayland)${NC}

Configura Pacman para descargas paralelas y multilib, actualiza el sistema,
instala microcódigo Intel (intel-ucode), drivers Vulkan (vulkan-intel),
aceleración hardware VA-API (intel-media-driver), ZRAM (zstd) y Flathub.

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)   Ejecuta toda la configuración post-instalación de Intel
  -s, --status       Muestra el estado detallado del hardware Intel, codecs y Vulkan
  -h, --help         Muestra esta ayuda
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO POST-INSTALACIÓN HARDWARE INTEL - CACHYOS (GNOME WAYLAND)"
    echo "================================================================="
    echo "• Modelo de CPU:                 $(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//')"
    echo "• Microcódigo Intel instalado:   $(pacman -Q intel-ucode &>/dev/null && echo "${GREEN}Instalado${NC}" || echo "${RED}No instalado${NC}")"
    echo "• Mesa Vulkan Intel (64-bit):    $(pacman -Q vulkan-intel &>/dev/null && echo "${GREEN}Instalado${NC}" || echo "${RED}Falta vulkan-intel${NC}")"
    echo "• Driver VA-API (intel-media):   $(pacman -Q intel-media-driver &>/dev/null && echo "${GREEN}Instalado${NC}" || echo "${YELLOW}Falta intel-media-driver${NC}")"
    echo "• Flathub:                       $(flatpak remotes 2>/dev/null | grep -q "flathub" && echo "${GREEN}Configurado${NC}" || echo "${YELLOW}No configurado${NC}")"
    echo "================================================================="
}

run_setup() {
    log_info "Iniciando aprovisionamiento Intel Core en CachyOS..."
    if [ -f "$SCRIPT_DIR/cachyos-repos.sh" ]; then
        bash "$SCRIPT_DIR/cachyos-repos.sh"
    fi

    log_info "Actualizando base del sistema..."
    $SUDO pacman -Syu --noconfirm

    log_info "Instalando microcódigo Intel y controladores gráficos..."
    $SUDO pacman -S --needed --noconfirm \
        intel-ucode \
        mesa \
        vulkan-intel \
        intel-media-driver \
        libva-intel-driver \
        vulkan-tools \
        libva-utils \
        lib32-mesa \
        lib32-vulkan-intel 2>/dev/null || true

    if [ -f "$SCRIPT_DIR/zram-setup.sh" ]; then
        bash "$SCRIPT_DIR/zram-setup.sh"
    fi

    $SUDO systemctl enable --now fstrim.timer 2>/dev/null || true
    log_ok "Post-instalación Intel en CachyOS completada."
}

ACTION="${1:-setup}"
case "$ACTION" in
    -s|--status)
        show_status
        ;;
    -h|--help)
        show_help
        ;;
    setup|"")
        run_setup
        ;;
    *)
        log_err "Opción no reconocida: $ACTION"
        show_help
        exit 1
        ;;
esac
