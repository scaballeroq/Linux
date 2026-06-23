#!/bin/bash
# podman-nginx.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network

echo "ℹ️ Iniciando Nginx..."
podman run -d --replace \
    --name nginx-dev \
    --network "$PODMAN_NETWORK" \
    -p 8082:80 \
    docker.io/library/nginx:latest
echo "✅ Nginx iniciado en http://localhost:8082"
