#!/bin/bash
# ==============================================================================
# zram-setup.sh - Configuración de ZRAM con compresión ZSTD para Debian TV
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / 8.0 GiB RAM)
# Sistema: Debian GNU/Linux (GNOME Shell Wayland)
# ==============================================================================
# Características:
#   - Swap comprimida en memoria RAM utilizando 'zram-tools' y algoritmo ZSTD.
#   - Asignación del 50% de la RAM física (4 GB ZRAM para 8 GB de RAM).
#   - Optimización de latencia en kernel: vm.page-cluster = 0 (cero I/O de disco).
#   - Evita el desgaste del SSD de 256 GB manteniendo la fluidez en streaming 1080p.
#   - Soporte CLI completo: --status / -s, --disable / -d, --help / -h.
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "❌ Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

show_help() {
    cat <<EOF
⚡ Configurador de Swap en RAM (ZRAM / ZSTD) - Debian TV (HP Z230 SFF)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala zram-tools, configura algoritmo zstd al 50% de RAM y activa el servicio.
  --status, -s           Muestra el estado detallado de los dispositivos ZRAM y swap activa.
  --disable, -d          Detiene y deshabilita el servicio de ZRAM.
  --help, -h             Muestra este mensaje de ayuda.

Parámetros aplicados:
  • Algoritmo:           zstd (equilibrio óptimo entre velocidad de descompresión y tasa de compresión)
  • Porcentaje de RAM:   50% (en 8 GB de RAM asigna 4 GB de swap ultrarrápida en memoria)
  • vm.page-cluster:     0 (desactiva lectura anticipada secuencial innecesaria en RAM)
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE MEMORIA ZRAM Y SWAP - DEBIAN TV (HP Z230 SFF)"
    echo "================================================================="
    
    echo "• Servicio systemd (zramswap):"
    if systemctl is-active --quiet zramswap.service 2>/dev/null; then
        echo "  - Estado: ✅ Activo y en ejecución"
    else
        echo "  - Estado: ⚪ Inactivo"
    fi
    echo "  - Habilitado al arranque: $(systemctl is-enabled zramswap.service 2>/dev/null || echo 'desconocido')"
    
    echo ""
    echo "• Dispositivos ZRAM (zramctl):"
    if command -v zramctl &>/dev/null; then
        zramctl 2>/dev/null || echo "  ℹ️ No hay dispositivos zram activos."
    else
        echo "  ❌ Herramienta zramctl no disponible."
    fi

    echo ""
    echo "• Swaps activas en el sistema:"
    swapon --show 2>/dev/null || echo "  ℹ️ No hay swap activa."

    echo ""
    echo "• Parámetros del Kernel:"
    echo "  - vm.page-cluster: $(sysctl -n vm.page-cluster 2>/dev/null || echo 'n/a') (Objetivo: 0 para ZRAM)"
    echo "  - vm.swappiness:   $(sysctl -n vm.swappiness 2>/dev/null || echo 'n/a') (Recomendado: 60-100)"
    echo "================================================================="
}

disable_zram() {
    echo "ℹ️ Deshabilitando swap ZRAM..."
    $SUDO systemctl stop zramswap.service 2>/dev/null || true
    $SUDO systemctl disable zramswap.service 2>/dev/null || true
    echo "✅ Servicio zramswap detenido y deshabilitado."
}

apply_zram() {
    echo "================================================================="
    echo "⚙️ CONFIGURANDO ZRAM CON ZSTD AL 50% DE RAM - DEBIAN WORKSTATION"
    echo "================================================================="

    # 1. Instalar paquete oficial zram-tools
    echo "ℹ️ [1/4] Verificando e instalando 'zram-tools'..."
    if ! dpkg -s zram-tools &>/dev/null; then
        $SUDO apt-get update -qq
        $SUDO apt-get install -y zram-tools
    fi

    # 2. Configurar parámetros en /etc/default/zramswap
    echo "ℹ️ [2/4] Escribiendo configuración /etc/default/zramswap..."
    cat <<'EOF' | $SUDO tee /etc/default/zramswap > /dev/null
# ==============================================================================
# /etc/default/zramswap - Configuración ZRAM Debian Workstation
# Hardware: Intel Core i7-4790 / 32 GB RAM DDR4
# ==============================================================================
# Algoritmo de compresión moderno
ALGORITHM=zstd

# Porcentaje de memoria RAM asignada a ZRAM (50% de 32GB = 16GB ZRAM)
PERCENT=50

# Prioridad máxima para que el kernel use ZRAM antes que cualquier disco swap
PRIORITY=100
EOF

    # 3. Optimización sysctl complementaria para ZRAM (page-cluster=0)
    echo "ℹ️ [3/4] Asegurando vm.page-cluster = 0..."
    $SUDO mkdir -p /etc/sysctl.d
    cat <<'EOF' | $SUDO tee /etc/sysctl.d/99-zram.conf > /dev/null
# Desactiva readahead secuencial de páginas en swap, reduciendo latencia a 0 en ZRAM
vm.page-cluster = 0
EOF
    $SUDO sysctl -w vm.page-cluster=0 >/dev/null 2>&1 || true

    # 4. Habilitar e iniciar servicio
    echo "ℹ️ [4/4] Habilitando y reiniciando zramswap.service..."
    $SUDO systemctl enable --now zramswap.service 2>/dev/null || true
    $SUDO systemctl restart zramswap.service 2>/dev/null || true

    echo ""
    show_status
    echo "================================================================="
    echo "✅ ZRAM configurado exitosamente con compresión ZSTD al 50% de RAM."
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --disable|-d|disable)
        disable_zram
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        apply_zram
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
