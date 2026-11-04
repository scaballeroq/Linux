#!/usr/bin/env bash
# ==============================================================================
# post-install.sh - Despachador Inteligente de Post-Instalación
# Sistema: Fedora 45 Workstation (GNOME Shell Wayland + DNF5 + RPM Fusion)
# ==============================================================================
# Detecta automáticamente la arquitectura de CPU (AMD Ryzen vs Intel Core) o
# permite selección manual y diagnóstico unificado.
# ==============================================================================

set -euo pipefail

BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
${BOLD}🚀 Despachador de Post-Instalación - Fedora 45 Workstation (GNOME Wayland)${NC}

Detecta automáticamente la arquitectura del procesador (AMD Ryzen vs Intel Core)
y ejecuta el perfil de post-instalación correspondiente con DNF5 y RPM Fusion.

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)   Auto-detecta el procesador (AMD o Intel) y ejecuta el instalador.
  --amd, -a          Ejecuta la configuración optimizada para AMD Ryzen y Radeon Graphics.
  --intel, -i        Ejecuta la configuración optimizada para Intel Core.
  --status, -s       Muestra diagnóstico rápido de plataforma y repositorios RPM Fusion.
  --help, -h         Muestra este mensaje de ayuda.

Scripts modulares invocados:
  • Setup/post-install-amd.sh   -> Optimizado para AMD Ryzen (firmware AMD, RADV, VA-API Freeworld, ZRAM)
  • Setup/post-install-intel.sh -> Optimizado para Intel Core (microcódigo Intel, iHD/i965 VA-API)
  • Setup/rpmfusion.sh          -> Gestor oficial e independiente de repositorios RPM Fusion
EOF
}

CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo 2>/dev/null | awk '{print $3}' || echo "Unknown")
CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "Unknown")

TARGET="auto"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --amd|-a|amd)     TARGET="amd"; shift ;;
        --intel|-i|intel) TARGET="intel"; shift ;;
        -s|--status|status)
            echo -e "${BOLD}======================================================================${NC}"
            echo -e "  🔍 ${BOLD}DIAGNÓSTICO DE PLATAFORMA - FEDORA WORKSTATION${NC}"
            echo -e "${BOLD}======================================================================${NC}"
            echo -e "  • CPU Detectada:    ${CYAN}${CPU_MODEL}${NC} (${CPU_VENDOR})"
            echo -e "  • Fedora Release:   ${GREEN}$(cat /etc/fedora-release 2>/dev/null || echo 'Fedora Linux')${NC}"
            echo -e "  • Kernel activo:    ${CYAN}$(uname -r)${NC}"
            if [[ -x "$SCRIPT_DIR/rpmfusion.sh" ]]; then
                echo ""
                "$SCRIPT_DIR/rpmfusion.sh" --status
            fi
            exit 0
            ;;
        -h|--help|help)   show_help; exit 0 ;;
        *)                echo -e "${RED}❌ Opción desconocida: $1${NC}"; show_help; exit 1 ;;
    esac
done

if [[ "$TARGET" == "auto" ]]; then
    if [[ "$CPU_VENDOR" == "AuthenticAMD" ]] || echo "$CPU_MODEL" | grep -qi "AMD"; then
        TARGET="amd"
    elif [[ "$CPU_VENDOR" == "GenuineIntel" ]] || echo "$CPU_MODEL" | grep -qi "Intel"; then
        TARGET="intel"
    else
        echo -e "${YELLOW}⚠️ No se pudo determinar automáticamente el procesador.${NC}"
        echo "1) AMD Ryzen / Radeon Graphics (HP ProBook 455 G10)"
        echo "2) Intel Core / HD Graphics"
        read -rp "Selecciona una opción (1 o 2) [1]: " choice
        [[ "${choice:-1}" == "2" ]] && TARGET="intel" || TARGET="amd"
    fi
fi

echo -e "${CYAN}ℹ️  Procesador detectado: ${BOLD}${CPU_MODEL}${NC} -> Ejecutando perfil ${BOLD}${TARGET^^}${NC}..."
if [[ "$TARGET" == "intel" ]]; then
    exec "$SCRIPT_DIR/post-install-intel.sh"
else
    exec "$SCRIPT_DIR/post-install-amd.sh"
fi
