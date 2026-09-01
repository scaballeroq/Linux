#!/bin/bash
# podman-rabbitmq.sh - RabbitMQ Message Broker

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando RabbitMQ con panel de gestión..."
podman run -d --replace \
    --name rabbitmq-dev \
    --network dev-net \
    -p 5672:5672 \
    -p 15672:15672 \
    docker.io/library/rabbitmq:3-management

echo "✅ RabbitMQ iniciado (AMQP: 5672, Management UI: http://localhost:15672, user: guest, pass: guest)"
