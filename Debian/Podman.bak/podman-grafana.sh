#!/bin/bash
# podman-grafana.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network
ensure_data_dir "$GRAFANA_DATA_DIR"

echo "ℹ️ Iniciando Grafana..."
podman run -d --replace \
    --name grafana-dev \
    --network "$PODMAN_NETWORK" \
    -v "$GRAFANA_DATA_DIR:/var/lib/grafana:Z" \
    -p 3000:3000 \
    docker.io/grafana/grafana:latest
echo "✅ Grafana iniciado en http://localhost:3000"
