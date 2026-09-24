#!/bin/bash
# podman-rabbitmq.sh

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

echo "ℹ️ Iniciando RabbitMQ (Management)..."
podman run -d --replace \
    --name rabbitmq-dev \
    --network "$NETWORK" \
    -p 5672:5672 -p 15672:15672 \
    docker.io/library/rabbitmq:3-management
echo "✅ RabbitMQ iniciado (AMQP: 5672, UI: http://localhost:15672)"
