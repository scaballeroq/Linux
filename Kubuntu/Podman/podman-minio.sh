#!/bin/bash
# podman-minio.sh - S3 Compatible Object Storage

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando MinIO..."
podman run -d --replace \
    --name minio-dev \
    --network dev-net \
    -p 9000:9000 \
    -p 9001:9001 \
    -e MINIO_ROOT_USER=minioadmin \
    -e MINIO_ROOT_PASSWORD=minioadmin \
    docker.io/minio/minio:latest server /data --console-address ":9001"

echo "✅ MinIO iniciado (API: 9000, Consola: http://localhost:9001, user: minioadmin, pass: minioadmin)"
