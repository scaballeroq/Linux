#!/bin/bash
# ==============================================================================
# post-install.sh - Despachador Inteligente de Post-Instalación (Fedora 44)
# Detecta automáticamente la arquitectura de CPU (AMD Ryzen vs Intel Core)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat <<EOF
🚀 Despachador de Post-Instalación - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)   Auto-detecta el procesador (AMD o Intel) y ejecuta el instalador correspondiente.
  --status, -s       Muestra el estado de la post-instalación de acuerdo a la CPU detectada.
  --amd, -a          Ejecuta la configuración optimizada para AMD Ryzen y Radeon Graphics.
  --intel, -i        Ejecuta la configuración optimizada para Intel Core (Haswell/i7-4790) + Multimedia (Kodi).
  --help, -h         Muestra este mensaje de ayuda.

Scripts especializados disponibles:
  - Setup/post-install-amd.sh   -> Optimizado para AMD Ryzen (HP EliteBook 855 G7 / Vega 7 / ZRAM 16 GB)
  - Setup/post-install-intel.sh -> Optimizado para Intel Core / HD Graphics (i965 VA-API / Kodi Media Center)
EOF
}

# Auto-detección de procesador
detect_cpu() {
    local vendor
    vendor=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || echo "")
    echo "$vendor"
}

# Procesar argumentos de línea de comandos
if [ $# -gt 0 ]; then
    case "$1" in
        --amd|-a|amd)
            echo "ℹ️ Opción manual seleccionada: AMD Ryzen"
            exec "$SCRIPT_DIR/post-install-amd.sh"
            ;;
        --intel|-i|intel)
            echo "ℹ️ Opción manual seleccionada: Intel Core / Media Center"
            exec "$SCRIPT_DIR/post-install-intel.sh"
            ;;
        --status|-s|status)
            VENDOR=$(detect_cpu)
            if [ "$VENDOR" == "AuthenticAMD" ]; then
                exec "$SCRIPT_DIR/post-install-amd.sh" --status
            elif [ "$VENDOR" == "GenuineIntel" ]; then
                exec "$SCRIPT_DIR/post-install-intel.sh" --status
            else
                echo "⚠️ CPU no identificada para estado automático."
                exit 1
            fi
            ;;
        --help|-h|help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Opción no reconocida: $1"
            show_help
            exit 1
            ;;
    esac
fi

# Auto-detección y ejecución
echo "================================================================="
echo "🔍 ANALIZANDO ARQUITECTURA DE CPU DEL SISTEMA..."
echo "================================================================="

CPU_VENDOR=$(detect_cpu)
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs || echo "Desconocido")
echo "• Modelo detectado: $CPU_MODEL (Fabricante: $CPU_VENDOR)"

if [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
    echo "⚡ Procesador AMD Ryzen detectado. Ejecutando post-install-amd.sh..."
    echo ""
    exec "$SCRIPT_DIR/post-install-amd.sh"
elif [ "$CPU_VENDOR" == "GenuineIntel" ]; then
    echo "⚡ Procesador Intel detectado. Ejecutando post-install-intel.sh..."
    echo ""
    exec "$SCRIPT_DIR/post-install-intel.sh"
else
    echo "⚠️ No se pudo determinar automáticamente el fabricante del procesador."
    echo "Selecciona una opción:"
    echo "1) AMD Ryzen / Radeon Graphics"
    echo "2) Intel Core / HD Graphics (Media Center)"
    read -rp "Opción (1 o 2): " CHOICE
    case "$CHOICE" in
        1) exec "$SCRIPT_DIR/post-install-amd.sh" ;;
        2) exec "$SCRIPT_DIR/post-install-intel.sh" ;;
        *) echo "❌ Opción inválida. Abortando."; exit 1 ;;
    esac
fi
