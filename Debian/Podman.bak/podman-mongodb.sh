#!/bin/bash
# podman-mongodb.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network
ensure_data_dir "$MONGO_DATA_DIR"

echo "ℹ️ Iniciando MongoDB (latest)..."
podman run -d --replace \
    --name mongo-dev \
    --network "$PODMAN_NETWORK" \
    -v "$MONGO_DATA_DIR:/data/db:Z" \
    -p 27017:27017 \
    docker.io/library/mongo:latest
echo "✅ MongoDB iniciado en puerto 27017"
