#!/bin/bash
# podman-grafana.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Grafana..."
podman run -d --replace \
    --name grafana-dev \
    --network devfed-net \
    -p 3000:3000 \
    docker.io/grafana/grafana:latest
echo "✅ Grafana iniciado en http://localhost:3000"
