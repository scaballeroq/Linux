#!/bin/bash
# podman-redis.sh - Redis In-Memory Cache/Store

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando Redis (latest)..."
podman run -d --replace \
    --name redis-dev \
    --network dev-net \
    -p 6379:6379 \
    docker.io/library/redis:latest

echo "✅ Redis iniciado en puerto 6379"
