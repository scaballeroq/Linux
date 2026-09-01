#!/bin/bash
# podman-browserless.sh - Headless Chrome / Puppeteer

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando Browserless (Chrome Headless)..."
podman run -d --replace \
    --name browserless-dev \
    --network dev-net \
    -p 3000:3000 \
    -e "CONCURRENT=5" \
    docker.io/browserless/chrome:latest

echo "✅ Browserless iniciado en http://localhost:3000"
