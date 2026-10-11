#!/bin/bash
# podman-minio.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando MinIO (S3-compatible)..."
podman run -d --replace \
    --name minio-dev \
    --network devfed-net \
    -p 9000:9000 \
    -p 9001:9001 \
    -e MINIO_ROOT_USER=minioadmin \
    -e MINIO_ROOT_PASSWORD=minioadmin \
    docker.io/minio/minio:latest server /data --console-address ":9001"
echo "✅ MinIO iniciado (API:9000, Console:9001)"
