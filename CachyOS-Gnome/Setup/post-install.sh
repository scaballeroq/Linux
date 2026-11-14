#!/usr/bin/env bash
# ==============================================================================
# post-install.sh - Despachador Inteligente Post-Instalación
# Sistema: CachyOS / Arch Linux (GNOME Shell Wayland)
# Hardware: Detección Automática de CPU (AMD Ryzen vs Intel Core)
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
${BOLD}🔍 Despachador Inteligente Post-Instalación - CachyOS (GNOME)${NC}

Detecta la arquitectura del procesador (AMD Ryzen vs Intel Core) y delega
automáticamente en el script de aprovisionamiento optimizado correspondiente:
  - AMD:   ./Setup/post-install-amd.sh
  - Intel: ./Setup/post-install-intel.sh

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)   Detecta y ejecuta la post-instalación de hardware correspondiente
  -s, --status       Muestra el estado de hardware y drivers según la CPU detectada
  -h, --help         Muestra esta ayuda
EOF
}

CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo | cut -d: -f2 | tr -d ' ' || echo "AuthenticAMD")

ACTION="${1:-setup}"

case "$ACTION" in
    -h|--help)
        show_help
        exit 0
        ;;
    -s|--status)
        if [[ "$CPU_VENDOR" =~ "AuthenticAMD" ]]; then
            log_info "CPU AMD Ryzen detectada. Consultando estado AMD..."
            exec "$SCRIPT_DIR/post-install-amd.sh" --status
        elif [[ "$CPU_VENDOR" =~ "GenuineIntel" ]]; then
            log_info "CPU Intel Core detectada. Consultando estado Intel..."
            exec "$SCRIPT_DIR/post-install-intel.sh" --status
        else
            log_warn "CPU genérica detectada ($CPU_VENDOR). Delegando en AMD por defecto..."
            exec "$SCRIPT_DIR/post-install-amd.sh" --status
        fi
        ;;
    setup|"")
        if [[ "$CPU_VENDOR" =~ "AuthenticAMD" ]]; then
            log_info "CPU AMD Ryzen detectada. Ejecutando post-install-amd.sh..."
            exec "$SCRIPT_DIR/post-install-amd.sh"
        elif [[ "$CPU_VENDOR" =~ "GenuineIntel" ]]; then
            log_info "CPU Intel Core detectada. Ejecutando post-install-intel.sh..."
            exec "$SCRIPT_DIR/post-install-intel.sh"
        else
            log_warn "CPU genérica detectada ($CPU_VENDOR). Ejecutando post-install-amd.sh..."
            exec "$SCRIPT_DIR/post-install-amd.sh"
        fi
        ;;
    *)
        log_err "Opción no reconocida: $ACTION"
        show_help
        exit 1
        ;;
esac
