#!/bin/bash
# podman-portainer.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network

echo "ℹ️ Iniciando Portainer (CE)..."
podman run -d --replace \
    --name portainer-dev \
    --network "$PODMAN_NETWORK" \
    -v /run/user/$(id -u)/podman/podman.sock:/var/run/docker.sock:ro \
    -p 9443:9443 \
    docker.io/portainer/portainer-ce:latest
echo "✅ Portainer iniciado en https://localhost:9443"
