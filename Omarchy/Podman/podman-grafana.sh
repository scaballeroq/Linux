#!/bin/bash
# podman-grafana.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Grafana..."
podman run -d --replace \
    --name grafana-dev \
    --network devfed-net \
    -p 3000:3000 \
    -e "GF_SECURITY_ADMIN_PASSWORD=admin" \
    docker.io/library/grafana/grafana:latest
echo "✅ Grafana iniciado en puerto 3000"
