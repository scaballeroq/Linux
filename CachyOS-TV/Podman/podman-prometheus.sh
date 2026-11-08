#!/bin/bash
# podman-prometheus.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Prometheus..."
podman run -d --replace \
    --name prometheus-dev \
    --network devfed-net \
    -p 9090:9090 \
    docker.io/prom/prometheus:latest
echo "✅ Prometheus iniciado en http://localhost:9090"
