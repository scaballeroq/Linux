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
if ! podman network exists "$NETWORK" 2>/dev/null; then
    podman network create "$NETWORK"
fi

echo "ℹ️ Iniciando MySQL 8.4 LTS con volumen persistente..."
podman run -d --replace \
    --name mysql-dev \
    --network "$NETWORK" \
    -e MYSQL_ROOT_PASSWORD=root \
    -v mysql-standalone-data:/var/lib/mysql \
    -p 3306:3306 \
    docker.io/library/mysql:8.4
echo "✅ MySQL iniciado en puerto 3306 (user: root, pass: root, volume: mysql-standalone-data)"
