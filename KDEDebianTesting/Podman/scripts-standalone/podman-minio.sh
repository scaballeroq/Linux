#!/bin/bash
# podman-minio.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v podman &>/dev/null; then
    echo "❌ Error: Podman no está instalado en el sistema."
    echo "💡 Puedes instalarlo y configurarlo ejecutando: $SCRIPT_DIR/../install/podman-install.sh"
    exit 1
fi

NETWORK="dev-net"
if ! podman network exists "$NETWORK" 2>/dev/null; then
    podman network create "$NETWORK"
fi

echo "ℹ️ Iniciando MinIO (S3 Compatible) con volumen persistente..."
podman run -d --replace \
    --name minio-dev \
    --network "$NETWORK" \
    -v minio-standalone-data:/data \
    -p 9000:9000 -p 9001:9001 \
    docker.io/minio/minio server /data --console-address ":9001"
echo "✅ MinIO iniciado (API: 9000, UI: http://localhost:9001, volume: minio-standalone-data)"
