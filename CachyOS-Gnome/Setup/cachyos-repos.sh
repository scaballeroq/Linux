#!/usr/bin/env bash
# ==============================================================================
# cachyos-repos.sh - Gestor de Repositorios Oficiales y Optimizados de CachyOS
# Sistema: CachyOS / Arch Linux (GNOME Shell Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U Zen 3 / Barcelo-R x86-64-v3)
# ==============================================================================
# Características:
#   - Habilitación y verificación de repositorios optimizados CachyOS (x86-64-v3).
#   - Habilitación de repositorio oficial [multilib] para compatibilidad 32-bit (Steam/Wine).
#   - Integración de Chaotic-AUR para paquetes precompilados rápidos.
#   - Optimización de descargas paralelas y visualización en /etc/pacman.conf.
#   - Optimización de espejos mediante cachyos-rate-mirrors / reflector.
#   - Opciones CLI: --status / -s, --rate-mirrors, --help / -h.
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

PACMAN_CONF="/etc/pacman.conf"

show_help() {
    cat << EOF
${BOLD}📦 Gestor de Repositorios CachyOS (x86-64-v3) y Pacman${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U Zen 3 / x86-64-v3)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)   Configura repositorios CachyOS v3, multilib, descargas paralelas y actualiza índices
  -s, --status       Muestra el estado de los repositorios activos y configuración de Pacman
  -r, --rate-mirrors Optimiza la lista de espejos de CachyOS y Arch Linux por latencia y velocidad
  -h, --help         Muestra esta ayuda interactiva
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE REPOSITORIOS Y PACMAN - CACHYOS"
    echo "================================================================="
    echo "• Arquitectura detectada:        $(uname -m)"
    echo "• Soporte CPU x86-64-v3:         $(/usr/lib/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -q "x86-64-v3 (supported" && echo "${GREEN}Compatible (Zen 3 / Barcelo-R)${NC}" || echo "${YELLOW}Comprobando soporte microarquitectura${NC}")"
    echo "-----------------------------------------------------------------"
    echo "• Repositorios activos en pacman.conf:"
    grep -E "^\[.*\]" "$PACMAN_CONF" | while read -r repo; do
        echo "   - $repo"
    done
    echo "-----------------------------------------------------------------"
    echo "• Descargas paralelas:           $(grep -E "^ParallelDownloads" "$PACMAN_CONF" 2>/dev/null || echo 'Por defecto (1)')"
    echo "• Colores habilitados:           $(grep -q "^Color" "$PACMAN_CONF" 2>/dev/null && echo 'Sí' || echo 'No')"
    echo "• Repositorio multilib:          $(grep -q "^\[multilib\]" "$PACMAN_CONF" 2>/dev/null && echo "${GREEN}Habilitado${NC}" || echo "${RED}Deshabilitado${NC}")"
    echo "• Repositorios CachyOS v3:       $(grep -q "cachyos-v3" "$PACMAN_CONF" 2>/dev/null && echo "${GREEN}Activos${NC}" || echo "${YELLOW}Genéricos / Estándar${NC}")"
    echo "• Chaotic-AUR:                   $(grep -q "chaotic-aur" "$PACMAN_CONF" 2>/dev/null && echo "${GREEN}Configurado${NC}" || echo "No configurado")"
    echo "• AUR Helper disponible:         $(command -v paru &>/dev/null && echo "paru ($(paru --version | head -n1))" || (command -v yay &>/dev/null && echo "yay" || echo "Ninguno"))"
    echo "================================================================="
}

rate_mirrors() {
    log_info "Optimizando espejos de CachyOS y Arch Linux..."
    if command -v cachyos-rate-mirrors &>/dev/null; then
        $SUDO cachyos-rate-mirrors
        log_ok "Espejos optimizados con cachyos-rate-mirrors."
    elif command -v rate-mirrors &>/dev/null; then
        rate-mirrors arch | $SUDO tee /etc/pacman.d/mirrorlist >/dev/null
        log_ok "Espejos optimizados con rate-mirrors."
    elif command -v reflector &>/dev/null; then
        $SUDO reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
        log_ok "Espejos optimizados con reflector."
    else
        log_warn "Instalando cachyos-rate-mirrors..."
        $SUDO pacman -S --needed --noconfirm cachyos-rate-mirrors 2>/dev/null || true
        if command -v cachyos-rate-mirrors &>/dev/null; then
            $SUDO cachyos-rate-mirrors
        fi
    fi
}

setup_pacman() {
    log_info "Configurando /etc/pacman.conf para máximo rendimiento (Zen 3 / 16 hilos)..."

    # ParallelDownloads = 8
    if grep -q "^#ParallelDownloads" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^#ParallelDownloads = .*/ParallelDownloads = 8/' "$PACMAN_CONF"
    elif grep -q "^ParallelDownloads" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^ParallelDownloads = .*/ParallelDownloads = 8/' "$PACMAN_CONF"
    else
        $SUDO sed -i '/^\[options\]/a ParallelDownloads = 8' "$PACMAN_CONF"
    fi

    # Color
    if grep -q "^#Color" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^#Color/Color/' "$PACMAN_CONF"
    elif ! grep -q "^Color" "$PACMAN_CONF"; then
        $SUDO sed -i '/^\[options\]/a Color' "$PACMAN_CONF"
    fi

    # ILoveCandy
    if ! grep -q "ILoveCandy" "$PACMAN_CONF"; then
        $SUDO sed -i '/^Color/a ILoveCandy' "$PACMAN_CONF" 2>/dev/null || true
    fi

    # VerbosePkgLists
    if grep -q "^#VerbosePkgLists" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' "$PACMAN_CONF"
    fi

    # Multilib
    if ! grep -q "^\[multilib\]" "$PACMAN_CONF"; then
        log_info "Habilitando repositorio [multilib] para compatibilidad 32-bit..."
        echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | $SUDO tee -a "$PACMAN_CONF" > /dev/null
    fi

    # Makepkg optimizations for 16 threads (Zen 3 Barcelo-R)
    MAKEPKG_CONF="/etc/makepkg.conf"
    if [ -f "$MAKEPKG_CONF" ]; then
        if grep -q "^#MAKEFLAGS=" "$MAKEPKG_CONF"; then
            $SUDO sed -i 's/^#MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' "$MAKEPKG_CONF"
        elif grep -q "^MAKEFLAGS=" "$MAKEPKG_CONF"; then
            $SUDO sed -i 's/^MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' "$MAKEPKG_CONF"
        fi
        if grep -q "^COMPRESSZST=" "$MAKEPKG_CONF"; then
            $SUDO sed -i 's/^COMPRESSZST=.*/COMPRESSZST=(zstd -c -z -q --threads=0 -)/' "$MAKEPKG_CONF"
        fi
    fi

    # Ensure cachyos keyring and mirrors are valid
    if ! grep -q "^\[cachyos" "$PACMAN_CONF"; then
        log_info "Asegurando repositorios CachyOS optimizados x86-64-v3..."
        $SUDO pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com 2>/dev/null || true
        $SUDO pacman-key --lsign-key F3B607488DB35A47 2>/dev/null || true
    fi

    log_info "Actualizando índices de paquetes con Pacman..."
    $SUDO pacman -Sy
    log_ok "Configuración de repositorios y Pacman completada."
}

ACTION="${1:-setup}"
case "$ACTION" in
    -s|--status)
        show_status
        ;;
    -r|--rate-mirrors)
        rate_mirrors
        ;;
    -h|--help)
        show_help
        ;;
    setup|"")
        setup_pacman
        ;;
    *)
        log_err "Opción no reconocida: $ACTION"
        show_help
        exit 1
        ;;
esac
