#!/bin/bash
# podman-mysql.sh - MySQL Database

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando MySQL..."
podman run -d --replace \
    --name mysql-dev \
    --network dev-net \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=root \
    -e MYSQL_DATABASE=devdb \
    docker.io/library/mysql:latest

echo "✅ MySQL iniciado en puerto 3306 (user: root, pass: root, db: devdb)"
