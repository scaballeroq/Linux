#!/bin/bash
# podman-redis.sh

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

echo "ℹ️ Iniciando Redis 7 (alpine) con volumen persistente..."
podman run -d --replace \
    --name redis-dev \
    --network "$NETWORK" \
    -v redis-standalone-data:/data \
    -p 6379:6379 \
    docker.io/library/redis:7-alpine redis-server --appendonly yes
echo "✅ Redis iniciado en puerto 6379 (volume: redis-standalone-data)"
