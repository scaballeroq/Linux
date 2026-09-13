#!/bin/bash
# podman-storybook.sh

set -e

if ! podman network exists dev-net; then podman network create dev-net; fi

echo "ℹ️ Iniciando Storybook (Standalone Demo)..."
podman run -d --replace \
    --name storybook-dev \
    --network dev-net \
    -p 6006:6006 \
    docker.io/storybooks/storybook:latest
echo "✅ Storybook (Demo) iniciado en http://localhost:6006"
