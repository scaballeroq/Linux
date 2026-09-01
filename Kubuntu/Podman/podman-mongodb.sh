#!/bin/bash
# podman-mongodb.sh - MongoDB Database

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando MongoDB..."
podman run -d --replace \
    --name mongo-dev \
    --network dev-net \
    -p 27017:27017 \
    docker.io/library/mongo:latest

echo "✅ MongoDB iniciado en puerto 27017"
