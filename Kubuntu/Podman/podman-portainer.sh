#!/bin/bash
# podman-portainer.sh - Portainer Container Management UI

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

USER_UID="$(id -u)"

echo "ℹ️ Iniciando Portainer CE..."
podman run -d --replace \
    --name portainer-dev \
    --network dev-net \
    -p 9443:9443 \
    -p 9002:9000 \
    -v "/run/user/$USER_UID/podman/podman.sock:/var/run/docker.sock:ro" \
    -v portainer_data:/data \
    docker.io/portainer/portainer-ce:latest

echo "✅ Portainer iniciado en https://localhost:9443 o http://localhost:9002"
