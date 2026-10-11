#!/bin/bash
# podman-storybook.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Storybook standalone..."
podman run -d --replace \
    --name storybook-dev \
    --network devfed-net \
    -p 6006:6006 \
    docker.io/storybook/storybook:latest
echo "✅ Storybook iniciado en puerto 6006"
