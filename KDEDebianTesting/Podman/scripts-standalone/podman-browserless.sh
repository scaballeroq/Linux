#!/bin/bash
# podman-browserless.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v podman &>/dev/null; then
    echo "❌ Error: Podman no está instalado en el sistema."
    echo "💡 Puedes instalarlo y configurarlo ejecutando: $SCRIPT_DIR/../install/podman-install.sh"
    exit 1
fi

NETWORK="dev-net"
if ! podman network exists "$NETWORK" 2>/dev/null; then
    podman network create "$NETWORK"
fi

GPU_OPTS=()
if [ -e /dev/dri/renderD128 ]; then
    GPU_OPTS=(--device /dev/dri/card0 --device /dev/dri/renderD128)
fi

echo "ℹ️ Iniciando Browserless (Chrome) con GPU y shm-size..."
podman run -d --replace \
    --name browserless-dev \
    --network "$NETWORK" \
    --shm-size=2g \
    "${GPU_OPTS[@]}" \
    -p 3003:3000 \
    docker.io/browserless/chrome:latest
echo "✅ Browserless iniciado en puerto 3003"
