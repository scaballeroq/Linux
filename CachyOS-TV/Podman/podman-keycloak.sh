#!/bin/bash
# podman-keycloak.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Keycloak..."
podman run -d --replace \
    --name keycloak-dev \
    --network devfed-net \
    -e KEYCLOAK_ADMIN=admin \
    -e KEYCLOAK_ADMIN_PASSWORD=admin \
    -p 8083:8080 \
    quay.io/keycloak/keycloak:latest start-dev
echo "✅ Keycloak iniciado en http://localhost:8083 (user: admin, pass: admin)"
