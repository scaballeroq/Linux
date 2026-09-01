#!/bin/bash
# podman-grafana.sh - Grafana Dashboard

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando Grafana..."
podman run -d --replace \
    --name grafana-dev \
    --network dev-net \
    -p 3001:3000 \
    docker.io/grafana/grafana:latest

echo "✅ Grafana iniciado en http://localhost:3001 (user: admin, pass: admin)"
