#!/bin/bash
# podman-postgres.sh

set -e

if ! podman network exists dev-net; then podman network create dev-net; fi

echo "ℹ️ Iniciando PostgreSQL (latest)..."
podman run -d --replace \
    --name postgres-dev \
    --network dev-net \
    -e POSTGRES_PASSWORD=postgres \
    -p 5432:5432 \
    docker.io/library/postgres:latest
echo "✅ PostgreSQL iniciado en puerto 5432 (user: postgres, pass: postgres)"
