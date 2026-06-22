#!/bin/bash
# podman-keycloak.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

KC_ADMIN="${KC_ADMIN:-admin}"
KC_ADMIN_PASSWORD="${KC_ADMIN_PASSWORD:-admin}"

ensure_podman_network

echo "ℹ️ Iniciando Keycloak..."
podman run -d --replace \
    --name keycloak-dev \
    --network "$PODMAN_NETWORK" \
    -e KEYCLOAK_ADMIN="$KC_ADMIN" \
    -e KEYCLOAK_ADMIN_PASSWORD="$KC_ADMIN_PASSWORD" \
    -p 8083:8080 \
    quay.io/keycloak/keycloak:latest start-dev
echo "✅ Keycloak iniciado en http://localhost:8083"
