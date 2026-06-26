#!/bin/bash
# podman-mongodb.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando MongoDB..."
podman run -d --replace \
    --name mongodb-dev \
    --network devfed-net \
    -p 27017:27017 \
    -v mongodb_data:/data/db \
    docker.io/library/mongo:latest
echo "✅ MongoDB iniciado en puerto 27017"
