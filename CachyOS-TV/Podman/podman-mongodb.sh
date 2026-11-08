#!/bin/bash
# podman-mongodb.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando MongoDB (latest)..."
podman run -d --replace \
    --name mongo-dev \
    --network devfed-net \
    -p 27017:27017 \
    docker.io/library/mongo:latest
echo "✅ MongoDB iniciado en puerto 27017"
