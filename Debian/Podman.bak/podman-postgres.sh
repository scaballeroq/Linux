#!/bin/bash
# podman-postgres.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

PG_PASSWORD="${PG_PASSWORD:-postgres}"

ensure_podman_network
ensure_data_dir "$POSTGRES_DATA_DIR"

echo "ℹ️ Iniciando PostgreSQL (latest)..."
podman run -d --replace \
    --name postgres-dev \
    --network "$PODMAN_NETWORK" \
    -e POSTGRES_PASSWORD="$PG_PASSWORD" \
    -v "$POSTGRES_DATA_DIR:/var/lib/postgresql/data:Z" \
    -p 5432:5432 \
    docker.io/library/postgres:latest
echo "✅ PostgreSQL iniciado en puerto 5432 (user: postgres)"
