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
if ! podman network exists "$NETWORK" 2>/dev/null; then
    podman network create "$NETWORK"
fi

echo "ℹ️ Iniciando MongoDB con volumen persistente..."
podman run -d --replace \
    --name mongo-dev \
    --network "$NETWORK" \
    -v mongo-standalone-data:/data/db \
    -p 27017:27017 \
    docker.io/library/mongo:latest
echo "✅ MongoDB iniciado en puerto 27017 (volume: mongo-standalone-data)"
