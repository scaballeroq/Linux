#!/bin/bash
# podman-browserless.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Browserless Chrome..."
podman run -d --replace \
    --name browserless-dev \
    --network devfed-net \
    -p 3003:3000 \
    -e "CONNECTION_TIMEOUT=600000" \
    ghcr.io/browserless/chromium:latest
echo "✅ Browserless Chrome iniciado en puerto 3003"
