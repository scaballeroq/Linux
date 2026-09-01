#!/bin/bash
# podman-dozzle.sh - Real-time Log Viewer

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

USER_UID="$(id -u)"

echo "ℹ️ Iniciando Dozzle (Visor de logs)..."
podman run -d --replace \
    --name dozzle-dev \
    --network dev-net \
    -p 8888:8080 \
    -v "/run/user/$USER_UID/podman/podman.sock:/var/run/docker.sock:ro" \
    docker.io/amir20/dozzle:latest

echo "✅ Dozzle iniciado en http://localhost:8888"
