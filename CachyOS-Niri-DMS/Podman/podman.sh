#!/bin/bash
# podman.sh - Wrapper hacia el optimizador e instalador oficial de Podman Rootless
#
# Este archivo delega en install/podman-install.sh manteniendo compatibilidad
# con invocaciones directas en la raíz de la carpeta Podman/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install/podman-install.sh"

if [ -f "$INSTALL_SCRIPT" ]; then
    chmod +x "$INSTALL_SCRIPT"
    exec "$INSTALL_SCRIPT" "$@"
else
    echo "❌ No se encontró el instalador principal en: $INSTALL_SCRIPT"
    exit 1
fi
