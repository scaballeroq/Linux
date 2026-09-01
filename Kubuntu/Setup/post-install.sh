#!/bin/bash
# post-install.sh - Despachador inteligente de post-instalación para Kubuntu
# Detecta automáticamente el procesador (AMD Ryzen vs Intel Core) y ejecuta el instalador correspondiente

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat <<EOF
Despachador de Post-Instalación para Kubuntu (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)   Auto-detecta el procesador (AMD o Intel) y ejecuta el instalador correspondiente.
  --amd, -a          Ejecuta la configuración optimizada para AMD Ryzen y Radeon Graphics.
  --intel, -i        Ejecuta la configuración optimizada para Intel Core + Intel Graphics.
  --help, -h         Muestra este mensaje de ayuda.

Scripts independientes disponibles:
  - Setup/post-install-amd.sh   -> Optimizado para AMD Ryzen (microcode AMD, RADV, Mesa, ZRAM)
  - Setup/post-install-intel.sh -> Optimizado para Intel Core (microcode Intel, VA-API Intel, Mesa)
EOF
}

if [ $# -gt 0 ]; then
    case "$1" in
        --amd|-a|amd)
            echo "Opción manual seleccionada: AMD Ryzen"
            exec "$SCRIPT_DIR/post-install-amd.sh"
            ;;
        --intel|-i|intel)
            echo "Opción manual seleccionada: Intel Core"
            exec "$SCRIPT_DIR/post-install-intel.sh"
            ;;
        --help|-h|help)
            show_help
            exit 0
            ;;
        *)
            echo "Opción no reconocida: $1"
            show_help
            exit 1
            ;;
    esac
fi

echo "Analizando procesador y arquitectura del sistema..."
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || true)
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs || echo "Desconocido")

echo "CPU Detectado: $CPU_MODEL (Vendor: $CPU_VENDOR)"

if [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
    echo "Procesador AMD detectado. Ejecutando post-install-amd.sh..."
    exec "$SCRIPT_DIR/post-install-amd.sh"
elif [ "$CPU_VENDOR" == "GenuineIntel" ]; then
    echo "Procesador Intel detectado. Ejecutando post-install-intel.sh..."
    exec "$SCRIPT_DIR/post-install-intel.sh"
else
    echo "No se pudo determinar automáticamente el fabricante del procesador."
    echo "Qué configuración deseas aplicar?"
    echo "1) AMD Ryzen / Radeon Graphics"
    echo "2) Intel Core / Intel HD Graphics"
    read -rp "Selecciona una opción (1 o 2): " CHOICE
    case "$CHOICE" in
        1)
            exec "$SCRIPT_DIR/post-install-amd.sh"
            ;;
        2)
            exec "$SCRIPT_DIR/post-install-intel.sh"
            ;;
        *)
            echo "Selección inválida. Abortando."
            exit 1
            ;;
    esac
fi
