#!/usr/bin/env bash
# ==============================================================================
# Juegos/steam.sh - Lanzador de Steam con GameMode y MangoHud en NixOS
# ==============================================================================

set -euo pipefail

if ! command -v steam &>/dev/null; then
    echo "❌ Steam no está instalado en el sistema."
    echo "💡 Puedes activarlo en tu configuración de NixOS (modules/gaming.nix)"
    exit 1
fi

LAUNCH_CMD="steam"

# Ejecutar con GameMode si está disponible
if command -v gamemoderun &>/dev/null; then
    echo "🚀 Lanzando Steam con GameMode..."
    LAUNCH_CMD="gamemoderun $LAUNCH_CMD"
fi

# Ejecutar
exec $LAUNCH_CMD "$@"
