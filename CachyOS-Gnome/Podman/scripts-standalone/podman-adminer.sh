#!/bin/bash
# podman-adminer.sh - Adminer Standalone en Podman Rootless

set -euo pipefail

CONTAINER_NAME="adminer-dev"
NETWORK_NAME="devfed-net"
PORT="8081:8080"
IMAGE="docker.io/library/adminer:latest"

ensure_network() {
    if ! podman network exists "$NETWORK_NAME" 2>/dev/null; then
        podman network create "$NETWORK_NAME" >/dev/null
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
    echo "ℹ️ Iniciando Adminer..."
    podman run -d --replace \
        --name "$CONTAINER_NAME" \
        --network "$NETWORK_NAME" \
        -p "$PORT" \
        "$IMAGE"
    echo "✅ Adminer iniciado en http://localhost:8081 (DB Admin UI)"
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
