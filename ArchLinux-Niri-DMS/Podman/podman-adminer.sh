#!/bin/bash
# podman-adminer.sh

set -e

if ! podman network exists dev-net; then podman network create dev-net; fi

echo "ℹ️ Iniciando Adminer..."
podman run -d --replace \
    --name adminer-dev \
    --network dev-net \
    -p 8081:8080 \
    docker.io/library/adminer:latest
echo "✅ Adminer iniciado en http://localhost:8081 (DB Admin)"
