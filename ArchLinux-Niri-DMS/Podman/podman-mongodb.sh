#!/bin/bash
# podman-mongodb.sh

set -e

if ! podman network exists dev-net; then podman network create dev-net; fi

echo "ℹ️ Iniciando MongoDB (latest)..."
podman run -d --replace \
    --name mongo-dev \
    --network dev-net \
    -p 27017:27017 \
    docker.io/library/mongo:latest
echo "✅ MongoDB iniciado en puerto 27017"
