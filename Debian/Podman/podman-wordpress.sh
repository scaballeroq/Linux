#!/bin/bash
# podman-wordpress.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

WP_DB_PASSWORD="${WP_DB_PASSWORD:-${MYSQL_ROOT_PASSWORD:-root}}"

ensure_podman_network

echo "ℹ️ Iniciando WordPress..."
podman run -d --replace \
    --name wordpress-dev \
    --network "$PODMAN_NETWORK" \
    -e WORDPRESS_DB_HOST=mysql-dev:3306 \
    -e WORDPRESS_DB_USER=root \
    -e WORDPRESS_DB_PASSWORD="$WP_DB_PASSWORD" \
    -p 8080:80 \
    docker.io/library/wordpress:latest
echo "✅ WordPress iniciado en http://localhost:8080"
