#!/bin/bash
# podman-adminer.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network

echo "ℹ️ Iniciando Adminer..."
podman run -d --replace \
    --name adminer-dev \
    --network "$PODMAN_NETWORK" \
    -p 8081:8080 \
    docker.io/library/adminer:latest
echo "✅ Adminer iniciado en http://localhost:8081 (DB Admin)"
