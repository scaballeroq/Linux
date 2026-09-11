#!/bin/bash
# podman-prometheus.sh

set -e

if ! podman network exists dev-net; then podman network create dev-net; fi

echo "ℹ️ Iniciando Prometheus..."
podman run -d --replace \
    --name prometheus-dev \
    --network dev-net \
    -p 9090:9090 \
    docker.io/prom/prometheus:latest
echo "✅ Prometheus iniciado en http://localhost:9090"
