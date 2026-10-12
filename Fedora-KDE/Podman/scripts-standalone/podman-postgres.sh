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
if ! podman network exists "$NETWORK" 2>/dev/null; then
    podman network create "$NETWORK"
fi

echo "ℹ️ Iniciando PostgreSQL 17 (alpine) con volumen persistente..."
podman run -d --replace \
    --name postgres-dev \
    --network "$NETWORK" \
    -e POSTGRES_PASSWORD=postgres \
    -v postgres-standalone-data:/var/lib/postgresql/data \
    -p 5432:5432 \
    docker.io/library/postgres:17-alpine
echo "✅ PostgreSQL iniciado en puerto 5432 (user: postgres, pass: postgres, volume: postgres-standalone-data)"
