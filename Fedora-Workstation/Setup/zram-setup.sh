#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  zram-setup.sh - Configuración de Swap en ZRAM (zstd) para Fedora 45 Workstation
#  Optimizado para Estación de Trabajo HP ProBook 455 G10 (32 GB RAM / Ryzen 7)
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

ZRAM_CONF="/etc/systemd/zram-generator.conf"
ZRAM_SYSCTL="/etc/sysctl.d/99-zram.conf"

show_help() {
    cat << EOF
${BOLD}⚡ Configurador de ZRAM Swap (zstd) - Fedora 45 Workstation${NC}

Configura swap comprimida en memoria RAM mediante ${BOLD}zram-generator${NC} nativo de systemd
utilizando el algoritmo ${BOLD}zstd${NC} (50% de RAM, prioridad 100 y vm.page-cluster=0).

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)   Instala y configura ZRAM con algoritmo zstd al 50% de la RAM
  -s, --status       Muestra el estado actual de ZRAM, compresión y swap activa
  --disable          Detiene el servicio ZRAM y restaura valores por defecto
  -h, --help         Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  ⚡ ${BOLD}ESTADO DE ZRAM SWAP - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if rpm -q zram-generator &>/dev/null; then
        echo -e "  • Paquete zram-generator: ${GREEN}Instalado ($(rpm -q --queryformat '%{VERSION}' zram-generator))${NC}"
    else
        echo -e "  • Paquete zram-generator: ${RED}No instalado${NC}"
    fi

    if systemctl is-active --quiet systemd-zram-setup@zram0.service 2>/dev/null; then
        echo -e "  • Servicio ZRAM (zram0):  ${GREEN}Activo (systemd-zram-setup@zram0.service)${NC}"
    else
        echo -e "  • Servicio ZRAM (zram0):  ${YELLOW}Inactivo${NC}"
    fi

    if [[ -f "$ZRAM_CONF" ]]; then
        local algo size prio
        algo=$(grep -E '^compression-algorithm\s*=' "$ZRAM_CONF" 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "zstd (default)")
        size=$(grep -E '^zram-size\s*=' "$ZRAM_CONF" 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "ram/2")
        prio=$(grep -E '^swap-priority\s*=' "$ZRAM_CONF" 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "100")
        echo -e "  • Configuración activa:   ${CYAN}${ZRAM_CONF}${NC} (algo=${BOLD}${algo}${NC}, size=${BOLD}${size}${NC}, priority=${BOLD}${prio}${NC})"
    else
        echo -e "  • Configuración activa:   ${YELLOW}Usando defaults del sistema (/usr/lib/systemd/zram-generator.conf)${NC}"
    fi

    local page_cluster
    page_cluster=$(sysctl -n vm.page-cluster 2>/dev/null || echo "N/A")
    echo -e "  • Kernel vm.page-cluster: ${CYAN}${page_cluster}${NC} (óptimo para ZRAM zstd: 0)"

    echo ""
    echo -e "${BOLD}📊 Dispositivos ZRAM activos (zramctl):${NC}"
    if command -v zramctl &>/dev/null && [[ -n "$(zramctl --output-all 2>/dev/null)" ]]; then
        zramctl
    else
        echo "  (Ningún dispositivo ZRAM activo)"
    fi

    echo ""
    echo -e "${BOLD}💾 Dispositivos de Swap activos (swapon):${NC}"
    swapon --show || true
    echo -e "${BOLD}======================================================================${NC}"
}

disable_zram() {
    log_info "Deshabilitando configuración personalizada de ZRAM..."
    sudo systemctl stop systemd-zram-setup@zram0.service 2>/dev/null || true
    sudo rm -f "$ZRAM_CONF" "$ZRAM_SYSCTL"
    sudo systemctl daemon-reload
    sudo sysctl --system >/dev/null 2>&1 || true
    log_ok "Configuración personalizada de ZRAM eliminada."
}

ACTION="install"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status) ACTION="status"; shift ;;
        --disable)   ACTION="disable"; shift ;;
        -h|--help)   show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
elif [[ "$ACTION" == "disable" ]]; then
    disable_zram
    exit 0
fi

log_info "Configurando Swap en ZRAM (zstd) para Fedora 45 Workstation..."

if ! rpm -q zram-generator &>/dev/null; then
    log_info "Instalando zram-generator y zram-generator-defaults mediante $DNF_BIN..."
    sudo "$DNF_BIN" install -y zram-generator zram-generator-defaults
else
    log_ok "zram-generator ya está instalado."
fi

log_info "Escribiendo configuración optimizada en $ZRAM_CONF (50% RAM, zstd, prioridad 100)..."
sudo tee "$ZRAM_CONF" > /dev/null << 'EOF'
# Configuración ZRAM optimizada para Fedora 45 Workstation (32 GB RAM / AMD Ryzen)
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

log_info "Ajustando vm.page-cluster = 0 en $ZRAM_SYSCTL para baja latencia en ZRAM..."
sudo tee "$ZRAM_SYSCTL" > /dev/null << 'EOF'
# En swap sobre ZRAM (zstd), leer páginas individuales (2^0 = 1 página) evita latencia extra
vm.page-cluster = 0
EOF

sudo sysctl -p "$ZRAM_SYSCTL" >/dev/null 2>&1 || true
sudo systemctl daemon-reload

if systemctl is-active --quiet systemd-zram-setup@zram0.service; then
    log_info "Recargando servicio systemd-zram-setup@zram0.service..."
    sudo systemctl restart systemd-zram-setup@zram0.service || true
else
    log_info "Iniciando servicio systemd-zram-setup@zram0.service..."
    sudo systemctl start systemd-zram-setup@zram0.service || true
fi

log_ok "ZRAM configurado y activo con compresión zstd."
echo ""
show_status
