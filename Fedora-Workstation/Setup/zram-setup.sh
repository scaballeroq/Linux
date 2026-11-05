#!/usr/bin/env bash
# ==============================================================================
# zram-setup.sh - Configuración de Swap en ZRAM (zstd) para Fedora 45 Workstation
# Optimizado para Estación de Trabajo HP ProBook 455 G10 (32 GB RAM / AMD Ryzen 7 7730U)
# Entorno: GNOME Shell (Wayland) / DNF5 / systemd zram-generator
# ==============================================================================
# Características:
#   - Swap comprimida de alto rendimiento en memoria RAM mediante zram-generator.
#   - Algoritmo zstd multinúcleo (Zen 3 / 16 hilos) al 50% de la RAM (16 GB zram0).
#   - Prioridad 100 para garantizar que ZRAM se consuma antes de cualquier swap en disco.
#   - Ajuste de kernel vm.page-cluster = 0 (lectura de páginas individuales sin latencia).
#   - vm.swappiness = 100 para descargar páginas anónimas frías y reservar RAM a buffers y caché.
#   - Eliminación de micro-tirones de compactación: vm.watermark_boost_factor = 0.
#   - Reinicio seguro e idempotente con swapoff previo para evitar "Device or resource busy".
#   - Opciones CLI: --status / -s, --disable, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 2. PRIVILEGIOS Y GESTOR DE PAQUETES
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible. Ejecuta este script con privilegios de superusuario.${NC}" >&2
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

ZRAM_CONF="/etc/systemd/zram-generator.conf"
ZRAM_SYSCTL="/etc/sysctl.d/99-zram.conf"

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO DETALLADO
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}⚡ Configurador de ZRAM Swap (zstd) - Fedora 45 Workstation (GNOME Wayland)${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM DDR4 / NVMe)

Configura swap comprimida en memoria RAM mediante ${BOLD}zram-generator${NC} de systemd
utilizando el algoritmo ${BOLD}zstd${NC} (50% de RAM, prioridad 100, swappiness 100 y page-cluster 0).

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)   Instala y configura ZRAM con algoritmo zstd al 50% de la RAM
  -s, --status       Muestra el estado detallado de ZRAM, compresión, ratio y swap activa
  --disable          Detiene el servicio ZRAM y restaura valores predeterminados
  -h, --help         Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  ⚡ ${BOLD}ESTADO DE ZRAM SWAP - FEDORA 45 WORKSTATION (32 GB RAM)${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    # 1. Paquetes instalados
    if rpm -q zram-generator &>/dev/null; then
        local ver
        ver=$(rpm -q --queryformat '%{VERSION}' zram-generator 2>/dev/null || echo "instalado")
        echo -e "  • Paquete zram-generator:        ${GREEN}✅ Instalado (v$ver)${NC}"
    else
        echo -e "  • Paquete zram-generator:        ${RED}❌ No instalado${NC}"
    fi

    # 2. Estado de Swap en ZRAM
    if swapon --show 2>/dev/null | grep -q "/dev/zram0"; then
        echo -e "  • Swap ZRAM (/dev/zram0):        ${GREEN}✅ Activo y montado como Swap (prio=100)${NC}"
    elif systemctl is-active --quiet systemd-zram-setup@zram0.service 2>/dev/null; then
        echo -e "  • Servicio ZRAM (zram0):         ${GREEN}✅ Activo (systemd-zram-setup@zram0.service)${NC}"
    else
        echo -e "  • Servicio ZRAM (zram0):         ${YELLOW}⚠️ Inactivo (Swap no inicializada)${NC}"
    fi

    # 3. Archivo de configuración
    if [[ -f "$ZRAM_CONF" ]]; then
        local algo size prio
        algo=$(grep -E '^compression-algorithm\s*=' "$ZRAM_CONF" 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "zstd")
        size=$(grep -E '^zram-size\s*=' "$ZRAM_CONF" 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "ram/2")
        prio=$(grep -E '^swap-priority\s*=' "$ZRAM_CONF" 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "100")
        echo -e "  • Configuración activa:          ${GREEN}✅ ${ZRAM_CONF}${NC} (algo=${CYAN}${algo}${NC}, size=${CYAN}${size}${NC}, prio=${CYAN}${prio}${NC})"
    else
        echo -e "  • Configuración activa:          ${YELLOW}⚠️ Por defecto del sistema (/usr/lib/systemd/zram-generator.conf)${NC}"
    fi

    # 4. Parámetros de Kernel Sysctl
    local page_cluster swappiness w_boost w_scale
    page_cluster=$(sysctl -n vm.page-cluster 2>/dev/null || echo "N/A")
    swappiness=$(sysctl -n vm.swappiness 2>/dev/null || echo "N/A")
    w_boost=$(sysctl -n vm.watermark_boost_factor 2>/dev/null || echo "N/A")
    w_scale=$(sysctl -n vm.watermark_scale_factor 2>/dev/null || echo "N/A")

    echo ""
    echo -e "${BOLD}🧠 Parámetros de Kernel Sysctl para ZRAM:${NC}"
    echo -e "  • vm.page-cluster:               ${CYAN}${page_cluster}${NC} $([[ "$page_cluster" == "0" ]] && echo -e "${GREEN}(Óptimo para ZRAM: sin lectura de bloque)${NC}" || echo -e "${YELLOW}(Recomendado: 0)${NC}")"
    echo -e "  • vm.swappiness:                 ${CYAN}${swappiness}${NC} $([[ "$swappiness" -ge 100 ]] && echo -e "${GREEN}(Óptimo para ZRAM: descarga activa de RAM fría)${NC}" || echo -e "${YELLOW}(Recomendado: >= 100)${NC}")"
    echo -e "  • vm.watermark_boost_factor:     ${CYAN}${w_boost}${NC} $([[ "$w_boost" == "0" ]] && echo -e "${GREEN}(Óptimo: sin micro-tirones kswapd)${NC}" || echo -e "${YELLOW}(Recomendado: 0)${NC}")"
    echo -e "  • vm.watermark_scale_factor:     ${CYAN}${w_scale}${NC} (Factor de amortiguación de memoria)"

    # 5. Telemetría en vivo de zramctl
    echo ""
    echo -e "${BOLD}📊 Telemetría y Ratio de Compresión ZRAM (zramctl):${NC}"
    if command -v zramctl &>/dev/null && [[ -n "$(zramctl --output-all 2>/dev/null)" ]]; then
        zramctl --output-all
        local orig compr
        orig=$(zramctl --bytes --noheadings --output DATA 2>/dev/null | tr -d ' ' || echo "0")
        compr=$(zramctl --bytes --noheadings --output COMPR 2>/dev/null | tr -d ' ' || echo "0")
        if [[ -n "$orig" && -n "$compr" && "$orig" -gt 0 && "$compr" -gt 0 ]]; then
            local ratio
            ratio=$(awk "BEGIN {printf \"%.2f\", $orig / $compr}")
            echo -e "  • ${BOLD}Factor de Compresión Real:${NC}   ${GREEN}${ratio}:1${NC} (Ahorro de memoria en RAM)"
        fi
    else
        echo "  (Ningún dispositivo ZRAM activo actualmente)"
    fi

    # 6. Dispositivos Swap activos
    echo ""
    echo -e "${BOLD}💾 Dispositivos Swap Activos (swapon):${NC}"
    swapon --show || true
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. DESHABILITACIÓN
# ------------------------------------------------------------------------------
disable_zram() {
    log_info "Deshabilitando configuración personalizada de ZRAM..."
    if swapon --show 2>/dev/null | grep -q "/dev/zram0"; then
        log_info "Desactivando swap sobre /dev/zram0..."
        $SUDO swapoff /dev/zram0 2>/dev/null || true
    fi
    $SUDO systemctl stop systemd-zram-setup@zram0.service 2>/dev/null || true
    $SUDO rm -f "$ZRAM_CONF" "$ZRAM_SYSCTL"
    $SUDO systemctl daemon-reload
    $SUDO sysctl --system >/dev/null 2>&1 || true
    log_ok "Configuración personalizada de ZRAM eliminada y restaurada a valores por defecto."
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
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

log_info "Iniciando configuración de ZRAM Swap (zstd) en Fedora 45 Workstation..."

# 1. Asegurar paquete zram-generator
if ! rpm -q zram-generator &>/dev/null; then
    log_info "Instalando zram-generator y zram-generator-defaults mediante $DNF_BIN..."
    $SUDO "$DNF_BIN" install -y zram-generator zram-generator-defaults
else
    log_ok "zram-generator ya está instalado."
fi

# 2. Configuración en /etc/systemd/zram-generator.conf (50% RAM, zstd, prioridad 100)
log_info "Desplegando configuración optimizada en $ZRAM_CONF..."
$SUDO tee "$ZRAM_CONF" > /dev/null << 'EOF'
# ==============================================================================
# Configuración ZRAM optimizada para Fedora 45 Workstation (32 GB RAM / AMD Ryzen)
# HP ProBook 455 G10 (AMD Ryzen 7 7730U - 8 núcleos / 16 hilos)
# ==============================================================================
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

# 3. Ajustes de Kernel en /etc/sysctl.d/99-zram.conf
log_info "Desplegando parámetros sysctl en $ZRAM_SYSCTL..."
$SUDO tee "$ZRAM_SYSCTL" > /dev/null << 'EOF'
# ==============================================================================
# Optimización de Kernel para Swap en ZRAM (zstd) - Fedora 45 Workstation
# ==============================================================================
# En swap sobre RAM comprimida, leer páginas individuales (2^0 = 1 página) evita latencias
vm.page-cluster = 0

# Descargar proactivamente memoria anónima inactiva a ZRAM zstd para dejar RAM libre a caché
vm.swappiness = 100

# Eliminar micro-bloqueos del recolector kswapd
vm.watermark_boost_factor = 0

# Factor de escala de marca de agua para evitar latencias directas en GNOME Wayland
vm.watermark_scale_factor = 125
EOF

$SUDO sysctl -p "$ZRAM_SYSCTL" >/dev/null 2>&1 || true

# 4. Recargar systemd y reiniciar zram de forma limpia sin "Device or resource busy"
log_info "Aplicando cambios en el servicio systemd-zram-setup@zram0.service..."

if swapon --show 2>/dev/null | grep -q "/dev/zram0"; then
    log_info "Desactivando swap temporalmente sobre /dev/zram0 para reconfiguración..."
    $SUDO swapoff /dev/zram0 2>/dev/null || true
fi

# Resetear el dispositivo de bloques zram0 para evitar EBUSY (os error 16)
if [ -b "/dev/zram0" ]; then
    $SUDO zramctl --reset /dev/zram0 2>/dev/null || true
fi

$SUDO systemctl reset-failed systemd-zram-setup@zram0.service 2>/dev/null || true
$SUDO systemctl daemon-reload

if ! $SUDO systemctl restart systemd-zram-setup@zram0.service 2>/dev/null; then
    $SUDO systemctl start systemd-zram-setup@zram0.service 2>/dev/null || true
fi

# Asegurar activación de swap si el servicio oneshot no montó la unidad
if ! swapon --show 2>/dev/null | grep -q "/dev/zram0"; then
    if [ -b "/dev/zram0" ]; then
        $SUDO mkswap -U clear /dev/zram0 2>/dev/null || true
        $SUDO swapon -p 100 /dev/zram0 2>/dev/null || true
    fi
fi

log_ok "ZRAM Swap configurado y activo con compresión zstd al 50% de RAM (16 GB)."
echo ""
show_status
