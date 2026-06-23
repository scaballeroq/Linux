#!/bin/bash
# podman-storybook.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network

echo "ℹ️ Iniciando Storybook (Standalone Demo)..."
podman run -d --replace \
    --name storybook-dev \
    --network "$PODMAN_NETWORK" \
    -p 6006:6006 \
    docker.io/storybooks/storybook:latest
echo "✅ Storybook (Demo) iniciado en http://localhost:6006"
