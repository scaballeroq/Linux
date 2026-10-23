#!/bin/bash
# podman-portainer.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Portainer (CE)..."
podman run -d --replace \
    --name portainer-dev \
    --network devfed-net \
    -v /run/user/$(id -u)/podman/podman.sock:/var/run/docker.sock:ro \
    -p 9443:9443 \
    docker.io/portainer/portainer-ce:latest
echo "✅ Portainer iniciado en https://localhost:9443"
