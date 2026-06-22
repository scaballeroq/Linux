#!/bin/bash
# podman-browserless.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network

echo "ℹ️ Iniciando Browserless (Chrome)..."
podman run -d --replace \
    --name browserless-dev \
    --network "$PODMAN_NETWORK" \
    -p 3003:3000 \
    docker.io/browserless/chrome:latest
echo "✅ Browserless iniciado en puerto 3003"
