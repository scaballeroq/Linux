#!/bin/bash
# =============================================================================
# docker-utils - CLI para gestionar proyectos y servicios Docker (Omarchy)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$DOCKER_DIR/templates"
PROJECTS_DIR="$DOCKER_DIR/projects"
SHARED_DIR="$DOCKER_DIR/services-shared"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }

get_compose_cmd() {
    if docker compose version &>/dev/null; then
        echo "docker compose"
    elif command -v docker-compose &>/dev/null; then
        echo "docker-compose"
    else
        log_error "Docker Compose no está instalado."
        exit 1
    fi
}

COMPOSE="$(get_compose_cmd)"

ensure_docker_running() {
    if ! docker info &>/dev/null; then
        if sudo docker info &>/dev/null; then
            log_info "El socket de Docker requiere permisos. Te sugerimos ejecutar: newgrp docker"
        else
            log_error "El servicio de Docker no está activo. Inícialo con: sudo systemctl start docker"
            exit 1
        fi
    fi
}

# =============================================================================
# CREATE
# =============================================================================
cmd_create() {
    local template="${1:-}"
    local project="${2:-}"

    if [ -z "$template" ] || [ -z "$project" ]; then
        echo "Uso: docker-utils create <template> <nombre-proyecto>"
        echo ""
        echo "Templates disponibles:"
        cmd_list_templates
        exit 1
    fi

    local template_dir="$TEMPLATES_DIR/$template"
    if [ ! -d "$template_dir" ]; then
        log_error "Template '$template' no existe"
        echo ""
        cmd_list_templates
        exit 1
    fi

    local project_dir="$PROJECTS_DIR/$project"
    if [ -d "$project_dir" ]; then
        log_error "El proyecto '$project' ya existe en $project_dir"
        exit 1
    fi

    log_step "Creando proyecto '$project' desde template '$template'..."

    mkdir -p "$project_dir"

    local project_upper
    project_upper=$(echo "$project" | tr '[:lower:]-' '[:upper:]_')

    cp -r "$template_dir"/* "$project_dir"/
    if [ -f "$template_dir/.env.example" ]; then
        cp "$template_dir/.env.example" "$project_dir/.env"
    fi

    # Reemplazar placeholders
    find "$project_dir" -type f \( -name "docker-compose.yml" -o -name "compose.yaml" -o -name ".env*" -o -name "*.py" -o -name "*.json" -o -name "*.md" \) | while read -r file; do
        sed -i "s/__PROJECT__/$project/g" "$file"
        sed -i "s/__PROJECT_UPPER__/$project_upper/g" "$file"
        sed -i "s|__PROJECT_DIR__|$project_dir|g" "$file"
    done

    # Asegurar red global si el template la requiere
    if grep -q "proxy-net" "$project_dir/docker-compose.yml" 2>/dev/null; then
        docker network inspect proxy-net &>/dev/null || docker network create proxy-net >/dev/null 2>&1 || true
    fi

    echo ""
    log_ok "Proyecto '$project' creado exitosamente en: $project_dir"
    echo ""
    echo "Siguientes pasos:"
    echo "  1. Configura variables:  nano $project_dir/.env"
    echo "  2. Inicia el proyecto:   docker-utils start $project"
    echo "  3. Ver logs:             docker-utils logs $project"
    echo "  4. Monitorizar:          docker-utils lazy $project"
    echo ""
}

# =============================================================================
# START / STOP / RESTART / DOWN
# =============================================================================
cmd_start() {
    local project="${1:-}"
    shift || true
    [ -z "$project" ] && { log_error "Uso: docker-utils start <proyecto> [--build]"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    [ ! -d "$project_dir" ] && { log_error "Proyecto '$project' no existe en $PROJECTS_DIR"; exit 1; }

    local compose_file="$project_dir/docker-compose.yml"
    [ ! -f "$compose_file" ] && [ -f "$project_dir/compose.yaml" ] && compose_file="$project_dir/compose.yaml"

    ensure_docker_running
    log_step "Iniciando proyecto '$project'..."
    (cd "$project_dir" && $COMPOSE -p "$project" up -d "$@")

    log_ok "Proyecto '$project' iniciado"
    echo ""
    cmd_status "$project"
}

cmd_stop() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: docker-utils stop <proyecto>"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    [ ! -d "$project_dir" ] && { log_error "Proyecto '$project' no existe en $PROJECTS_DIR"; exit 1; }

    ensure_docker_running
    log_step "Deteniendo contenedores de '$project'..."
    (cd "$project_dir" && $COMPOSE -p "$project" stop)
    log_ok "Proyecto '$project' detenido"
}

cmd_down() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: docker-utils down <proyecto>"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    [ ! -d "$project_dir" ] && { log_error "Proyecto '$project' no existe en $PROJECTS_DIR"; exit 1; }

    ensure_docker_running
    log_step "Bajando contenedores y redes de '$project'..."
    (cd "$project_dir" && $COMPOSE -p "$project" down)
    log_ok "Proyecto '$project' bajado"
}

cmd_restart() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: docker-utils restart <proyecto>"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    [ ! -d "$project_dir" ] && { log_error "Proyecto '$project' no existe en $PROJECTS_DIR"; exit 1; }

    ensure_docker_running
    log_step "Reiniciando proyecto '$project'..."
    (cd "$project_dir" && $COMPOSE -p "$project" restart)
    log_ok "Proyecto '$project' reiniciado"
    cmd_status "$project"
}

# =============================================================================
# LOGS / STATUS / EXEC
# =============================================================================
cmd_logs() {
    local project="${1:-}"
    local service="${2:-}"
    [ -z "$project" ] && { log_error "Uso: docker-utils logs <proyecto> [servicio]"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    [ ! -d "$project_dir" ] && { log_error "Proyecto '$project' no existe"; exit 1; }

    ensure_docker_running
    if [ -n "$service" ]; then
        (cd "$project_dir" && $COMPOSE -p "$project" logs -f "$service")
    else
        (cd "$project_dir" && $COMPOSE -p "$project" logs -f)
    fi
}

cmd_status() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: docker-utils status <proyecto>"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    [ ! -d "$project_dir" ] && { log_error "Proyecto '$project' no existe"; exit 1; }

    ensure_docker_running
    echo "=== Estado del Proyecto: $project ==="
    (cd "$project_dir" && $COMPOSE -p "$project" ps)
}

cmd_exec() {
    local project="${1:-}"
    local service="${2:-}"
    shift 2 || true
    [ -z "$project" ] || [ -z "$service" ] && { log_error "Uso: docker-utils exec <proyecto> <servicio> [comando]"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    [ ! -d "$project_dir" ] && { log_error "Proyecto '$project' no existe"; exit 1; }

    ensure_docker_running
    local cmd=("${@:-/bin/sh}")
    (cd "$project_dir" && $COMPOSE -p "$project" exec "$service" "${cmd[@]}")
}

# =============================================================================
# DESTROY
# =============================================================================
cmd_destroy() {
    local project="${1:-}"
    local force="${2:-}"
    [ -z "$project" ] && { log_error "Uso: docker-utils destroy <proyecto> [-y]"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    if [ ! -d "$project_dir" ]; then
        log_error "Proyecto '$project' no existe en $PROJECTS_DIR"
        exit 1
    fi

    if [[ "$force" != "-y" && "$force" != "--yes" && "$force" != "-f" && "$force" != "--force" ]]; then
        echo -n "¿Estás seguro de que deseas eliminar '$project' y todos sus volúmenes y datos? [s/N]: "
        read -r confirm
        if [[ ! "$confirm" =~ ^[sSyY]$ ]]; then
            log_info "Operación cancelada."
            return 0
        fi
    fi

    (cd "$project_dir" && $COMPOSE -p "$project" down -v --remove-orphans 2>/dev/null || true)

    log_step "Eliminando directorio del proyecto..."
    rm -rf "$project_dir"

    log_ok "Proyecto '$project' eliminado completamente."
}

# =============================================================================
# SHARED / GLOBAL SERVICES
# =============================================================================
cmd_shared() {
    local action="${1:-status}"
    shift || true

    local compose_file="$SHARED_DIR/docker-compose.yml"
    if [ ! -f "$compose_file" ]; then
        log_error "No se encontró el archivo de servicios compartidos en $compose_file"
        exit 1
    fi

    if [ ! -f "$SHARED_DIR/.env" ] && [ -f "$SHARED_DIR/.env.example" ]; then
        cp "$SHARED_DIR/.env.example" "$SHARED_DIR/.env"
        log_ok "Archivo .env generado para servicios globales."
    fi

    ensure_docker_running

    case "$action" in
        up|start)
            log_step "Iniciando servicios globales compartidos..."
            docker network inspect proxy-net &>/dev/null || docker network create proxy-net >/dev/null 2>&1 || true
            (cd "$SHARED_DIR" && $COMPOSE -p "shared-services" up -d "$@")
            log_ok "Servicios globales iniciados."
            (cd "$SHARED_DIR" && $COMPOSE -p "shared-services" ps)
            ;;
        down|stop)
            log_step "Deteniendo servicios globales compartidos..."
            (cd "$SHARED_DIR" && $COMPOSE -p "shared-services" down "$@")
            log_ok "Servicios globales detenidos."
            ;;
        restart)
            log_step "Reiniciando servicios globales compartidos..."
            (cd "$SHARED_DIR" && $COMPOSE -p "shared-services" restart "$@")
            log_ok "Servicios globales reiniciados."
            ;;
        logs)
            (cd "$SHARED_DIR" && $COMPOSE -p "shared-services" logs -f "$@")
            ;;
        status|ps)
            echo "=== Servicios Globales Compartidos ==="
            (cd "$SHARED_DIR" && $COMPOSE -p "shared-services" ps)
            ;;
        *)
            echo "Uso: docker-utils shared <up|down|restart|logs|status> [servicio]"
            ;;
    esac
}

# =============================================================================
# LAZYDOCKER UI
# =============================================================================
cmd_lazy() {
    local project="${1:-}"

    if ! command -v lazydocker &>/dev/null; then
        log_error "lazydocker no está instalado. Instálalo con: sudo pacman -S lazydocker"
        exit 1
    fi

    if [ -n "$project" ]; then
        local project_dir="$PROJECTS_DIR/$project"
        if [ -d "$project_dir" ]; then
            cd "$project_dir" && lazydocker
            return 0
        elif [ "$project" = "shared" ] || [ "$project" = "global" ]; then
            cd "$SHARED_DIR" && lazydocker
            return 0
        else
            log_error "Proyecto '$project' no encontrado en $PROJECTS_DIR"
            exit 1
        fi
    fi

    lazydocker
}

# =============================================================================
# LIST
# =============================================================================
cmd_list() {
    echo "=== Proyectos Docker ==="
    echo ""

    if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A "$PROJECTS_DIR" 2>/dev/null | grep -v '\.gitkeep')" ]; then
        echo "  (ningún proyecto creado aún)"
        echo ""
        echo "Para crear uno, ejecuta: docker-utils create <template> <nombre>"
        return 0
    fi

    for dir in "$PROJECTS_DIR"/*/; do
        [ -d "$dir" ] || continue
        local name
        name="$(basename "$dir")"
        [ "$name" = ".gitkeep" ] && continue

        local running_containers
        running_containers=$( (docker ps --filter "label=com.docker.compose.project=$name" --format "{{.Names}}" 2>/dev/null || true) | tr '\n' ', ' | sed 's/,$//')

        if [ -n "$running_containers" ]; then
            printf "  ${GREEN}%-20s${NC} ${GREEN}[activo]${NC}   %s\n" "$name" "$running_containers"
        else
            printf "  ${YELLOW}%-20s${NC} ${RED}[detenido]${NC}\n" "$name"
        fi
    done
    echo ""
}

cmd_list_templates() {
    echo "Templates disponibles:"
    echo ""

    if [ -d "$TEMPLATES_DIR" ]; then
        for dir in "$TEMPLATES_DIR"/*/; do
            [ -d "$dir" ] || continue
            local name
            name="$(basename "$dir")"
            local desc=""

            case "$name" in
                python-postgres)       desc="FastAPI + PostgreSQL (con hot reload)" ;;
                python-postgres-redis) desc="FastAPI + PostgreSQL + Redis (con hot reload)" ;;
                fullstack)             desc="Frontend Node.js + FastAPI + PostgreSQL + Keycloak + Traefik" ;;
                *)                     desc="Plantilla personalizada" ;;
            esac

            printf "  ${CYAN}%-25s${NC} %s\n" "$name" "$desc"
        done
    fi
    echo ""
}

# =============================================================================
# USAGE
# =============================================================================
usage() {
    echo "======================================================================"
    echo "  docker-utils - Gestor de Entornos Docker para Omarchy"
    echo "======================================================================"
    echo ""
    echo "Uso: docker-utils <comando> [argumentos]"
    echo ""
    echo "Gestión de Proyectos:"
    echo "  create <template> <nombre>      Crear un nuevo proyecto desde plantilla"
    echo "  start <nombre> [--build]        Iniciar contenedores del proyecto"
    echo "  stop <nombre>                   Detener contenedores del proyecto"
    echo "  down <nombre>                   Bajar contenedores y redes del proyecto"
    echo "  restart <nombre>                Reiniciar proyecto"
    echo "  logs <nombre> [servicio]        Ver logs en tiempo real"
    echo "  status <nombre>                 Ver estado de contenedores (ps)"
    echo "  exec <nombre> <servicio> [cmd]  Ejecutar comando/shell en un contenedor"
    echo "  destroy <nombre>                Eliminar proyecto y sus datos"
    echo ""
    echo "Servicios Compartidos / Globales:"
    echo "  shared <up|down|restart|logs|ps> Administrar Traefik, Keycloak, Postgres, Redis globales"
    echo ""
    echo "Interfaz Gráfica / Monitorización:"
    echo "  lazy [nombre|shared]            Abrir Lazydocker (en el contexto del proyecto)"
    echo ""
    echo "Información:"
    echo "  list                            Listar todos los proyectos locales"
    echo "  list-templates                  Listar plantillas disponibles"
    echo "  help                            Mostrar esta ayuda"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================
case "${1:-}" in
    create)           shift; cmd_create "$@" ;;
    start|up)         shift; cmd_start "$@" ;;
    stop)             shift; cmd_stop "$@" ;;
    down)             shift; cmd_down "$@" ;;
    restart)          shift; cmd_restart "$@" ;;
    logs)             shift; cmd_logs "$@" ;;
    status|ps)        shift; cmd_status "$@" ;;
    exec)             shift; cmd_exec "$@" ;;
    destroy)          shift; cmd_destroy "$@" ;;
    shared|global)    shift; cmd_shared "$@" ;;
    lazy|lzd)         shift; cmd_lazy "$@" ;;
    list)             cmd_list ;;
    list-templates)   cmd_list_templates ;;
    help|--help|-h)   usage ;;
    *)                usage; exit 1 ;;
esac
