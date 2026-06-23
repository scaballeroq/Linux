#!/bin/bash
# podman-jaeger.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network

echo "ℹ️ Iniciando Jaeger (Tracing)..."
podman run -d --replace \
    --name jaeger-dev \
    --network "$PODMAN_NETWORK" \
    -p 16686:16686 -p 6831:6831/udp -p 6832:6832/udp \
    -p 5778:5778 -p 14268:14268 -p 14250:14250 -p 9411:9411 \
    docker.io/jaegertracing/all-in-one:latest
echo "✅ Jaeger iniciado (UI: http://localhost:16686)"
