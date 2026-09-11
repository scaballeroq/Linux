#!/bin/bash
# podman-browserless.sh

set -e

if ! podman network exists dev-net; then podman network create dev-net; fi

echo "ℹ️ Iniciando Browserless (Chrome)..."
podman run -d --replace \
    --name browserless-dev \
    --network dev-net \
    -p 3003:3000 \
    docker.io/browserless/chrome:latest
echo "✅ Browserless iniciado en puerto 3003"
