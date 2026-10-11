#!/bin/bash
# podman-mysql.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando MySQL..."
podman run -d --replace \
    --name mysql-dev \
    --network devfed-net \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=root \
    -v mysql_data:/var/lib/mysql \
    docker.io/library/mysql:latest
echo "✅ MySQL iniciado en puerto 3306 (root/root)"
