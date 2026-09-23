#!/bin/bash
# =============================================================================
# podman-utils.sh - CLI para Gestion de Proyectos y Contenedores Quadlets
# openSUSE Tumbleweed (KDE Plasma 6 + Wayland)
# =============================================================================

set -euo pipefail

# Directorios base
REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]:-$0}")"
SCRIPT_DIR="$(cd "$(dirname "$REAL_SCRIPT")" && pwd)"
PODMAN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$PODMAN_DIR/templates"
PROJECTS_DIR="$PODMAN_DIR/projects"
SHARED_DIR="$PODMAN_DIR/services-shared"
SYSTEMD_QUADLETS_DIR="$HOME/.config/containers/systemd"
SYSTEMD_GLOBAL_DIR="$SYSTEMD_QUADLETS_DIR/global"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

# Colores
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
# PROYECTOS
# =============================================================================

cmd_create() {
    local template="${1:-}"
    local project_name="${2:-}"

    if [ -z "$template" ] || [ -z "$project_name" ]; then
        log_error "Uso: podman-utils create <template> <nombre-proyecto>"
        echo ""
        cmd_list_templates
        exit 1
    fi

    local src_dir="$TEMPLATES_DIR/$template"
    local dst_dir="$PROJECTS_DIR/$project_name"

    if [ ! -d "$src_dir" ]; then
        log_error "Template '$template' no existe."
        echo ""
        cmd_list_templates
        exit 1
    fi

    if [ -d "$dst_dir" ]; then
        log_error "El proyecto '$project_name' ya existe en $dst_dir"
        exit 1
    fi

    log_step "Creando proyecto '$project_name' desde template '$template'..."

    # Copiar template
    mkdir -p "$dst_dir"
    cp -r "$src_dir"/* "$dst_dir/"
    [ -f "$src_dir"/.env.example ] && cp "$src_dir/.env.example" "$dst_dir/.env" 2>/dev/null || true

    # Reemplazar __PROJECT__ en nombres de archivo
    for file in "$dst_dir"/__PROJECT__*; do
        [ -f "$file" ] || continue
        local new_name
        new_name="$(echo "$file" | sed "s/__PROJECT__/$project_name/g")"
        mv "$file" "$new_name"
    done

    # Reemplazar __PROJECT__ en contenido de archivos
    local socket_path="/run/user/$(id -u)/podman/podman.sock"
    find "$dst_dir" -type f -exec sed -i \
        -e "s|__PROJECT__|$project_name|g" \
        -e "s|__PROJECT_DIR__|$dst_dir|g" \
        -e "s|__PODMAN_SOCKET__|$socket_path|g" \
        {} +

    # Enlazar a systemd
    link_project "$project_name" "$dst_dir"

    # Recargar systemd
    systemctl --user daemon-reload

    log_ok "Proyecto '$project_name' creado en: $dst_dir"
    echo ""
    echo "Para iniciar:"
    echo "  podman-utils start $project_name"
    echo ""
    echo "Para ver estado:"
    echo "  podman-utils status $project_name"
}

cmd_start() {
    local project_name="${1:-}"

    if [ -z "$project_name" ]; then
        log_error "Uso: podman-utils start <nombre-proyecto>"
        exit 1
    fi

    local target="$project_name.target"

    log_step "Iniciando proyecto '$project_name'..."

    # Iniciar via target si existe, o servicios individuales
    if systemctl --user list-unit-files "$target" &>/dev/null; then
        systemctl --user start "$target"
    else
        # Iniciar todos los servicios del proyecto
        for service in $(get_project_services "$project_name"); do
            systemctl --user start "$service"
        done
    fi

    log_ok "Proyecto '$project_name' iniciado"
    echo ""
    cmd_status "$project_name"
}

cmd_stop() {
    local project_name="${1:-}"

    if [ -z "$project_name" ]; then
        log_error "Uso: podman-utils stop <nombre-proyecto>"
        exit 1
    fi

    local target="$project_name.target"

    log_step "Deteniendo proyecto '$project_name'..."

    if systemctl --user list-unit-files "$target" &>/dev/null; then
        systemctl --user stop "$target"
    else
        for service in $(get_project_services "$project_name"); do
            systemctl --user stop "$service"
        done
    fi

    log_ok "Proyecto '$project_name' detenido"
}

cmd_restart() {
    local project_name="${1:-}"
    cmd_stop "$project_name"
    sleep 1
    cmd_start "$project_name"
}

cmd_logs() {
    local project_name="${1:-}"
    local service_name="${2:-}"

    if [ -z "$project_name" ]; then
        log_error "Uso: podman-utils logs <nombre-proyecto> [servicio]"
        exit 1
    fi

    if [ -n "$service_name" ]; then
        journalctl --user -u "${project_name}-${service_name}.service" -f
    else
        # Logs de todos los servicios del proyecto
        local units=()
        for service in $(get_project_services "$project_name"); do
            units+=("-u" "$service")
        done
        journalctl --user "${units[@]}" -f
    fi
}

cmd_status() {
    local project_name="${1:-}"

    if [ -z "$project_name" ]; then
        log_error "Uso: podman-utils status <nombre-proyecto>"
        exit 1
    fi

    echo "================================================================="
    echo "Estado del proyecto: $project_name"
    echo "================================================================="

    # Estado de servicios systemd
    for service in $(get_project_services "$project_name"); do
        local state
        state="$(systemctl --user is-active "$service" 2>/dev/null || echo "inactive")"
        local enabled
        enabled="$(systemctl --user is-enabled "$service" 2>/dev/null || echo "disabled")"

        if [ "$state" = "active" ]; then
            printf "  %-35s ${GREEN}%-10s${NC} (%s)\n" "$service" "[$state]" "$enabled"
        else
            printf "  %-35s ${RED}%-10s${NC} (%s)\n" "$service" "[$state]" "$enabled"
        fi
    done

    echo ""
    echo "Contenedores en ejecucion:"
    podman ps --filter "name=$project_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
    echo "================================================================="
}

cmd_destroy() {
    local project_name="${1:-}"

    if [ -z "$project_name" ]; then
        log_error "Uso: podman-utils destroy <nombre-proyecto>"
        exit 1
    fi

    local project_dir="$PROJECTS_DIR/$project_name"

    if [ ! -d "$project_dir" ]; then
        log_error "El proyecto '$project_name' no existe en $project_dir"
        exit 1
    fi

    echo -e "${RED}ADVERTENCIA: Se eliminara el proyecto '$project_name' y sus datos.${NC}"
    read -rp "Estas seguro? (s/N): " confirm

    if [[ ! "$confirm" =~ ^[sS]$ ]]; then
        echo "Cancelado."
        exit 0
    fi

    log_step "Deteniendo servicios..."
    cmd_stop "$project_name" 2>/dev/null || true

    log_step "Desvinculando de systemd..."
    unlink_project "$project_name"

    systemctl --user daemon-reload

    log_step "Eliminando archivos del proyecto..."
    rm -rf "$project_dir"

    log_ok "Proyecto '$project_name' eliminado correctamente."
}

# =============================================================================
# SERVICIOS GLOBALES COMPARTIDOS
# =============================================================================

cmd_install_global() {
    local service="${1:-}"

    if [ -z "$service" ]; then
        log_error "Uso: podman-utils install-global <servicio>"
        echo ""
        echo "Servicios disponibles en $SHARED_DIR:"
        for f in "$SHARED_DIR"/*.container; do
            [ -f "$f" ] && basename "$f" .container
        done
        exit 1
    fi

    local src="$SHARED_DIR/$service.container"
    local dst="$SYSTEMD_GLOBAL_DIR/$service.container"
    local socket_path="/run/user/$(id -u)/podman/podman.sock"

    if [ ! -f "$src" ]; then
        log_error "Servicio global '$service' no encontrado en $SHARED_DIR"
        exit 1
    fi

    mkdir -p "$SYSTEMD_GLOBAL_DIR"
    sed "s|__PODMAN_SOCKET__|$socket_path|g" "$src" > "$dst"

    systemctl --user daemon-reload

    log_ok "Servicio global '$service' instalado."
    echo "Para iniciarlo: systemctl --user start $service.service"
}

cmd_uninstall_global() {
    local service="${1:-}"

    if [ -z "$service" ]; then
        log_error "Uso: podman-utils uninstall-global <servicio>"
        exit 1
    fi

    local dst="$SYSTEMD_GLOBAL_DIR/$service.container"

    if [ -f "$dst" ]; then
        systemctl --user stop "$service.service" 2>/dev/null || true
        rm -f "$dst"
        systemctl --user daemon-reload
        log_ok "Servicio global '$service' desinstalado."
    else
        log_info "El servicio '$service' no estaba instalado."
    fi
}

# =============================================================================
# HELPERS
# =============================================================================

link_project() {
    local project_name="$1"
    local project_dir="$2"

    mkdir -p "$SYSTEMD_QUADLETS_DIR/$project_name"
    mkdir -p "$SYSTEMD_USER_DIR"

    # Enlazar archivos Quadlet (.container, .network, .volume)
    for file in "$project_dir"/*.{container,network,volume}; do
        [ -f "$file" ] || continue
        local basename
        basename="$(basename "$file")"
        ln -sf "$file" "$SYSTEMD_QUADLETS_DIR/$project_name/$basename"
    done

    # Enlazar archivo .target a ~/.config/systemd/user/
    for file in "$project_dir"/*.target; do
        [ -f "$file" ] || continue
        local basename
        basename="$(basename "$file")"
        ln -sf "$file" "$SYSTEMD_USER_DIR/$basename"
    done
}

unlink_project() {
    local project_name="$1"

    # Eliminar enlaces de Quadlets
    rm -rf "$SYSTEMD_QUADLETS_DIR/$project_name"

    # Eliminar enlaces de .target
    rm -f "$SYSTEMD_USER_DIR/$project_name.target"
}

get_project_services() {
    local project_name="$1"
    local project_dir="$PROJECTS_DIR/$project_name"

    if [ -d "$project_dir" ]; then
        for file in "$project_dir"/*.container; do
            [ -f "$file" ] || continue
            basename "$file" .container
        done | sed "s/$/.service/"
    fi
}

# =============================================================================
# LISTAS
# =============================================================================

cmd_list() {
    echo "================================================================="
    echo "PROYECTOS ACTIVOS:"
    echo "================================================================="

    if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A "$PROJECTS_DIR" 2>/dev/null)" ]; then
        echo "  No hay proyectos creados."
        echo "  Crea uno con: podman-utils create <template> <nombre>"
        echo "================================================================="
        return 0
    fi

    for dir in "$PROJECTS_DIR"/*/; do
        [ -d "$dir" ] || continue
        local name
        name="$(basename "$dir")"
        local status="inactivo"

        # Comprobar si algún contenedor corre
        local containers
        containers="$(podman ps --filter "name=$name" --format "{{.Names}}" 2>/dev/null | tr '\n' ' ')"

        [ -n "$containers" ] && status="activo"

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
    echo "🩺 DIAGNÓSTICO DE PODMAN ROOTLESS - OPENSUSE TUMBLEWEED (KDE 6)"
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
        local reload_hint="source ~/.bashrc"
        if [ -n "${ZSH_VERSION:-}" ]; then
            reload_hint="source ~/.zshrc"
        fi
        log_info "DOCKER_HOST: No exportado en el shell actual (Carga con: $reload_hint)"
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
🐳 podman-utils - Gestor de Proyectos y Contenedores Quadlets (openSUSE Tumbleweed)

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
