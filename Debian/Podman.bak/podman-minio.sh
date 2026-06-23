#!/bin/bash
# podman-minio.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network
ensure_data_dir "$MINIO_DATA_DIR"

echo "ℹ️ Iniciando MinIO (S3 Compatible)..."
podman run -d --replace \
    --name minio-dev \
    --network "$PODMAN_NETWORK" \
    -v "$MINIO_DATA_DIR:/data:Z" \
    -p 9000:9000 -p 9001:9001 \
    docker.io/minio/minio server /data --console-address ":9001"
echo "✅ MinIO iniciado (API: 9000, UI: http://localhost:9001)"
