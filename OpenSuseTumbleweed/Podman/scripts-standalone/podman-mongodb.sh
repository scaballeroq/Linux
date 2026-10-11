#!/bin/bash
# podman-mongodb.sh

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

echo "ℹ️ Iniciando MongoDB (latest)..."
podman run -d --replace \
    --name mongo-dev \
    --network "$NETWORK" \
    -p 27017:27017 \
    docker.io/library/mongo:latest
echo "✅ MongoDB iniciado en puerto 27017"
