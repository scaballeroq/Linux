#!/bin/bash
# podman-nginx.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Nginx..."
podman run -d --replace \
    --name nginx-dev \
    --network devfed-net \
    -p 8082:80 \
    docker.io/library/nginx:latest
echo "✅ Nginx iniciado en http://localhost:8082"
