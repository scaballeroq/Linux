#!/bin/bash
# podman-jaeger.sh

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

echo "ℹ️ Iniciando Jaeger (Tracing)..."
podman run -d --replace \
    --name jaeger-dev \
    --network "$NETWORK" \
    -p 16686:16686 -p 6831:6831/udp -p 6832:6832/udp \
    -p 5778:5778 -p 14268:14268 -p 14250:14250 -p 9411:9411 \
    docker.io/jaegertracing/all-in-one:latest
echo "✅ Jaeger iniciado (UI: http://localhost:16686)"
