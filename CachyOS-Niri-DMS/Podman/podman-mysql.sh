#!/bin/bash
# podman-mysql.sh

set -e

if ! podman network exists dev-net; then podman network create dev-net; fi

echo "ℹ️ Iniciando MySQL (latest)..."
podman run -d --replace \
    --name mysql-dev \
    --network dev-net \
    -e MYSQL_ROOT_PASSWORD=root \
    -p 3306:3306 \
    docker.io/library/mysql:latest
echo "✅ MySQL iniciado en puerto 3306 (user: root, pass: root)"
