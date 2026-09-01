#!/bin/bash
# podman-storybook.sh - Storybook UI Component Explorer

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando Storybook..."
podman run -d --replace \
    --name storybook-dev \
    --network dev-net \
    -p 6006:6006 \
    docker.io/library/node:lts \
    npx storybook dev -p 6006 --ci

echo "✅ Storybook iniciado en http://localhost:6006"
