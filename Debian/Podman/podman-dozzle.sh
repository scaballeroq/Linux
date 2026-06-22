#!/bin/bash
# podman-dozzle.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network

echo "ℹ️ Iniciando Dozzle (Logs Viewer)..."
podman run -d --replace \
    --name dozzle-dev \
    --network "$PODMAN_NETWORK" \
    -v /run/user/$(id -u)/podman/podman.sock:/var/run/docker.sock:ro \
    -p 8888:8080 \
    docker.io/amir20/dozzle:latest
echo "✅ Dozzle iniciado en http://localhost:8888"
