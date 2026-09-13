#!/bin/bash
# podman-minio.sh

set -e

if ! podman network exists dev-net; then podman network create dev-net; fi

echo "ℹ️ Iniciando MinIO (S3 Compatible)..."
podman run -d --replace \
    --name minio-dev \
    --network dev-net \
    -p 9000:9000 -p 9001:9001 \
    docker.io/minio/minio server /data --console-address ":9001"
echo "✅ MinIO iniciado (API: 9000, UI: http://localhost:9001)"
