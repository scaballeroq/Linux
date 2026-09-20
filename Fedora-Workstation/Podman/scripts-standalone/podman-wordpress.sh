#!/bin/bash
# podman-wordpress.sh

set -e

if ! podman network exists devfed-net; then podman network create devfed-net; fi

echo "ℹ️ Iniciando WordPress..."
podman run -d --replace \
    --name wordpress-dev \
    --network devfed-net \
    -e WORDPRESS_DB_HOST=mysql-dev:3306 \
    -e WORDPRESS_DB_USER=root \
    -e WORDPRESS_DB_PASSWORD=root \
    -p 8080:80 \
    docker.io/library/wordpress:latest
echo "✅ WordPress iniciado en http://localhost:8080"
