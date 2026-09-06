#!/bin/bash
# post-install.sh - Despachador y selector inteligente de post-instalacion para CachyOS (Arch Linux + KDE Plasma)
# Detecta automaticamente la arquitectura de CPU (AMD Ryzen vs Intel Core) o permite seleccion manual

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat <<EOF
Despachador de Post-Instalacion para CachyOS (Arch Linux + KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)   Auto-detecta el procesador (AMD o Intel) y ejecuta el instalador correspondiente.
  --amd, -a          Ejecuta la configuracion optimizada para AMD Ryzen y Radeon Graphics.
  --intel, -i        Ejecuta la configuracion optimizada para Intel Core + Intel Graphics.
  --help, -h         Muestra este mensaje de ayuda.

Scripts independientes disponibles:
  - Setup/post-install-amd.sh   -> Optimizado para AMD Ryzen (firmware AMD, RADV, Mesa, Chaotic-AUR, Dolphin, Pacman)
  - Setup/post-install-intel.sh -> Optimizado para Intel Core (microcodigo Intel, VA-API Intel, Chaotic-AUR, Dolphin, Pacman)
EOF
}

# Procesar argumentos de linea de comandos
if [ $# -gt 0 ]; then
    case "$1" in
        --amd|-a|amd)
            echo "Opcion manual seleccionada: AMD Ryzen"
            exec "$SCRIPT_DIR/post-install-amd.sh"
            ;;
        --intel|-i|intel)
            echo "Opcion manual seleccionada: Intel Core"
            exec "$SCRIPT_DIR/post-install-intel.sh"
            ;;
        --help|-h|help)
            show_help
            exit 0
            ;;
        *)
            echo "Opcion no reconocida: $1"
            show_help
            exit 1
            ;;
    esac
fi

# Auto-deteccion de procesador
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
    echo "No se pudo determinar automaticamente el fabricante del procesador."
    echo "Que configuracion deseas aplicar?"
    echo "1) AMD Ryzen / Radeon Graphics"
    echo "2) Intel Core / Intel HD Graphics"
    read -rp "Selecciona una opcion (1 o 2): " CHOICE
    case "$CHOICE" in
        1)
            exec "$SCRIPT_DIR/post-install-amd.sh"
            ;;
        2)
            exec "$SCRIPT_DIR/post-install-intel.sh"
            ;;
        *)
            echo "Seleccion invalida. Abortando."
            exit 1
            ;;
    esac
fi
