#!/bin/bash
# podman-dozzle.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Dozzle (Logs Viewer)..."
podman run -d --replace \
    --name dozzle-dev \
    --network devfed-net \
    -v /run/user/$(id -u)/podman/podman.sock:/var/run/docker.sock:ro \
    -p 8888:8080 \
    docker.io/amir20/dozzle:latest
echo "✅ Dozzle iniciado en http://localhost:8888"
