#!/bin/bash
# =============================================================================
# CONFIGURACIÓN COMÚN PARA PODMAN (podman-common.sh)
# =============================================================================
# Este archivo centraliza la configuración de red y volúmenes para los
# scripts de contenedores Podman. Debe ser sourced por los demás scripts.
# =============================================================================

# Nombre de la red Podman (configurable)
PODMAN_NETWORK="${PODMAN_NETWORK:-podman-dev}"

# Directorio base para volúmenes persistentes
PODMAN_DATA_DIR="${PODMAN_DATA_DIR:-$HOME/.local/share/podman-data}"

# Función para asegurar que la red existe
ensure_podman_network() {
    if ! podman network exists "$PODMAN_NETWORK" 2>/dev/null; then
        echo "ℹ️ Creando red Podman: $PODMAN_NETWORK"
        podman network create "$PODMAN_NETWORK"
    fi
}

# Función para crear directorio de datos si no existe
ensure_data_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

# Volúmenes comunes para persistencia
# PostgreSQL
POSTGRES_DATA_DIR="$PODMAN_DATA_DIR/postgres"

# MySQL
MYSQL_DATA_DIR="$PODMAN_DATA_DIR/mysql"

# MongoDB
MONGO_DATA_DIR="$PODMAN_DATA_DIR/mongodb"

# Redis
REDIS_DATA_DIR="$PODMAN_DATA_DIR/redis"

# MinIO
MINIO_DATA_DIR="$PODMAN_DATA_DIR/minio"

# Grafana
GRAFANA_DATA_DIR="$PODMAN_DATA_DIR/grafana"

# Prometheus
PROMETHEUS_DATA_DIR="$PODMAN_DATA_DIR/prometheus"
