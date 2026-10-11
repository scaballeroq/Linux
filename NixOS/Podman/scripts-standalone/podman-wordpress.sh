#!/bin/bash
# podman-wordpress.sh

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

echo "ℹ️ Iniciando WordPress..."
podman run -d --replace \
    --name wordpress-dev \
    --network "$NETWORK" \
    -e WORDPRESS_DB_HOST=mysql-dev:3306 \
    -e WORDPRESS_DB_USER=root \
    -e WORDPRESS_DB_PASSWORD=root \
    -p 8080:80 \
    docker.io/library/wordpress:latest
echo "✅ WordPress iniciado en http://localhost:8080"
