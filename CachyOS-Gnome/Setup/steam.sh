#!/usr/bin/env bash
# ==============================================================================
# steam.sh - Instalación de Steam, GameMode, MangoHud y Controladores 32-bit
# Fedora Workstation + GNOME Shell (Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / Mesa RADV)
# ==============================================================================
# Características:
#   - Activa RPM Fusion Non-Free y el repositorio oficial de Steam.
#   - Instala Steam nativo, GameMode, MangoHud y controladores 32-bit (i686).
#   - Activa aceleración HW 32-bit (mesa-va-drivers-freeworld.i686) para cinemáticas.
#   - Instala la capa de compatibilidad Proton-GE vía Flathub de forma desacoplada.
#   - Diagnóstico integral (--status) y ayuda interactiva (--help).
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
        echo -e "${RED}❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo.${NC}" >&2
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

is_pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

show_help() {
    cat <<EOF
${BOLD}🎮 Instalador de Steam y Stack de Gaming - Fedora Workstation (GNOME)${NC}

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Activa RPM Fusion Non-Free (y repo Steam), instala Steam nativo,
                      drivers 32-bit (Mesa RADV i686), GameMode, MangoHud y Proton-GE.
  --status, -s        Muestra el estado de instalación de Steam, drivers 32-bit y optimizadores.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🎮 ${BOLD}ESTADO DE STEAM Y GAMING - FEDORA WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "• RPM Fusion Non-Free:      $(if is_pkg_installed rpmfusion-nonfree-release; then echo -e "${GREEN}✅ Habilitado${NC}"; else echo -e "${RED}❌ No instalado${NC}"; fi)"
    echo -e "• Steam nativo:             $(if command -v steam &>/dev/null; then echo -e "${GREEN}✅ Sí ($(command -v steam))${NC}"; else echo -e "${RED}❌ No instalado${NC}"; fi)"
    echo -e "• GameMode:                 $(if command -v gamemoded &>/dev/null; then echo -e "${GREEN}✅ Sí ($(gamemoded --version 2>/dev/null || echo 'Activo'))${NC}"; else echo -e "${YELLOW}⚠️ No instalado${NC}"; fi)"
    echo -e "• MangoHud:                 $(if command -v mangohud &>/dev/null; then echo -e "${GREEN}✅ Sí${NC}"; else echo -e "${YELLOW}⚠️ No instalado${NC}"; fi)"
    echo -e "• Mesa Vulkan 32-bit (i686):$(if is_pkg_installed mesa-vulkan-drivers.i686; then echo -e "${GREEN}✅ Instalado (i686)${NC}"; else echo -e "${YELLOW}⚠️ No instalado (necesario para títulos 32-bit)${NC}"; fi)"
    echo -e "• Mesa DRI 32-bit (i686):   $(if is_pkg_installed mesa-dri-drivers.i686; then echo -e "${GREEN}✅ Instalado (i686)${NC}"; else echo -e "${YELLOW}⚠️ No instalado (necesario para títulos 32-bit)${NC}"; fi)"
    echo -e "• Mesa VA-API 32-bit HW:    $(if is_pkg_installed mesa-va-drivers-freeworld.i686; then echo -e "${GREEN}✅ Freeworld i686 (Aceleración activa)${NC}"; else echo -e "${YELLOW}ℹ️ No instalado${NC}"; fi)"
    echo -e "• Proton-GE Flatpak:        $(if flatpak list 2>/dev/null | grep -q "Proton-GE"; then echo -e "${GREEN}✅ Instalado${NC}"; else echo -e "${YELLOW}ℹ️ No instalado${NC}"; fi)"
    echo -e "${BOLD}======================================================================${NC}"
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo -e "${BOLD}======================================================================${NC}"
echo -e "  🎮 ${BOLD}CONFIGURANDO ENTORNO DE GAMING Y STEAM - FEDORA WORKSTATION${NC}"
echo -e "${BOLD}======================================================================${NC}"

# 1. Asegurar RPM Fusion Free y Non-Free
log_info "Verificando repositorios RPM Fusion vía Setup/rpmfusion.sh..."
if [[ -x "$SCRIPT_DIR/rpmfusion.sh" ]]; then
    "$SCRIPT_DIR/rpmfusion.sh"
else
    FEDORA_VER=$(rpm -E %fedora 2>/dev/null || echo "45")
    $SUDO "$DNF_BIN" install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm" 2>/dev/null || true
fi

# Habilitar repositorio steam de RPM Fusion si está disponible
$SUDO "$DNF_BIN" config-manager setopt rpmfusion-nonfree-steam.enabled=1 2>/dev/null || true

# 2. Instalar Steam, GameMode, MangoHud y librerías 32-bit
log_info "Instalando Steam nativo, GameMode, MangoHud y controladores 32-bit vía $DNF_BIN..."
$SUDO "$DNF_BIN" install -y --skip-unavailable \
    steam \
    gamemode \
    mangohud \
    mesa-vulkan-drivers.i686 \
    mesa-dri-drivers.i686 \
    pipewire-alsa.i686 2>/dev/null || \
    $SUDO "$DNF_BIN" install -y steam gamemode mangohud

# Intercambio de códecs 32-bit para cinemáticas de juegos
if is_pkg_installed "mesa-va-drivers.i686"; then
    $SUDO "$DNF_BIN" swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 2>/dev/null || true
fi
if is_pkg_installed "mesa-vdpau-drivers.i686"; then
    $SUDO "$DNF_BIN" swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686 2>/dev/null || true
fi

# 3. Configurar compatibilidad Proton-GE vía Flatpak
log_info "Configurando herramientas de compatibilidad Proton-GE..."
if command -v flatpak &>/dev/null; then
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    flatpak install --user -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE 2>/dev/null || true
fi

log_ok "Steam y herramientas Gaming configuradas con éxito."
echo ""
show_status
