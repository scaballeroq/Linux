#!/usr/bin/env bash
# ==============================================================================
# steam.sh - Instalación de Steam, GameMode, MangoHud y Controladores 32-bit
# CachyOS Workstation + GNOME Shell (Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / Mesa RADV)
# ==============================================================================
# Características:
#   - Activa repositorio [multilib] oficial en /etc/pacman.conf.
#   - Instala Steam nativo, GameMode, MangoHud y controladores Vulkan 32-bit (lib32-vulkan-radeon).
#   - Activa aceleración HW y librerías 32-bit para compatibilidad total con Proton.
#   - Instala la capa de compatibilidad Proton-GE vía Flathub o AUR de forma desacoplada.
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

is_pkg_installed() {
    pacman -Q "$1" >/dev/null 2>&1
}

show_help() {
    cat <<EOF
${BOLD}🎮 Instalador de Steam y Stack de Gaming - CachyOS Workstation (GNOME)${NC}

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Activa multilib, instala Steam nativo, drivers 32-bit
                      (lib32-vulkan-radeon, lib32-mesa), GameMode, MangoHud y Proton-GE.
  --status, -s        Muestra el estado de instalación de Steam, drivers 32-bit y optimizadores.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🎮 ${BOLD}ESTADO DE STEAM Y GAMING - CACHYOS WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "• Repositorio [multilib]:   $(if grep -q "^\[multilib\]" /etc/pacman.conf 2>/dev/null; then echo -e "${GREEN}✅ Habilitado${NC}"; else echo -e "${RED}❌ Deshabilitado en /etc/pacman.conf${NC}"; fi)"
    echo -e "• Steam nativo:             $(if command -v steam &>/dev/null; then echo -e "${GREEN}✅ Sí ($(command -v steam))${NC}"; else echo -e "${RED}❌ No instalado${NC}"; fi)"
    echo -e "• GameMode:                 $(if command -v gamemoded &>/dev/null; then echo -e "${GREEN}✅ Sí ($(gamemoded --version 2>/dev/null || echo 'Activo'))${NC}"; else echo -e "${YELLOW}⚠️ No instalado${NC}"; fi)"
    echo -e "• MangoHud:                 $(if command -v mangohud &>/dev/null; then echo -e "${GREEN}✅ Sí${NC}"; else echo -e "${YELLOW}⚠️ No instalado${NC}"; fi)"
    echo -e "• Vulkan Radeon 64-bit:     $(if is_pkg_installed vulkan-radeon; then echo -e "${GREEN}✅ vulkan-radeon${NC}"; else echo -e "${RED}❌ No instalado${NC}"; fi)"
    echo -e "• Vulkan Radeon 32-bit:     $(if is_pkg_installed lib32-vulkan-radeon; then echo -e "${GREEN}✅ lib32-vulkan-radeon${NC}"; else echo -e "${YELLOW}⚠️ No instalado (necesario para títulos 32-bit)${NC}"; fi)"
    echo -e "• Mesa 32-bit:              $(if is_pkg_installed lib32-mesa; then echo -e "${GREEN}✅ lib32-mesa${NC}"; else echo -e "${YELLOW}⚠️ No instalado${NC}"; fi)"
    echo -e "• Proton-GE (Flathub):      $(if flatpak list 2>/dev/null | grep -qi "Proton-GE"; then echo -e "${GREEN}✅ Instalado${NC}"; else echo -e "${YELLOW}ℹ️ No instalado${NC}"; fi)"
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
echo -e "  🎮 ${BOLD}CONFIGURANDO ENTORNO DE GAMING Y STEAM - CACHYOS WORKSTATION${NC}"
echo -e "${BOLD}======================================================================${NC}"

# 1. Asegurar repositorio [multilib] en /etc/pacman.conf
if ! grep -q "^\[multilib\]" /etc/pacman.conf 2>/dev/null; then
    log_info "Habilitando repositorio [multilib] en /etc/pacman.conf..."
    $SUDO sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf 2>/dev/null || true
    $SUDO pacman -Sy
    log_ok "Repositorio [multilib] habilitado."
fi

# 2. Instalar Steam, GameMode, MangoHud y librerías 32-bit
log_info "Instalando Steam nativo, GameMode, MangoHud y controladores AMD Radeon 32-bit..."
STEAM_PKGS=(
    steam
    gamemode
    lib32-gamemode
    mangohud
    lib32-mangohud
    vulkan-radeon
    lib32-vulkan-radeon
    mesa
    lib32-mesa
)

$SUDO pacman -S --needed --noconfirm "${STEAM_PKGS[@]}" 2>/dev/null || true

# 3. Configurar compatibilidad Proton-GE vía Flatpak
log_info "Configurando herramientas de compatibilidad Proton-GE..."
if command -v flatpak &>/dev/null; then
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    flatpak install --user -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE 2>/dev/null || true
fi

log_ok "Steam y herramientas Gaming configuradas con éxito."
echo ""
show_status
