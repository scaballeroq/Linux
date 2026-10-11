#!/bin/bash
# podman-prometheus.sh - Prometheus Monitoring

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando Prometheus..."
podman run -d --replace \
    --name prometheus-dev \
    --network dev-net \
    -p 9090:9090 \
    docker.io/prom/prometheus:latest

echo "✅ Prometheus iniciado en http://localhost:9090"
