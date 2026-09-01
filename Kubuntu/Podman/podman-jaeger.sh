#!/bin/bash
# podman-jaeger.sh - Distributed Tracing

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando Jaeger (All-in-One)..."
podman run -d --replace \
    --name jaeger-dev \
    --network dev-net \
    -p 16686:16686 \
    -p 4317:4317 \
    -p 4318:4318 \
    docker.io/jaegertracing/all-in-one:latest

echo "✅ Jaeger iniciado en http://localhost:16686 (OTLP gRPC: 4317, HTTP: 4318)"
