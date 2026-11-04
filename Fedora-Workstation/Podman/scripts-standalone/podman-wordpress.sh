#!/bin/bash
# podman-wordpress.sh - WordPress Standalone en Podman Rootless

set -euo pipefail

CONTAINER_NAME="wordpress-dev"
NETWORK_NAME="devfed-net"
PORT="8080:80"
IMAGE="docker.io/library/wordpress:latest"
VOLUME_NAME="devfed-wordpress-data"

ensure_network() {
    if ! podman network exists "$NETWORK_NAME" 2>/dev/null; then
        podman network create "$NETWORK_NAME" >/dev/null
    fi
}

check_mysql() {
    if ! podman ps --filter "name=^/mysql-dev$" --format "{{.Names}}" 2>/dev/null | grep -q "mysql-dev"; then
        echo "⚠️ Advertencia: El contenedor 'mysql-dev' no parece estar corriendo en la red '$NETWORK_NAME'."
        echo "   Puedes iniciarlo primero con: ./Podman/scripts-standalone/podman-mysql.sh"
    fi
}

show_status() {
    echo "================================================================="
    echo "📊 ESTADO DE $CONTAINER_NAME"
    echo "================================================================="
    if podman container exists "$CONTAINER_NAME" 2>/dev/null; then
        podman ps -a --filter "name=^/${CONTAINER_NAME}$" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "Contenedor '$CONTAINER_NAME' no existe."
    fi
    echo "================================================================="
}

stop_container() {
    echo "🛑 Deteniendo $CONTAINER_NAME..."
    podman stop "$CONTAINER_NAME" 2>/dev/null || true
    podman rm "$CONTAINER_NAME" 2>/dev/null || true
    echo "✅ $CONTAINER_NAME detenido y removido."
}

show_logs() {
    podman logs -f "$CONTAINER_NAME"
}

start_container() {
    ensure_network
    check_mysql
    echo "ℹ️ Iniciando WordPress..."
    podman run -d --replace \
        --name "$CONTAINER_NAME" \
        --network "$NETWORK_NAME" \
        -v "$VOLUME_NAME:/var/www/html:Z" \
        -e WORDPRESS_DB_HOST=mysql-dev:3306 \
        -e WORDPRESS_DB_USER=root \
        -e WORDPRESS_DB_PASSWORD=root \
        -p "$PORT" \
        "$IMAGE"
    echo "✅ WordPress iniciado en http://localhost:8080 (volumen: $VOLUME_NAME)"
}

case "${1:-}" in
    --status|-s|status) show_status ;;
    --stop|stop)        stop_container ;;
    --logs|-l|logs)     show_logs ;;
    --help|-h|help)
        echo "Uso: $0 [--status | --stop | --logs | --help]"
        ;;
    "") start_container ;;
    *)
        echo "Opción no reconocida: $1"
        echo "Uso: $0 [--status | --stop | --logs | --help]"
        exit 1
        ;;
esac
