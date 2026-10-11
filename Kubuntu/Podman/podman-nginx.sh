#!/bin/bash
# podman-nginx.sh - Nginx Web Server

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando Nginx..."
podman run -d --replace \
    --name nginx-dev \
    --network dev-net \
    -p 8080:80 \
    docker.io/library/nginx:latest

echo "✅ Nginx iniciado en http://localhost:8080"
