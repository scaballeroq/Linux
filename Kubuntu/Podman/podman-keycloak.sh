#!/bin/bash
# podman-keycloak.sh - Identity & Access Management

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando Keycloak..."
podman run -d --replace \
    --name keycloak-dev \
    --network dev-net \
    -p 8083:8080 \
    -e KEYCLOAK_ADMIN=admin \
    -e KEYCLOAK_ADMIN_PASSWORD=admin \
    quay.io/keycloak/keycloak:latest \
    start-dev

echo "✅ Keycloak iniciado en http://localhost:8083 (user: admin, pass: admin)"
