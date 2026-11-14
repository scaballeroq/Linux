#!/usr/bin/env bash
# ==============================================================================
# zram-setup.sh - Configuración y Optimización de Swap en ZRAM (zstd) para CachyOS
# Optimizado para Estación de Trabajo HP ProBook 455 G10 (32 GB RAM / AMD Ryzen 7 7730U)
# Entorno: GNOME Shell (Wayland) / Pacman / systemd zram-generator
# ==============================================================================
# Características:
#   - Swap comprimida de ultra-baja latencia en memoria RAM mediante zram-generator.
#   - Algoritmo zstd multinúcleo (Zen 3 / 16 hilos) al 50% de la RAM (16 GB zram0)
#     o configurable al 100% (32 GB) con opción --full.
#   - Prioridad 100 para consumir ZRAM antes de cualquier swap secundaria en disco.
#   - vm.page-cluster = 0: Específico para ZRAM, lectura de páginas individuales sin
#     el overhead de readahead en memoria contigua.
#   - vm.swappiness = 180: Recomendación oficial para entornos ZRAM (preserva la caché VFS).
#   - vm.watermark_boost_factor = 0: Elimina micro-tirones y pausas de compactación de memoria.
#   - vm.watermark_scale_factor = 125: Reclamado progresivo y suave de memoria.
#   - vm.vfs_cache_pressure = 50: Mantiene estructuras de archivos/Git en caché RAM.
#   - Reseteo limpio de bloques con 'zramctl --reset' para evitar fragmentación o fugas.
#   - Comprobación idempotente: si la configuración deseada ya está activa, no reinicia.
#   - Opciones CLI: --status / -s, --half (50%), --full (100%), --disable, --help / -h.
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
${BOLD}💾 Gestor y Optimizador de ZRAM (zstd) - CachyOS Workstation${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM DDR4 / 16 hilos)

Configura zram-generator para crear un dispositivo zram0 comprimido en RAM con
algoritmo zstd multinúcleo y prioridad máxima (100).
Aplica optimizaciones de kernel: vm.page-cluster=0, vm.swappiness=180 y anti-microstutter.

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)   Aplica o verifica ZRAM optimizado al 50% de RAM (16 GB zram0 - Recomendado)
  --half             Configura ZRAM al 50% de RAM (16 GB zram0)
  --full             Configura ZRAM al 100% de RAM (32 GB zram0 - Modo agresivo de CachyOS)
  -s, --status       Muestra telemetría en tiempo real: ratio de compresión, ahorro y sysctl
  --disable          Desactiva completamente ZRAM, resetea dispositivos y restaura sysctl
  -h, --help         Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🔍 ${BOLD}ESTADO Y TELEMETRÍA DE MEMORIA SWAP EN ZRAM - CACHYOS${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "• Memoria RAM total:             ${GREEN}$(free -h | awk '/^Mem:/ {print $2}')${NC}"
    echo -e "• Memoria en uso / libre:        $(free -h | awk '/^Mem:/ {print $3}') / $(free -h | awk '/^Mem:/ {print $4}')"
    echo -e "• Swap total / en uso:           $(free -h | awk '/^Inter:/ || /^Swap:/ {print $2}') / $(free -h | awk '/^Inter:/ || /^Swap:/ {print $3}')"
    echo "-----------------------------------------------------------------"
    echo -e "• Dispositivos ZRAM activos (zramctl):"
    if command -v zramctl &>/dev/null && [ -n "$(zramctl 2>/dev/null)" ]; then
        zramctl --output NAME,DISKSIZE,DATA,COMPR,ALGORITHM,STREAMS,TOTAL,COMP-RATIO
    else
        echo -e "   ${YELLOW}No hay dispositivos ZRAM activos.${NC}"
    fi
    echo "-----------------------------------------------------------------"
    echo "• Dispositivos de swap del kernel (/proc/swaps):"
    cat /proc/swaps
    echo "-----------------------------------------------------------------"
    echo -e "• Configuración activa en $ZRAM_CONF:"
    if [ -f "$ZRAM_CONF" ]; then
        grep -v '^[[:space:]]*#' "$ZRAM_CONF" | grep -v '^[[:space:]]*$' || cat "$ZRAM_CONF"
    elif [ -f "/usr/lib/systemd/zram-generator.conf" ]; then
        echo -e "   ${CYAN}(Usando configuración por defecto de CachyOS en /usr/lib/systemd/zram-generator.conf)${NC}"
        grep -v '^[[:space:]]*#' "/usr/lib/systemd/zram-generator.conf" | grep -v '^[[:space:]]*$' || true
    else
        echo -e "   ${YELLOW}No existe archivo de configuración.${NC}"
    fi
    echo "-----------------------------------------------------------------"
    echo -e "• Parámetros de Kernel de Memoria (Sysctl):"
    echo -e "   - vm.swappiness:                 ${CYAN}$(sysctl -n vm.swappiness 2>/dev/null || echo 'n/a')${NC} (Recomendado: 180)"
    echo -e "   - vm.page-cluster:               ${CYAN}$(sysctl -n vm.page-cluster 2>/dev/null || echo 'n/a')${NC} (Recomendado ZRAM: 0)"
    echo -e "   - vm.watermark_boost_factor:     ${CYAN}$(sysctl -n vm.watermark_boost_factor 2>/dev/null || echo 'n/a')${NC} (Recomendado: 0)"
    echo -e "   - vm.watermark_scale_factor:     ${CYAN}$(sysctl -n vm.watermark_scale_factor 2>/dev/null || echo 'n/a')${NC} (Recomendado: 125)"
    echo -e "   - vm.vfs_cache_pressure:         ${CYAN}$(sysctl -n vm.vfs_cache_pressure 2>/dev/null || echo 'n/a')${NC} (Recomendado: 50)"
    echo -e "${BOLD}=================================================================${NC}"
}

disable_zram() {
    log_info "Desactivando ZRAM en CachyOS..."
    if [ -b "/dev/zram0" ]; then
        $SUDO swapoff /dev/zram0 2>/dev/null || true
        if command -v zramctl &>/dev/null; then
            $SUDO zramctl --reset /dev/zram0 2>/dev/null || true
        fi
    fi
    $SUDO rm -f "$ZRAM_CONF" "$ZRAM_SYSCTL"
    $SUDO systemctl daemon-reload
    $SUDO sysctl --system >/dev/null 2>&1 || true
    log_ok "ZRAM desactivado y restaurado a valores del sistema."
}

setup_zram() {
    local target_ratio="${1:-half}"
    local size_expr="ram / 2"
    local size_desc="50% de la RAM (16 GB)"

    if [ "$target_ratio" = "full" ]; then
        size_expr="ram"
        size_desc="100% de la RAM (32 GB)"
    fi

    log_info "Configurando Swap comprimida en ZRAM para 32 GB RAM [$size_desc]..."

    # 1. Asegurar paquete zram-generator
    if ! pacman -Q zram-generator &>/dev/null; then
        $SUDO pacman -S --needed --noconfirm zram-generator 2>/dev/null || true
    fi

    # 2. Generar /etc/systemd/zram-generator.conf
    log_info "Generando $ZRAM_CONF ($size_desc, algoritmo zstd)..."
    $SUDO tee "$ZRAM_CONF" > /dev/null << EOF
# =============================================================================
# zram-generator.conf - Configuración ZRAM para HP ProBook 455 G10 (32GB RAM)
# =============================================================================
[zram0]
zram-size = $size_expr
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

    # 3. Aplicar parámetros de kernel optimizados para ZRAM
    log_info "Aplicando parámetros de Kernel en $ZRAM_SYSCTL..."
    $SUDO tee "$ZRAM_SYSCTL" > /dev/null << 'EOF'
# =============================================================================
# 99-zram.conf - Ajustes de Kernel para Swap en Memoria Comprimida (zstd)
# =============================================================================
# Priorizar swap en RAM comprimida manteniendo la caché de archivos VFS
vm.swappiness = 180

# Lectura de páginas individuales (0 = 1 página), eliminando latencia de readahead en RAM
vm.page-cluster = 0

# Desactivar aumentos artificiales de marca de agua que provocan micro-tirones
vm.watermark_boost_factor = 0

# Reclamado suave y proactivo de memoria
vm.watermark_scale_factor = 125

# Preservar inodos y dentry en RAM para acelerar git y exploración de archivos
vm.vfs_cache_pressure = 50
EOF

    $SUDO sysctl -p "$ZRAM_SYSCTL" >/dev/null 2>&1 || $SUDO sysctl --system >/dev/null 2>&1 || true

    # 4. Reinicio seguro e idempotente de ZRAM
    log_info "Aplicando configuración y recargando systemd-zram-setup@zram0..."
    $SUDO systemctl daemon-reload
    if [ -b "/dev/zram0" ]; then
        $SUDO swapoff /dev/zram0 2>/dev/null || true
        if command -v zramctl &>/dev/null; then
            $SUDO zramctl --reset /dev/zram0 2>/dev/null || true
        fi
    fi
    $SUDO systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

    log_ok "ZRAM (zstd, $size_desc, prioridad 100) configurado y activo con éxito."
}

ACTION="${1:-half}"
case "$ACTION" in
    -s|--status)
        show_status
        ;;
    --disable)
        disable_zram
        ;;
    --half|"")
        setup_zram "half"
        ;;
    --full)
        setup_zram "full"
        ;;
    -h|--help)
        show_help
        ;;
    *)
        log_err "Opción no reconocida: $ACTION"
        show_help
        exit 1
        ;;
esac
