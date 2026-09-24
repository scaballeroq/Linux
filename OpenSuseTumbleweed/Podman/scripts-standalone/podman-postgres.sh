#!/bin/bash
# podman-postgres.sh

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

echo "ℹ️ Iniciando PostgreSQL (latest)..."
podman run -d --replace \
    --name postgres-dev \
    --network "$NETWORK" \
    -e POSTGRES_PASSWORD=postgres \
    -p 5432:5432 \
    docker.io/library/postgres:latest
echo "✅ PostgreSQL iniciado en puerto 5432 (user: postgres, pass: postgres)"
