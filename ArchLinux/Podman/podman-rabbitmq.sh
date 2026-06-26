#!/bin/bash
# podman-rabbitmq.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando RabbitMQ..."
podman run -d --replace \
    --name rabbitmq-dev \
    --network devfed-net \
    -p 5672:5672 \
    -p 15672:15672 \
    -e RABBITMQ_DEFAULT_USER=guest \
    -e RABBITMQ_DEFAULT_PASS=guest \
    docker.io/library/rabbitmq:3-management
echo "✅ RabbitMQ iniciado (AMQP:5672, Management:15672)"
