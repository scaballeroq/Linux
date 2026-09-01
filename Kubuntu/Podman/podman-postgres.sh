#!/bin/bash
# podman-postgres.sh - PostgreSQL Database

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando PostgreSQL (latest)..."
podman run -d --replace \
    --name postgres-dev \
    --network dev-net \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_DB=devdb \
    -v postgres-dev-data:/var/lib/postgresql/data \
    -p 5432:5432 \
    docker.io/library/postgres:latest

echo "✅ PostgreSQL iniciado en puerto 5432 (user: postgres, pass: postgres, db: devdb)"
