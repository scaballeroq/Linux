#!/bin/bash
# podman-keycloak.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando Keycloak (IAM)..."
podman run -d --replace \
    --name keycloak-dev \
    --network devfed-net \
    -p 8083:8080 \
    -e KEYCLOAK_ADMIN=admin \
    -e KEYCLOAK_ADMIN_PASSWORD=admin \
    docker.io/bitnami/keycloak:latest \
    /opt/bitnami/scripts/keycloak/entrypoint.sh /opt/bitnami/scripts/keycloak/run.sh
echo "✅ Keycloak iniciado en puerto 8083 (admin/admin)"
