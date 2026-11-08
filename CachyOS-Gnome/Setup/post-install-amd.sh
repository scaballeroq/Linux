#!/usr/bin/env bash
# ==============================================================================
# post-install-amd.sh - Post-Instalación Base para Estaciones AMD Ryzen / Radeon
# Sistema: CachyOS / Arch Linux (GNOME Shell Wayland + Pacman / Paru)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics / 32GB RAM)
# Topología: Triple Monitor Full HD 1080p (DP-3, DP-4, eDP-1)
# ==============================================================================
# Características:
#   - Optimización de Pacman (/etc/pacman.conf) y Makepkg (16 hilos Zen 3).
#   - Habilitación de repositorio [multilib] para gaming y librerías de 32-bit.
#   - Integración de Chaotic-AUR para paquetes precompilados rápidos.
#   - Microcódigo AMD Ryzen (amd-ucode) y firmware oficial (linux-firmware).
#   - Early KMS con driver amdgpu en mkinitcpio para arranque limpio multi-monitor.
#   - Stack gráfico Mesa RADV (Vulkan) y aceleración por hardware VA-API (libva-mesa-driver).
#   - Librerías multilib de 32-bit para Vulkan y Mesa (lib32-vulkan-radeon, lib32-mesa).
#   - Utilidades de diagnóstico por hardware (vulkan-tools, libva-utils).
#   - Despliegue de ZRAM Swap (zstd), Flathub oficial y TRIM periódico para SSD NVMe Kioxia.
#   - Opciones CLI: --status / -s, --help / -h.
# ==============================================================================

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

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
# 2. PRIVILEGIOS Y CONTEXTO DE USUARIO
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        log_err "'sudo' no está disponible. Ejecuta este script con privilegios de superusuario."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

PACMAN_CONF="/etc/pacman.conf"

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}🚀 Post-Instalación AMD Ryzen & Radeon - CachyOS (GNOME Wayland)${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8 / 32GB RAM)

Configura Pacman para descargas paralelas y multilib, actualiza el sistema,
instala microcódigo AMD, firmware, drivers Vulkan RADV + VA-API aceleración hardware,
Early KMS para triple monitor (DP-3, DP-4, eDP-1), ZRAM (zstd), Flathub y TRIM SSD.

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)   Ejecuta toda la configuración post-instalación de AMD
  -s, --status       Muestra el estado detallado del hardware AMD, codecs, Vulkan y ZRAM
  -h, --help         Muestra esta ayuda interactiva
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO POST-INSTALACIÓN HARDWARE AMD - CACHYOS (GNOME WAYLAND)"
    echo "================================================================="
    echo "• Equipo:                        HP ProBook 455 G10"
    echo "• Modelo de CPU:                 $(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//')"
    echo "• Núcleos / Hilos lógicos:       $(nproc) hilos"
    echo "• GPU Detectada:                 $(lspci 2>/dev/null | grep -i 'vga\|display' | cut -d: -f3 | sed 's/^[ \t]*//' || echo 'AMD Radeon Graphics')"
    echo "• Driver Kernel en uso:          $(lspci -k 2>/dev/null | grep -A 2 -E "VGA|3D" | grep "Kernel driver in use" | awk '{print $5}' || echo 'amdgpu')"
    echo "-----------------------------------------------------------------"
    echo "• Microcódigo AMD instalado:     $(pacman -Q amd-ucode &>/dev/null && echo "${GREEN}Instalado${NC}" || echo "${RED}No instalado${NC}")"
    echo "• Firmware AMD instalado:        $(pacman -Q linux-firmware &>/dev/null && echo "${GREEN}Instalado${NC}" || echo "${RED}No instalado${NC}")"
    echo "• Early KMS amdgpu mkinitcpio:   $(grep -q "amdgpu" /etc/mkinitcpio.conf 2>/dev/null && echo "${GREEN}Activo${NC}" || echo "${YELLOW}No configurado en MODULES${NC}")"
    echo "• Mesa RADV Vulkan (64-bit):     $(pacman -Q vulkan-radeon &>/dev/null && echo "${GREEN}Instalado${NC}" || echo "${RED}Falta vulkan-radeon${NC}")"
    echo "• Mesa RADV Vulkan (32-bit):     $(pacman -Q lib32-vulkan-radeon &>/dev/null && echo "${GREEN}Instalado${NC}" || echo "${YELLOW}Falta lib32-vulkan-radeon${NC}")"
    echo "• Driver VA-API (libva-mesa):    $(pacman -Q libva-mesa-driver &>/dev/null && echo "${GREEN}Instalado${NC}" || echo "${RED}Falta libva-mesa-driver${NC}")"
    echo "• VA-API 32-bit:                 $(pacman -Q lib32-libva-mesa-driver &>/dev/null && echo "${GREEN}Instalado${NC}" || echo "${YELLOW}No instalado${NC}")"
    echo "-----------------------------------------------------------------"
    echo "• Topología de Pantallas (DRM):"
    if [ -d "/sys/class/drm" ]; then
        for card in /sys/class/drm/card*-*; do
            [ -e "$card/status" ] || continue
            status=$(cat "$card/status" 2>/dev/null || true)
            if [ "$status" = "connected" ]; then
                name=$(basename "$card" | sed 's/card[0-9]*-//')
                echo "   - Pantalla $name: ${GREEN}Conectada${NC}"
            fi
        done
    fi
    echo "-----------------------------------------------------------------"
    echo "• Estado de ZRAM (Swap RAM):     $(if command -v zramctl &>/dev/null && [ -n "$(zramctl 2>/dev/null)" ]; then echo "${GREEN}Activo ($(zramctl --noheadings -o ALGORITHM,DISKSIZE 2>/dev/null | head -n1))${NC}"; else echo "${YELLOW}Inactivo${NC}"; fi)"
    echo "• Repositorio Flathub:           $(flatpak remotes 2>/dev/null | grep -q "flathub" && echo "${GREEN}Configurado${NC}" || echo "${YELLOW}No configurado${NC}")"
    echo "• Repositorio Chaotic-AUR:       $(grep -q "^\[chaotic-aur\]" "$PACMAN_CONF" 2>/dev/null && echo "${GREEN}Configurado${NC}" || echo "${YELLOW}No configurado${NC}")"
    echo "• Temporizador TRIM (fstrim):    $(systemctl is-enabled --quiet fstrim.timer 2>/dev/null && echo "${GREEN}Habilitado${NC}" || echo "${YELLOW}Inactivo${NC}")"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 4. EJECUCIÓN PRINCIPAL DE POST-INSTALACIÓN AMD
# ------------------------------------------------------------------------------
run_setup() {
    log_info "Iniciando aprovisionamiento AMD Ryzen 7 7730U y Radeon Vega 8 para CachyOS..."

    # 1. Configuración de Repositorios y Pacman
    if [ -f "$SCRIPT_DIR/cachyos-repos.sh" ]; then
        log_info "[1/11] Configurando repositorios CachyOS y optimizaciones de Pacman..."
        bash "$SCRIPT_DIR/cachyos-repos.sh"
    fi

    # 2. Habilitar repositorios multilib y Chaotic-AUR
    echo "📦 [2/11] Verificando repositorios multilib y Chaotic-AUR..."
    if ! grep -q "^\[multilib\]" "$PACMAN_CONF"; then
        echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | $SUDO tee -a "$PACMAN_CONF" > /dev/null
    fi

    if ! grep -q "^\[chaotic-aur\]" "$PACMAN_CONF"; then
        $SUDO pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null || true
        $SUDO pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true
        $SUDO pacman -U --needed --noconfirm \
            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null || true
        echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | $SUDO tee -a "$PACMAN_CONF" > /dev/null
    fi

    echo "🔄 [3/11] Actualizando bases de datos de paquetes..."
    $SUDO pacman -Sy --noconfirm

    # 4. Microcódigo y Firmware para AMD
    log_info "[4/11] Instalando microcódigo y firmware AMD..."
    $SUDO pacman -S --needed --noconfirm \
        amd-ucode \
        linux-firmware

    # 5. Configurar Early KMS en mkinitcpio para arranque multi-monitor limpio
    MKINITCPIO_CONF="/etc/mkinitcpio.conf"
    if [ -f "$MKINITCPIO_CONF" ]; then
        if ! grep -E "^MODULES=.*amdgpu" "$MKINITCPIO_CONF" >/dev/null; then
            log_info "[5/11] Configurando Early KMS (amdgpu) en mkinitcpio para inicio multi-pantalla limpio..."
            if grep -q "^MODULES=()" "$MKINITCPIO_CONF"; then
                $SUDO sed -i 's/^MODULES=()/MODULES=(amdgpu)/' "$MKINITCPIO_CONF"
            else
                $SUDO sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 amdgpu)/' "$MKINITCPIO_CONF"
                $SUDO sed -i 's/(  amdgpu/(amdgpu/' "$MKINITCPIO_CONF"
            fi
            log_info "Regenerando initramfs para kernel actual..."
            $SUDO mkinitcpio -P || true
            log_ok "Early KMS amdgpu configurado correctamente."
        else
            log_ok "Early KMS (amdgpu) ya está activo en mkinitcpio."
        fi
    fi

    # 6. Stack Gráfico Mesa, Vulkan RADV y Aceleración VA-API
    log_info "[6/11] Instalando controladores Mesa RADV Vulkan y VA-API hardware (64-bit y multilib)..."
    $SUDO pacman -S --needed --noconfirm \
        mesa \
        vulkan-radeon \
        libva-mesa-driver \
        mesa-vdpau \
        vulkan-tools \
        libva-utils \
        lib32-mesa \
        lib32-vulkan-radeon \
        lib32-libva-mesa-driver \
        lib32-mesa-vdpau 2>/dev/null || \
    $SUDO pacman -S --needed --noconfirm \
        mesa \
        vulkan-radeon \
        libva-mesa-driver \
        mesa-vdpau \
        vulkan-tools \
        libva-utils

    # 7. Herramientas de telemetría y diagnósticos de hardware
    log_info "[7/11] Instalando utilidades de hardware AMD y sensores..."
    $SUDO pacman -S --needed --noconfirm \
        lm_sensors \
        pciutils \
        usbutils \
        dmidecode \
        inxi \
        clinfo 2>/dev/null || true

    # 8. Configuración de Swap ZRAM
    if [ -f "$SCRIPT_DIR/zram-setup.sh" ]; then
        log_info "[8/11] Configurando Swap de alta velocidad en ZRAM..."
        bash "$SCRIPT_DIR/zram-setup.sh"
    fi

    # 9. Mantenimiento SSD NVMe Kioxia
    log_info "[9/11] Habilitando temporizador fstrim.timer para mantenimiento periódico del NVMe..."
    $SUDO systemctl enable --now fstrim.timer

    # 10. Flathub
    if command -v flatpak &>/dev/null; then
        log_info "[10/11] Verificando repositorio oficial de Flathub..."
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    fi

    log_ok "[11/11] Post-instalación base para AMD Ryzen / Radeon en CachyOS completada con éxito."
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
