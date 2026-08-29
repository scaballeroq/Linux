#!/bin/bash
# =============================================================================
# podman-utils - CLI para gestión de proyectos y servicios Quadlets con Podman en CachyOS
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$PODMAN_DIR/templates"
PROJECTS_DIR="$PODMAN_DIR/projects"
SERVICES_SHARED="$PODMAN_DIR/services-shared"
SYSTEMD_DIR="$HOME/.config/containers/systemd"
SYSTEMD_GLOBAL="$SYSTEMD_DIR/global"

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
        ls -1 "$TEMPLATES_DIR" 2>/dev/null | sed 's/^/  • /' || echo "  (ninguno)"
        exit 1
    fi

    local template_dir="$TEMPLATES_DIR/$template"
    if [ ! -d "$template_dir" ]; then
        log_error "El template '$template' no existe."
        echo "Templates disponibles:"
        ls -1 "$TEMPLATES_DIR" 2>/dev/null | sed 's/^/  • /'
        exit 1
    fi

    local project_dir="$PROJECTS_DIR/$project"
    if [ -d "$project_dir" ]; then
        log_error "El proyecto '$project' ya existe en $project_dir."
        exit 1
    fi

    log_step "Creando proyecto '$project' desde template '$template'..."

    mkdir -p "$project_dir"

    local project_upper
    project_upper=$(echo "$project" | tr '[:lower:]-' '[:upper:]_')

    cp -r "$template_dir"/* "$project_dir"/
    cp "$template_dir"/.env.example "$project_dir/.env" 2>/dev/null || true

    # Reemplazar placeholders en todos los archivos del proyecto
    find "$project_dir" -type f \( -name "*.container" -o -name "*.network" -o -name "*.target" -o -name "*.volume" -o -name ".env*" \) | while read -r file; do
        sed -i "s/__PROJECT__/$project/g" "$file"
        sed -i "s/__PROJECT_UPPER__/$project_upper/g" "$file"
        sed -i "s|__PROJECT_DIR__|$project_dir|g" "$file"
    done

    # Renombrar archivos con placeholder
    find "$project_dir" -name "*__PROJECT__*" | while read -r file; do
        mv "$file" "$(echo "$file" | sed "s/__PROJECT__/$project/g")"
    done

    # Crear symlinks en systemd
    link_project_to_systemd "$project"

    systemctl --user daemon-reload 2>/dev/null || true

    echo ""
    log_ok "Proyecto '$project' creado exitosamente en: $project_dir"
    echo ""
    echo "Pasos recomendados:"
    echo "  1. Configura tus variables: nano $project_dir/.env"
    echo "  2. Inicia los servicios:    podman-utils start $project"
    echo "  3. Ver estado:              podman-utils status $project"
    echo "  4. Ver logs en vivo:        podman-utils logs $project"
    echo ""
}

# =============================================================================
# START / STOP / RESTART
# =============================================================================
cmd_start() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils start <proyecto>"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    [ ! -d "$project_dir" ] && { log_error "El proyecto '$project' no existe en $PROJECTS_DIR."; exit 1; }

    log_step "Iniciando proyecto '$project' mediante systemd user..."
    systemctl --user daemon-reload

    if [ -f "$project_dir/${project}.target" ]; then
        systemctl --user start "${project}.target"
    else
        for c in "$project_dir"/*.container; do
            [ -f "$c" ] || continue
            local base
            base="$(basename "$c" .container)"
            systemctl --user start "${base}.service" 2>/dev/null || true
        done
    fi

    log_ok "Comando de inicio enviado para el proyecto '$project'."
    sleep 1
    cmd_status "$project"
}

cmd_stop() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils stop <proyecto>"; exit 1; }

    log_step "Deteniendo proyecto '$project'..."
    if systemctl --user list-units --all | grep -q "${project}.target"; then
        systemctl --user stop "${project}.target" 2>/dev/null || true
    fi

    for c in "$PROJECTS_DIR/$project"/*.container; do
        [ -f "$c" ] || continue
        local base
        base="$(basename "$c" .container)"
        systemctl --user stop "${base}.service" 2>/dev/null || true
    done

    log_ok "Proyecto '$project' detenido."
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
        journalctl --user -u "${project}-${service}.service" -f --no-pager
    else
        journalctl --user -u "${project}*.service" -f --no-pager
    fi
}

# =============================================================================
# STATUS
# =============================================================================
cmd_status() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils status <proyecto>"; exit 1; }

    echo ""
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${CYAN}📊 ESTADO DEL PROYECTO: $project${NC}"
    echo -e "${CYAN}=================================================================${NC}"
    echo ""
    echo "• Unidades Systemd activas:"
    systemctl --user list-units "${project}*" --no-pager 2>/dev/null || echo "  (Ninguna unidad activa)"
    echo ""
    echo "• Contenedores Podman asociados:"
    podman ps --filter "name=$project" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  (Sin contenedores)"
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
        log_error "El proyecto '$project' no existe."
        exit 1
    fi

    log_step "Deteniendo servicios asociados a '$project'..."
    cmd_stop "$project" 2>/dev/null || true

    log_step "Eliminando symlinks de systemd en ~/.config/containers/systemd/..."
    rm -f "$SYSTEMD_DIR/${project}"* 2>/dev/null || true

    log_step "Eliminando contenedores de Podman..."
    local c_ids
    c_ids=$(podman ps -a --filter "name=$project" --format "{{.ID}}" 2>/dev/null || true)
    if [ -n "$c_ids" ]; then
        echo "$c_ids" | xargs -r podman rm -f 2>/dev/null || true
    fi

    log_step "Eliminando volúmenes del proyecto..."
    local v_ids
    v_ids=$(podman volume ls --filter "name=$project" --format "{{.Name}}" 2>/dev/null || true)
    if [ -n "$v_ids" ]; then
        echo "$v_ids" | xargs -r podman volume rm 2>/dev/null || true
    fi

    log_step "Eliminando red del proyecto..."
    podman network rm "$project" 2>/dev/null || true

    log_step "Eliminando directorio del proyecto en $project_dir..."
    rm -rf "$project_dir"

    systemctl --user daemon-reload 2>/dev/null || true

    log_ok "Proyecto '$project' eliminado completamente."
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
    log_ok "Proyecto '$project' enlazado a ~/.config/containers/systemd/."
}

cmd_unlink() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils unlink <proyecto>"; exit 1; }

    rm -f "$SYSTEMD_DIR/${project}"* 2>/dev/null || true
    systemctl --user daemon-reload
    log_ok "Proyecto '$project' desenlazado de systemd."
}

# =============================================================================
# GLOBAL SHARED SERVICES
# =============================================================================
cmd_install_global() {
    local service="${1:-}"
    [ -z "$service" ] && { log_error "Uso: podman-utils install-global <servicio>"; exit 1; }

    local container_file="$SERVICES_SHARED/${service}.container"

    if [ ! -f "$container_file" ]; then
        log_error "El servicio '$service' no existe en $SERVICES_SHARED."
        echo "Servicios compartidos disponibles:"
        ls -1 "$SERVICES_SHARED" 2>/dev/null | sed 's/\.container$//' | sed 's/^/  • /'
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
    log_ok "Servicio global '$service' instalado en ~/.config/containers/systemd/global/."
    echo "  Para iniciar: systemctl --user start ${service}.service"
}

cmd_uninstall_global() {
    local service="${1:-}"
    [ -z "$service" ] && { log_error "Uso: podman-utils uninstall-global <servicio>"; exit 1; }

    systemctl --user stop "${service}.service" 2>/dev/null || true
    rm -f "$SYSTEMD_GLOBAL/${service}".* 2>/dev/null || true
    systemctl --user daemon-reload
    log_ok "Servicio global '$service' desinstalado."
}

# =============================================================================
# LIST
# =============================================================================
cmd_list() {
    echo "================================================================="
    echo "📂 PROYECTOS PODMAN QUADLETS"
    echo "================================================================="

    if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A "$PROJECTS_DIR" 2>/dev/null | grep -v '^\.gitkeep$')" ]; then
        echo "  (Ningún proyecto creado aún. Crea uno con: podman-utils create <template> <nombre>)"
        echo "================================================================="
        return 0
    fi

    for dir in "$PROJECTS_DIR"/*/; do
        [ -d "$dir" ] || continue
        local name
        name="$(basename "$dir")"
        [ "$name" = ".gitkeep" ] && continue

        local status="detenido"
        if systemctl --user is-active "${name}.target" &>/dev/null; then
            status="activo"
        fi

        local containers
        containers=$(podman ps --filter "name=$name" --format "{{.Names}}" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')

        printf "  • ${GREEN}%-20s${NC} %-10s %s\n" "$name" "[$status]" "${containers:-sin contenedores corriendo}"
    done
    echo "================================================================="
}

cmd_list_templates() {
    echo "================================================================="
    echo "📋 PLANTILLAS DE PROYECTOS DISPONIBLES"
    echo "================================================================="

    for dir in "$TEMPLATES_DIR"/*/; do
        [ -d "$dir" ] || continue
        local name
        name="$(basename "$dir")"
        local desc=""

        case "$name" in
            python-postgres)       desc="Python (FastAPI/Flask) + PostgreSQL" ;;
            python-postgres-redis) desc="Python + PostgreSQL + Redis (Celery/Cache)" ;;
            fullstack)             desc="Frontend + Backend + PostgreSQL + Traefik + Keycloak" ;;
            *)                     desc="Plantilla personalizada" ;;
        esac

        printf "  • ${YELLOW}%-25s${NC} %s\n" "$name" "$desc"
    done
    echo "================================================================="
}

# =============================================================================
# DOCTOR / DIAGNOSTICS
# =============================================================================
cmd_doctor() {
    echo "================================================================="
    echo "🩺 DIAGNÓSTICO DE PODMAN ROOTLESS - CACHYOS (KDE PLASMA)"
    echo "================================================================="

    # 1. Podman CLI
    if command -v podman &>/dev/null; then
        log_ok "Podman: $(podman --version)"
    else
        log_error "Podman no está instalado."
    fi

    # 2. Systemd Socket
    if systemctl --user is-active podman.socket &>/dev/null; then
        log_ok "Socket de Podman: Activo (/run/user/$(id -u)/podman/podman.sock)"
    else
        log_info "Socket de Podman: Inactivo (Ejecuta: systemctl --user enable --now podman.socket)"
    fi

    # 3. Linger
    local linger_val
    linger_val=$(loginctl show-user "$USER" 2>/dev/null | grep -i "Linger=" | cut -d= -f2 || echo "no")
    if [ "$linger_val" = "yes" ]; then
        log_ok "Persistencia Linger: Habilitada (los contenedores se ejecutan en segundo plano)"
    else
        log_info "Persistencia Linger: Deshabilitada (Ejecuta: loginctl enable-linger $USER)"
    fi

    # 4. DOCKER_HOST
    if [ -n "${DOCKER_HOST:-}" ]; then
        log_ok "DOCKER_HOST: $DOCKER_HOST"
    else
        log_info "DOCKER_HOST: No exportado en el shell actual (Carga con: source ~/.bashrc)"
    fi

    # 5. Generador Quadlet
    if [ -f /usr/lib/systemd/user-generators/podman-user-generator ]; then
        log_ok "Generador Quadlet: Integrado en Systemd"
    else
        log_error "Generador Quadlet no encontrado en /usr/lib/systemd/user-generators/podman-user-generator."
    fi

    echo "================================================================="
}

# =============================================================================
# USAGE
# =============================================================================
usage() {
    cat <<EOF
🐳 podman-utils - Gestor de Proyectos y Contenedores Quadlets (CachyOS)

Uso:
  podman-utils <comando> [argumentos]

Proyectos:
  create <template> <nombre>   Crea un nuevo proyecto a partir de una plantilla
  start <nombre>               Inicia todos los contenedores del proyecto vía systemd
  stop <nombre>                Detiene el proyecto y sus contenedores
  restart <nombre>             Reinicia el proyecto
  logs <nombre> [servicio]     Muestra los logs en vivo vía journalctl
  status <nombre>              Muestra el estado detallado de contenedores y servicios
  destroy <nombre>             Elimina por completo el proyecto (archivos, contenedores, volúmenes)
  link <nombre>                Enlaza los archivos Quadlet del proyecto a systemd
  unlink <nombre>              Desenlaza los archivos Quadlet de systemd

Servicios Globales:
  install-global <servicio>    Instala un servicio compartido (postgres, redis, traefik, keycloak)
  uninstall-global <servicio>  Desinstala un servicio compartido

Diagnóstico e Información:
  list                         Lista todos los proyectos creados y su estado
  list-templates               Muestra las plantillas disponibles
  doctor                       Ejecuta un diagnóstico completo del entorno Podman y Quadlets
  help                         Muestra este mensaje de ayuda
EOF
}

# =============================================================================
# MAIN ENTRYPOINT
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
    list|ps)          cmd_list ;;
    list-templates)   cmd_list_templates ;;
    doctor|check)     cmd_doctor ;;
    help|--help|-h)   usage ;;
    *)                usage; exit 1 ;;
esac
