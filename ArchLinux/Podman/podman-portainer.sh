#!/bin/bash
# podman-portainer.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Portainer CE..."
podman run -d --replace \
    --name portainer-dev \
    --network devfed-net \
    -p 9443:9443 \
    -v /run/user/$(id -u)/podman/podman.sock:/var/run/docker.sock:ro \
    -v portainer_data:/data \
    docker.io/portainer/portainer-ce:latest
echo "✅ Portainer CE iniciado en puerto 9443 (HTTPS)"
