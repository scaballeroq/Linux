#!/bin/bash
# podman-redis.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Redis (latest)..."
podman run -d --replace \
    --name redis-dev \
    --network devfed-net \
    -p 6379:6379 \
    docker.io/library/redis:latest
echo "✅ Redis iniciado en puerto 6379"
