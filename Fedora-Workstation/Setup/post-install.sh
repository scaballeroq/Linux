#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  post-install.sh - Despachador Inteligente de Post-Instalación
#  Sistema: Fedora 45 Workstation (GNOME Shell Wayland + DNF5 + RPM Fusion)
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
${BOLD}🚀 Despachador de Post-Instalación - Fedora 45 Workstation (GNOME Wayland)${NC}

Detecta automáticamente la arquitectura del procesador (AMD Ryzen vs Intel Core)
y ejecuta el perfil de post-instalación correspondiente con DNF5 y RPM Fusion.

${BOLD}Uso:${NC}
  $0 [--amd | --intel | --status | --help]
EOF
}

CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo 2>/dev/null | awk '{print $3}' || echo "Unknown")
CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "Unknown")

TARGET="auto"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --amd)       TARGET="amd"; shift ;;
        --intel)     TARGET="intel"; shift ;;
        -s|--status)
            echo -e "${BOLD}🔍 Diagnóstico de Plataforma - Fedora 45 Workstation:${NC}"
            echo -e "  • CPU Detectada: ${CYAN}${CPU_MODEL}${NC} (${CPU_VENDOR})"
            echo -e "  • Fedora Release:${GREEN} $(cat /etc/fedora-release 2>/dev/null || echo 'Fedora Linux')${NC}"
            rpm -q rpmfusion-free-release &>/dev/null && echo -e "  • RPM Fusion Free:    ${GREEN}Instalado${NC}" || echo -e "  • RPM Fusion Free:    ${RED}No instalado${NC}"
            rpm -q rpmfusion-nonfree-release &>/dev/null && echo -e "  • RPM Fusion NonFree: ${GREEN}Instalado${NC}" || echo -e "  • RPM Fusion NonFree: ${RED}No instalado${NC}"
            exit 0
            ;;
        -h|--help)   show_help; exit 0 ;;
        *)           echo -e "${RED}❌ Opción desconocida: $1${NC}"; show_help; exit 1 ;;
    esac
done

if [[ "$TARGET" == "auto" ]]; then
    if [[ "$CPU_VENDOR" == "AuthenticAMD" ]] || echo "$CPU_MODEL" | grep -qi "AMD"; then
        TARGET="amd"
    elif [[ "$CPU_VENDOR" == "GenuineIntel" ]] || echo "$CPU_MODEL" | grep -qi "Intel"; then
        TARGET="intel"
    else
        TARGET="amd"
    fi
fi

echo -e "${CYAN}ℹ️  Procesador detectado: ${BOLD}${CPU_MODEL}${NC} -> Ejecutando perfil ${BOLD}${TARGET^^}${NC} en Fedora 45 Workstation..."
if [[ "$TARGET" == "intel" ]]; then
    exec "$SCRIPT_DIR/post-install-intel.sh"
else
    exec "$SCRIPT_DIR/post-install-amd.sh"
fi
