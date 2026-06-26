#!/bin/bash
# podman-dozzle.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Dozzle (container log viewer)..."
podman run -d --replace \
    --name dozzle-dev \
    --network devfed-net \
    -p 8888:8080 \
    -v /run/user/$(id -u)/podman/podman.sock:/var/run/docker.sock:ro \
    amir20/dozzle:latest
echo "✅ Dozzle iniciado en puerto 8888"
