#!/bin/bash
# podman-redis.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network
ensure_data_dir "$REDIS_DATA_DIR"

echo "ℹ️ Iniciando Redis (latest)..."
podman run -d --replace \
    --name redis-dev \
    --network "$PODMAN_NETWORK" \
    -v "$REDIS_DATA_DIR:/data:Z" \
    -p 6379:6379 \
    docker.io/library/redis:latest
echo "✅ Redis iniciado en puerto 6379"
