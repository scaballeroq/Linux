#!/bin/bash
# =============================================================================
# podman-utils - CLI para gestionar proyectos Podman con Quadlets (Omarchy)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$PODMAN_DIR/templates"
PROJECTS_DIR="$PODMAN_DIR/projects"
SYSTEMD_DIR="$HOME/.config/containers/systemd"
SYSTEMD_GLOBAL="$SYSTEMD_DIR/global"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }

# =============================================================================
# CREATE
# =============================================================================
cmd_create() {
    local template="${1:-}"
    local project="${2:-}"

    if [ -z "$template" ] || [ -z "$project" ]; then
        echo "Uso: podman-utils create <template> <nombre-proyecto>"
        echo ""
        echo "Templates disponibles:"
        ls -1 "$TEMPLATES_DIR" 2>/dev/null | sed 's/^/  /' || echo "  (ninguno)"
        exit 1
    fi

    local template_dir="$TEMPLATES_DIR/$template"
    if [ ! -d "$template_dir" ]; then
        log_error "Template '$template' no existe"
        echo "Templates disponibles:"
        ls -1 "$TEMPLATES_DIR" 2>/dev/null | sed 's/^/  /'
        exit 1
    fi

    local project_dir="$PROJECTS_DIR/$project"
    if [ -d "$project_dir" ]; then
        log_error "El proyecto '$project' ya existe"
        exit 1
    fi

    log_step "Creando proyecto '$project' desde template '$template'..."

    mkdir -p "$project_dir"

    local project_upper
    project_upper=$(echo "$project" | tr '[:lower:]-' '[:upper:]_')
    local socket_path="/run/user/$(id -u)/podman/podman.sock"

    cp -r "$template_dir"/* "$project_dir"/
    if [ -f "$template_dir/.env.example" ]; then
        cp "$template_dir/.env.example" "$project_dir/.env"
    fi

    # Reemplazar placeholders en todos los archivos
    find "$project_dir" -type f \( -name "*.container" -o -name "*.network" -o -name "*.target" -o -name "*.volume" -o -name ".env*" -o -name "*.py" -o -name "*.json" \) | while read -r file; do
        sed -i "s/__PROJECT__/$project/g" "$file"
        sed -i "s/__PROJECT_UPPER__/$project_upper/g" "$file"
        sed -i "s|__PROJECT_DIR__|$project_dir|g" "$file"
        sed -i "s|__PODMAN_SOCKET__|$socket_path|g" "$file"
    done

    # Renombrar archivos con placeholder
    find "$project_dir" -name "*__PROJECT__*" | while read -r file; do
        mv "$file" "$(echo "$file" | sed "s/__PROJECT__/$project/g")"
    done

    # Crear symlinks en systemd
    link_project_to_systemd "$project"

    systemctl --user daemon-reload 2>/dev/null || true

    echo ""
    log_ok "Proyecto '$project' creado en: $project_dir"
    echo ""
    echo "Siguientes pasos:"
    echo "  1. Edita las credenciales: nano $project_dir/.env"
    echo "  2. Inicia el proyecto:     podman-utils start $project"
    echo "  3. Ver logs:               podman-utils logs $project"
    echo ""
}

# =============================================================================
# START / STOP / RESTART
# =============================================================================
cmd_start() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils start <proyecto>"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    [ ! -d "$project_dir" ] && { log_error "Proyecto '$project' no existe"; exit 1; }

    log_step "Iniciando proyecto '$project'..."
    systemctl --user daemon-reload
    systemctl --user start "${project}.target" 2>/dev/null || \
        systemctl --user start "$(ls "$SYSTEMD_DIR/${project}"*.service 2>/dev/null | head -1)" || \
        log_error "No se encontraron servicios para '$project'. Ejecuta: podman-utils link $project"

    log_ok "Proyecto '$project' iniciado"
    cmd_status "$project"
}

cmd_stop() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils stop <proyecto>"; exit 1; }

    log_step "Deteniendo proyecto '$project'..."
    systemctl --user stop "${project}.target" 2>/dev/null || \
        systemctl --user stop "$(ls "$SYSTEMD_DIR/${project}"*.service 2>/dev/null | xargs -r)" 2>/dev/null || true

    log_ok "Proyecto '$project' detenido"
}

cmd_restart() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils restart <proyecto>"; exit 1; }

    cmd_stop "$project"
    sleep 1
    cmd_start "$project"
}

# =============================================================================
# LOGS
# =============================================================================
cmd_logs() {
    local project="${1:-}"
    local service="${2:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils logs <proyecto> [servicio]"; exit 1; }

    if [ -n "$service" ]; then
        journalctl --user -u "${project}-${service}" -f --no-pager
    else
        journalctl --user -u "${project}*" -f --no-pager
    fi
}

# =============================================================================
# STATUS
# =============================================================================
cmd_status() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils status <proyecto>"; exit 1; }

    echo ""
    echo "=== Proyecto: $project ==="
    echo ""

    systemctl --user list-units "${project}*" --no-pager 2>/dev/null || \
        echo "  (sin servicios activos)"

    echo ""
    echo "Contenedores Podman:"
    podman ps --filter "name=$project" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
    echo ""
}

# =============================================================================
# DESTROY
# =============================================================================
cmd_destroy() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils destroy <proyecto>"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    if [ ! -d "$project_dir" ]; then
        log_error "Proyecto '$project' no existe"
        exit 1
    fi

    log_step "Deteniendo servicios..."
    cmd_stop "$project" 2>/dev/null || true

    log_step "Eliminando symlinks de systemd..."
    rm -f "$SYSTEMD_DIR/${project}"* 2>/dev/null || true

    log_step "Eliminando contenedores..."
    podman rm -f "$(podman ps -a --filter "name=$project" --format "{{.ID}}" 2>/dev/null)" 2>/dev/null || true

    log_step "Eliminando volumenes..."
    podman volume rm "$(podman volume ls --filter "name=$project" --format "{{.Name}}" 2>/dev/null)" 2>/dev/null || true

    log_step "Eliminando red..."
    podman network rm "$project" 2>/dev/null || true

    log_step "Eliminando directorio del proyecto..."
    rm -rf "$project_dir"

    systemctl --user daemon-reload 2>/dev/null || true

    log_ok "Proyecto '$project' eliminado completamente"
}

# =============================================================================
# LINK / UNLINK
# =============================================================================
link_project_to_systemd() {
    local project="${1:-}"
    local project_dir="$PROJECTS_DIR/$project"

    [ -z "$project" ] && return 1
    [ ! -d "$project_dir" ] && return 1

    mkdir -p "$SYSTEMD_DIR"

    # Crear symlinks para cada archivo quadlet
    for file in "$project_dir"/*.container "$project_dir"/*.network "$project_dir"/*.target "$project_dir"/*.volume; do
        [ -f "$file" ] || continue
        local basename
        basename="$(basename "$file")"
        ln -sf "$file" "$SYSTEMD_DIR/$basename"
    done
}

cmd_link() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils link <proyecto>"; exit 1; }

    link_project_to_systemd "$project"
    systemctl --user daemon-reload
    log_ok "Proyecto '$project' enlazado a systemd"
}

cmd_unlink() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils unlink <proyecto>"; exit 1; }

    rm -f "$SYSTEMD_DIR/${project}"* 2>/dev/null || true
    systemctl --user daemon-reload
    log_ok "Proyecto '$project' desenlazado de systemd"
}

# =============================================================================
# GLOBAL SERVICES
# =============================================================================
cmd_install_global() {
    local service="${1:-}"
    [ -z "$service" ] && { log_error "Uso: podman-utils install-global <servicio>"; exit 1; }

    local shared_dir="$PODMAN_DIR/services-shared"
    local container_file="$shared_dir/${service}.container"

    if [ ! -f "$container_file" ]; then
        log_error "Servicio '$service' no existe en services-shared/"
        echo "Servicios disponibles:"
        ls -1 "$shared_dir" 2>/dev/null | sed 's/\.container$//' | sed 's/^/  /'
        exit 1
    fi

    mkdir -p "$SYSTEMD_GLOBAL"

    local socket_path="/run/user/$(id -u)/podman/podman.sock"
    local target="$SYSTEMD_GLOBAL/${service}.container"

    if grep -q "__PODMAN_SOCKET__" "$container_file" 2>/dev/null; then
        sed "s|__PODMAN_SOCKET__|$socket_path|g" "$container_file" > "$target"
    else
        cp "$container_file" "$target"
    fi

    systemctl --user daemon-reload
    log_ok "Servicio global '$service' instalado"
    echo "  Iniciar: systemctl --user start ${service}.service"
}

cmd_uninstall_global() {
    local service="${1:-}"
    [ -z "$service" ] && { log_error "Uso: podman-utils uninstall-global <servicio>"; exit 1; }

    systemctl --user stop "${service}.service" 2>/dev/null || true
    rm -f "$SYSTEMD_GLOBAL/${service}".* 2>/dev/null || true
    systemctl --user daemon-reload
    log_ok "Servicio global '$service' desinstalado"
}

# =============================================================================
# LIST
# =============================================================================
cmd_list() {
    echo "Proyectos:"
    echo ""

    if [ -z "$(ls -A "$PROJECTS_DIR" 2>/dev/null | grep -v .gitkeep | grep -v .gitignore)" ]; then
        echo "  (ninguno)"
        return 0
    fi

    for dir in "$PROJECTS_DIR"/*/; do
        [ -d "$dir" ] || continue
        local name
        name="$(basename "$dir")"
        [ "$name" = ".gitkeep" ] && continue
        [ "$name" = ".gitignore" ] && continue

        local status="detenido"
        if systemctl --user is-active "${name}.target" &>/dev/null; then
            status="activo"
        fi

        local containers
        containers=$(podman ps --filter "name=$name" --format "{{.Names}}" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')

        printf "  ${GREEN}%-20s${NC} %-10s %s\n" "$name" "[$status]" "$containers"
    done
    echo ""
}

cmd_list_templates() {
    echo "Templates disponibles:"
    echo ""

    for dir in "$TEMPLATES_DIR"/*/; do
        [ -d "$dir" ] || continue
        local name
        name="$(basename "$dir")"
        local desc=""

        case "$name" in
            python-postgres)       desc="Python + PostgreSQL" ;;
            python-postgres-redis) desc="Python + PostgreSQL + Redis" ;;
            fullstack)             desc="Front + Back + PostgreSQL + Traefik + Keycloak" ;;
            *)                     desc="" ;;
        esac

        printf "  ${YELLOW}%-25s${NC} %s\n" "$name" "$desc"
    done
    echo ""
}

# =============================================================================
# USAGE
# =============================================================================
usage() {
    echo "Uso: podman-utils <comando> [opciones]"
    echo ""
    echo "Proyectos:"
    echo "  create <template> <nombre>   Crear proyecto desde plantilla"
    echo "  start <nombre>               Iniciar proyecto"
    echo "  stop <nombre>                Detener proyecto"
    echo "  restart <nombre>             Reiniciar proyecto"
    echo "  logs <nombre> [servicio]     Ver logs en tiempo real"
    echo "  status <nombre>              Ver estado del proyecto"
    echo "  destroy <nombre>             Eliminar proyecto (datos incluidos)"
    echo "  link <nombre>                Enlazar proyecto a systemd"
    echo "  unlink <nombre>              Desenlazar proyecto de systemd"
    echo ""
    echo "Servicios globales:"
    echo "  install-global <servicio>    Instalar servicio compartido"
    echo "  uninstall-global <servicio>  Desinstalar servicio compartido"
    echo ""
    echo "Informacion:"
    echo "  list                         Listar proyectos"
    echo "  list-templates               Listar plantillas disponibles"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================
case "${1:-}" in
    create)           shift; cmd_create "$@" ;;
    start)            shift; cmd_start "$@" ;;
    stop)             shift; cmd_stop "$@" ;;
    restart)          shift; cmd_restart "$@" ;;
    logs)             shift; cmd_logs "$@" ;;
    status)           shift; cmd_status "$@" ;;
    destroy)          shift; cmd_destroy "$@" ;;
    link)             shift; cmd_link "$@" ;;
    unlink)           shift; cmd_unlink "$@" ;;
    install-global)   shift; cmd_install_global "$@" ;;
    uninstall-global) shift; cmd_uninstall_global "$@" ;;
    list)             cmd_list ;;
    list-templates)   cmd_list_templates ;;
    help|--help|-h)   usage ;;
    *)                usage; exit 1 ;;
esac
