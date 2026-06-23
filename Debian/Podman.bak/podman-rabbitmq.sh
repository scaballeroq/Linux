#!/bin/bash
# podman-rabbitmq.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network

echo "ℹ️ Iniciando RabbitMQ (Management)..."
podman run -d --replace \
    --name rabbitmq-dev \
    --network "$PODMAN_NETWORK" \
    -p 5672:5672 -p 15672:15672 \
    docker.io/library/rabbitmq:3-management
echo "✅ RabbitMQ iniciado (AMQP: 5672, UI: http://localhost:15672)"
