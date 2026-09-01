#!/bin/bash
# podman-adminer.sh - Adminer Database Management

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando Adminer..."
podman run -d --replace \
    --name adminer-dev \
    --network dev-net \
    -p 8081:8080 \
    docker.io/library/adminer:latest

echo "✅ Adminer iniciado en http://localhost:8081"
