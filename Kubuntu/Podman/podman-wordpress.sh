#!/bin/bash
# podman-wordpress.sh - WordPress CMS + MySQL

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando base de datos MySQL para WordPress..."
podman run -d --replace \
    --name wp-mysql-dev \
    --network dev-net \
    -e MYSQL_ROOT_PASSWORD=wordpress \
    -e MYSQL_DATABASE=wordpress \
    -e MYSQL_USER=wordpress \
    -e MYSQL_PASSWORD=wordpress \
    -v wp-mysql-data:/var/lib/mysql \
    docker.io/library/mysql:latest

echo "ℹ️ Iniciando WordPress..."
podman run -d --replace \
    --name wp-dev \
    --network dev-net \
    -p 8085:80 \
    -e WORDPRESS_DB_HOST=wp-mysql-dev:3306 \
    -e WORDPRESS_DB_USER=wordpress \
    -e WORDPRESS_DB_PASSWORD=wordpress \
    -e WORDPRESS_DB_NAME=wordpress \
    -v wp-data:/var/www/html \
    docker.io/library/wordpress:latest

echo "✅ WordPress iniciado en http://localhost:8085 (DB: MySQL en red dev-net)"
