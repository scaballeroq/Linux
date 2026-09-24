#!/bin/bash
# podman-storybook.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v podman &>/dev/null; then
    echo "❌ Error: Podman no está instalado en el sistema."
    echo "💡 Puedes instalarlo y configurarlo ejecutando: $SCRIPT_DIR/../install/podman-install.sh"
    exit 1
fi

NETWORK="dev-net"
if podman network exists devfed-net 2>/dev/null; then
    NETWORK="devfed-net"
elif ! podman network exists "$NETWORK" 2>/dev/null; then
    podman network create "$NETWORK"
fi

echo "ℹ️ Iniciando Storybook (Standalone Demo)..."
podman run -d --replace \
    --name storybook-dev \
    --network "$NETWORK" \
    -p 6006:6006 \
    docker.io/storybooks/storybook:latest
echo "✅ Storybook (Demo) iniciado en http://localhost:6006"
