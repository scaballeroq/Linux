#!/bin/bash
# podman-postgres.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando PostgreSQL..."
podman run -d --replace \
    --name postgres-dev \
    --network devfed-net \
    -p 5432:5432 \
    -e POSTGRES_PASSWORD=postgres \
    -v pgdata_dev:/var/lib/postgresql/data \
    docker.io/library/postgres:latest
echo "✅ PostgreSQL iniciado en puerto 5432"
