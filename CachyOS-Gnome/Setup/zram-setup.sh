#!/usr/bin/env bash
# ==============================================================================
# zram-setup.sh - Configuración de Swap en ZRAM (zstd) para CachyOS Workstation
# Optimizado para Estación de Trabajo HP ProBook 455 G10 (32 GB RAM / AMD Ryzen 7 7730U)
# Entorno: GNOME Shell (Wayland) / Pacman / systemd zram-generator
# ==============================================================================
# Características:
#   - Swap comprimida de alto rendimiento en memoria RAM mediante zram-generator.
#   - Algoritmo zstd multinúcleo (Zen 3 / 16 hilos) al 50% de la RAM (16 GB zram0).
#   - Prioridad 100 para garantizar que ZRAM se consuma antes de cualquier swap en disco.
#   - Ajuste de kernel vm.page-cluster = 0 (lectura de páginas individuales sin latencia).
#   - vm.swappiness = 180 para priorizar memoria comprimida en RAM y preservar caché VFS.
#   - Eliminación de micro-tirones de compactación: vm.watermark_boost_factor = 0.
#   - Reinicio seguro e idempotente con swapoff previo para evitar "Device or resource busy".
#   - Opciones CLI: --status / -s, --disable, --help / -h.
# ==============================================================================

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

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
        log_err "'sudo' no está disponible. Ejecuta este script con privilegios de superusuario."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

ZRAM_CONF="/etc/systemd/zram-generator.conf"
ZRAM_SYSCTL="/etc/sysctl.d/99-zram.conf"

show_help() {
    cat << EOF
${BOLD}💾 Gestor de Memoria Comprimida ZRAM (zstd) - CachyOS Workstation${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM DDR4 / 16 hilos)

Configura zram-generator para crear un dispositivo zram0 comprimido con zstd
equivalente al 50% de la memoria física (16 GB en este equipo) con prioridad 100.
Aplica parámetros sysctl vm.page-cluster=0 y vm.swappiness=180 para máxima fluidez.

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)   Instala, configura y activa ZRAM zstd en CachyOS
  -s, --status       Muestra el estado detallado de ZRAM, algoritmos y parámetros sysctl
  --disable          Desactiva y retira la configuración de ZRAM
  -h, --help         Muestra esta ayuda
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE MEMORIA SWAP EN ZRAM - CACHYOS"
    echo "================================================================="
    echo "• Memoria RAM total:             $(free -h | awk '/^Mem:/ {print $2}')"
    echo "• Algoritmo y tamaño zramctl:"
    if command -v zramctl &>/dev/null && [ -n "$(zramctl 2>/dev/null)" ]; then
        zramctl
    else
        echo "   ${YELLOW}No hay dispositivos ZRAM activos.${NC}"
    fi
    echo "-----------------------------------------------------------------"
    echo "• Dispositivos de swap activos (/proc/swaps):"
    cat /proc/swaps
    echo "-----------------------------------------------------------------"
    echo "• Archivo de configuración:      $ZRAM_CONF"
    if [ -f "$ZRAM_CONF" ]; then
        cat "$ZRAM_CONF"
    else
        echo "   ${YELLOW}No existe $ZRAM_CONF${NC}"
    fi
    echo "-----------------------------------------------------------------"
    echo "• vm.swappiness:                 $(sysctl -n vm.swappiness 2>/dev/null || echo 'n/a')"
    echo "• vm.page-cluster:               $(sysctl -n vm.page-cluster 2>/dev/null || echo 'n/a')"
    echo "• vm.watermark_boost_factor:     $(sysctl -n vm.watermark_boost_factor 2>/dev/null || echo 'n/a')"
    echo "• vm.watermark_scale_factor:     $(sysctl -n vm.watermark_scale_factor 2>/dev/null || echo 'n/a')"
    echo "================================================================="
}

disable_zram() {
    log_info "Desactivando ZRAM en CachyOS..."
    if [ -b "/dev/zram0" ]; then
        $SUDO swapoff /dev/zram0 2>/dev/null || true
    fi
    $SUDO rm -f "$ZRAM_CONF" "$ZRAM_SYSCTL"
    $SUDO systemctl daemon-reload
    $SUDO sysctl --system >/dev/null 2>&1 || true
    log_ok "ZRAM desactivado correctamente."
}

setup_zram() {
    log_info "Configurando Swap comprimida en ZRAM para 32 GB RAM (HP ProBook 455 G10)..."

    $SUDO pacman -S --needed --noconfirm zram-generator 2>/dev/null || true

    log_info "Generando $ZRAM_CONF..."
    $SUDO tee "$ZRAM_CONF" > /dev/null << 'EOF'
# =============================================================================
# zram-generator.conf - Configuración ZRAM para HP ProBook 455 G10 (32GB RAM)
# =============================================================================
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

    log_info "Configurando parámetros de Kernel en $ZRAM_SYSCTL..."
    $SUDO tee "$ZRAM_SYSCTL" > /dev/null << 'EOF'
# =============================================================================
# 99-zram.conf - Ajustes de Kernel para Swap en Memoria Comprimida (zstd)
# =============================================================================
vm.swappiness = 180
vm.page-cluster = 0
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
EOF

    $SUDO sysctl -p "$ZRAM_SYSCTL" >/dev/null 2>&1 || $SUDO sysctl --system >/dev/null 2>&1 || true

    log_info "Reiniciando servicio zram-generator..."
    $SUDO systemctl daemon-reload
    if [ -b "/dev/zram0" ]; then
        $SUDO swapoff /dev/zram0 2>/dev/null || true
    fi
    $SUDO systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

    log_ok "ZRAM (zstd, 50% RAM = 16GB, prioridad 100) configurado con éxito."
}

ACTION="${1:-setup}"
case "$ACTION" in
    -s|--status)
        show_status
        ;;
    --disable)
        disable_zram
        ;;
    -h|--help)
        show_help
        ;;
    setup|"")
        setup_zram
        ;;
    *)
        log_err "Opción no reconocida: $ACTION"
        show_help
        exit 1
        ;;
esac
