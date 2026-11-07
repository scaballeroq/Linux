#!/bin/bash
# ==============================================================================
# post-install.sh - Despachador de Post-Instalación para Debian TV & Media Center
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD Graphics 4600)
# Pantalla: Sony TV (Wayland GNOME Shell)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat <<EOF
🚀 Despachador de Post-Instalación - Debian TV & Multimedia Center
Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD 4600 / Sony TV)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)   Ejecuta directamente la post-instalación optimizada para este equipo (Intel Core Haswell).
  --intel, -i        Ejecuta la configuración optimizada para Intel Core + Multimedia (Kodi/Stremio/VLC/Streaming).
  --help, -h         Muestra este mensaje de ayuda.
EOF
}

if [ $# -gt 0 ]; then
    case "$1" in
        --intel|-i|intel)
            echo "⚡ Ejecutando post-instalación optimizada para Intel Core / Centro Multimedia TV..."
            exec "$SCRIPT_DIR/post-install-intel.sh"
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

echo "🔍 Detectando procesador en HP Z230 SFF Workstation..."
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs || echo "Intel Core i7-4790")
echo "💻 CPU: $CPU_MODEL"
echo "📺 Objetivo: Centro Multimedia TV (Kodi, Stremio, VLC, Streaming Web)"
echo "🚀 Lanzando post-install-intel.sh..."
exec "$SCRIPT_DIR/post-install-intel.sh"
