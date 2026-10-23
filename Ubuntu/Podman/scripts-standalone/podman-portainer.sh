#!/bin/bash
# podman-portainer.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v podman &>/dev/null; then
    echo "❌ Error: Podman no está instalado en el sistema."
    echo "💡 Puedes instalarlo y configurarlo ejecutando: $SCRIPT_DIR/../install/podman-install.sh"
    exit 1
fi

NETWORK="dev-net"
if podman network exists devfed-net 2>/dev/null; then
    NETWORK="devfed-net"
elif ! podman network exists "$NETWORK" 2>/dev/null; then
    podman network create "$NETWORK"
fi

echo "ℹ️ Iniciando Portainer (CE)..."
podman run -d --replace \
    --name portainer-dev \
    --network "$NETWORK" \
    -v /run/user/$(id -u)/podman/podman.sock:/var/run/docker.sock:ro \
    -p 9443:9443 \
    docker.io/portainer/portainer-ce:latest
echo "✅ Portainer iniciado en https://localhost:9443"
