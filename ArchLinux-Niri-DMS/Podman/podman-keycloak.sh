#!/bin/bash
# podman-keycloak.sh

set -e

if ! podman network exists dev-net; then podman network create dev-net; fi

echo "ℹ️ Iniciando Keycloak..."
podman run -d --replace \
    --name keycloak-dev \
    --network dev-net \
    -e KEYCLOAK_ADMIN=admin \
    -e KEYCLOAK_ADMIN_PASSWORD=admin \
    -p 8083:8080 \
    quay.io/keycloak/keycloak:latest start-dev
echo "✅ Keycloak iniciado en http://localhost:8083 (user: admin, pass: admin)"
