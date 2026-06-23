#!/bin/bash
# podman-mysql.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"

ensure_podman_network
ensure_data_dir "$MYSQL_DATA_DIR"

echo "ℹ️ Iniciando MySQL (latest)..."
podman run -d --replace \
    --name mysql-dev \
    --network "$PODMAN_NETWORK" \
    -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    -v "$MYSQL_DATA_DIR:/var/lib/mysql:Z" \
    -p 3306:3306 \
    docker.io/library/mysql:latest
echo "✅ MySQL iniciado en puerto 3306 (user: root)"
