#!/bin/bash
# podman-keycloak.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v podman &>/dev/null; then
    echo "❌ Error: Podman no está instalado en el sistema."
    echo "💡 Puedes instalarlo y configurarlo ejecutando: $SCRIPT_DIR/../install/podman-install.sh"
    exit 1
fi

NETWORK="dev-net"
if podman network exists devfed-net 2>/dev/null; then
    NETWORK="devfed-net"
elif ! podman network exists "$NETWORK" 2>/dev/null; then
    podman network create "$NETWORK"
fi

echo "ℹ️ Iniciando Keycloak..."
podman run -d --replace \
    --name keycloak-dev \
    --network "$NETWORK" \
    -e KEYCLOAK_ADMIN=admin \
    -e KEYCLOAK_ADMIN_PASSWORD=admin \
    -p 8083:8080 \
    quay.io/keycloak/keycloak:latest start-dev
echo "✅ Keycloak iniciado en http://localhost:8083 (user: admin, pass: admin)"
