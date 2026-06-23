#!/bin/bash
# podman-prometheus.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network
ensure_data_dir "$PROMETHEUS_DATA_DIR"

echo "ℹ️ Iniciando Prometheus..."
podman run -d --replace \
    --name prometheus-dev \
    --network "$PODMAN_NETWORK" \
    -v "$PROMETHEUS_DATA_DIR:/prometheus:Z" \
    -p 9090:9090 \
    docker.io/prom/prometheus:latest
echo "✅ Prometheus iniciado en http://localhost:9090"
