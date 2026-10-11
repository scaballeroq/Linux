#!/bin/bash
# podman-mysql.sh

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

echo "ℹ️ Iniciando MySQL (latest)..."
podman run -d --replace \
    --name mysql-dev \
    --network "$NETWORK" \
    -e MYSQL_ROOT_PASSWORD=root \
    -p 3306:3306 \
    docker.io/library/mysql:latest
echo "✅ MySQL iniciado en puerto 3306 (user: root, pass: root)"
