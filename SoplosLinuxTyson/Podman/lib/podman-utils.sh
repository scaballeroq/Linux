#!/bin/bash
# =============================================================================
# podman-utils - CLI de Gestión para Podman + Quadlets + systemd
# Soplos Linux Tyson (Debian Testing)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$PODMAN_DIR/templates"
PROJECTS_DIR="$PODMAN_DIR/projects"
SERVICES_SHARED_DIR="$PODMAN_DIR/services-shared"
SYSTEMD_DIR="${CONTAINERS_SYSTEMD_DIR:-$HOME/.config/containers/systemd}"

# Colores y formatos
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }
log_warn()  { echo -e "${MAGENTA}[WARN]${NC} $1"; }

ensure_systemd_dir() {
    mkdir -p "$SYSTEMD_DIR" 2>/dev/null || true
}

reload_systemd() {
    if command -v systemctl &>/dev/null; then
        systemctl --user daemon-reload 2>/dev/null || true
    fi
}

require_podman() {
    if ! command -v podman &>/dev/null; then
        log_error "Podman no está instalado. Ejecuta './install/podman-install.sh' primero."
        exit 1
    fi
}

# =============================================================================
# CREATE
# =============================================================================
cmd_create() {
    local template="${1:-}"
    local project="${2:-}"

    if [ -z "$template" ] || [ -z "$project" ]; then
        echo -e "${BOLD}Uso:${NC} podman-utils create <template> <nombre-proyecto>"
        echo ""
        cmd_list_templates
        exit 1
    fi

    # Validar caracteres del nombre del proyecto (letras, números y guiones)
    if [[ ! "$project" =~ ^[a-z0-9-]+$ ]]; then
        log_error "El nombre del proyecto debe contener solo letras minúsculas, números y guiones (ej. 'mi-api')."
        exit 1
    fi

    local template_dir="$TEMPLATES_DIR/$template"
    if [ ! -d "$template_dir" ]; then
        log_error "La plantilla '$template' no existe."
        echo ""
        cmd_list_templates
        exit 1
    fi

    local project_dir="$PROJECTS_DIR/$project"
    if [ -d "$project_dir" ]; then
        log_error "El proyecto '$project' ya existe en $project_dir"
        exit 1
    fi

    ensure_systemd_dir
    if [ -d "$SYSTEMD_DIR" ] && ls "$SYSTEMD_DIR/${project}"* &>/dev/null; then
        log_error "Ya existen archivos Quadlet para '$project' en $SYSTEMD_DIR"
        exit 1
    fi

    log_step "Creando proyecto '${BOLD}$project${NC}' desde la plantilla '$template'..."

    mkdir -p "$project_dir"

    local project_upper
    project_upper=$(echo "$project" | tr '[:lower:]-' '[:upper:]_')

    # Copiar contenido de la plantilla
    cp -r "$template_dir"/* "$project_dir"/ 2>/dev/null || true

    # Copiar .env.example a .env si existe
    if [ -f "$template_dir/.env.example" ]; then
        cp "$template_dir/.env.example" "$project_dir/.env.example"
        cp "$template_dir/.env.example" "$project_dir/.env"
    fi

    # Reemplazar placeholders en todos los archivos de texto y configuración
    find "$project_dir" -type f | while read -r file; do
        sed -i "s/__PROJECT__/$project/g" "$file"
        sed -i "s/__PROJECT_UPPER__/$project_upper/g" "$file"
        sed -i "s|__PROJECT_DIR__|$project_dir|g" "$file"
    done

    # Renombrar archivos y directorios con placeholders (depth-first)
    find "$project_dir" -depth -name "*__PROJECT__*" | while read -r file; do
        local dir
        local base
        dir="$(dirname "$file")"
        base="$(basename "$file" | sed "s/__PROJECT__/$project/g")"
        mv "$file" "$dir/$base"
    done

    # Enlazar archivos Quadlet a systemd
    link_project_to_systemd "$project"

    # Recargar systemd
    reload_systemd

    echo ""
    log_ok "Proyecto '${BOLD}$project${NC}' creado exitosamente en: $project_dir"
    echo ""
    echo -e "${BOLD}Siguientes pasos recomendados:${NC}"
    echo "  1. Configurar credenciales: nano $project_dir/.env (o: podman-utils env $project)"
    echo "  2. Iniciar el proyecto:     podman-utils start $project"
    echo "  3. Ver estado y logs:       podman-utils status $project"
    echo "                              podman-utils logs $project"
    echo ""
}

# =============================================================================
# START / STOP / RESTART
# =============================================================================
cmd_start() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils start <proyecto>"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    [ ! -d "$project_dir" ] && { log_error "El proyecto '$project' no existe."; exit 1; }

    log_step "Iniciando proyecto '${BOLD}$project${NC}'..."
    reload_systemd
    systemctl --user start "${project}.target"

    log_ok "Proyecto '$project' iniciado."
    cmd_status "$project"
}

cmd_stop() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils stop <proyecto>"; exit 1; }

    log_step "Deteniendo proyecto '${BOLD}$project${NC}'..."
    systemctl --user stop "${project}.target" 2>/dev/null || true

    log_ok "Proyecto '$project' detenido."
}

cmd_restart() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils restart <proyecto>"; exit 1; }

    log_step "Reiniciando proyecto '${BOLD}$project${NC}'..."
    systemctl --user restart "${project}.target"

    log_ok "Proyecto '$project' reiniciado."
    cmd_status "$project"
}

# =============================================================================
# ENABLE / DISABLE (Boot Autostart)
# =============================================================================
cmd_enable() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils enable <proyecto>"; exit 1; }

    log_step "Habilitando auto-arranque en boot para '$project'..."
    systemctl --user enable "${project}.target"
    log_ok "Proyecto '$project' se iniciará automáticamente con el sistema (linger)."
}

cmd_disable() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils disable <proyecto>"; exit 1; }

    log_step "Deshabilitando auto-arranque en boot para '$project'..."
    systemctl --user disable "${project}.target"
    log_ok "Auto-arranque deshabilitado para '$project'."
}

# =============================================================================
# LOGS
# =============================================================================
cmd_logs() {
    local project="${1:-}"
    local service="${2:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils logs <proyecto> [servicio]"; exit 1; }

    if [ -n "$service" ]; then
        local unit_name="${project}-${service}"
        [[ "$service" == "${project}-"* ]] && unit_name="$service"
        [[ "$unit_name" != *".service" ]] && unit_name="${unit_name}.service"
        journalctl --user -u "$unit_name" -f --no-pager
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
    echo -e "${BOLD}=== Estado del Proyecto: ${CYAN}$project${NC} ===${NC}"
    echo ""

    local target_active="inactivo"
    if systemctl --user is-active "${project}.target" &>/dev/null; then
        target_active="${GREEN}activo${NC}"
    else
        target_active="${RED}detenido${NC}"
    fi

    local target_enabled="deshabilitado"
    if systemctl --user is-enabled "${project}.target" &>/dev/null; then
        target_enabled="${GREEN}habilitado (boot)${NC}"
    fi

    echo -e "  ${BOLD}Target systemd:${NC} ${project}.target -> [$target_active] ($target_enabled)"
    echo ""

    echo -e "${BOLD}Servicios systemd:${NC}"
    systemctl --user list-units "${project}*" --no-pager 2>/dev/null || echo "  (sin unidades registradas)"

    echo ""
    echo -e "${BOLD}Contenedores Podman asociados:${NC}"
    if command -v podman &>/dev/null; then
        podman ps -a --filter "name=^${project}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}" 2>/dev/null || echo "  (ninguno)"
    else
        echo "  (Podman no está en ejecución o no disponible)"
    fi
    echo ""
}

# =============================================================================
# EXEC (Interactive shell / command execution)
# =============================================================================
cmd_exec() {
    local project="${1:-}"
    local service="${2:-}"
    shift 2 || true
    local cmd=("${@}")

    if [ -z "$project" ] || [ -z "$service" ]; then
        echo -e "${BOLD}Uso:${NC} podman-utils exec <proyecto> <servicio> [comando...]"
        echo "  Ejemplo: podman-utils exec mi-api backend bash"
        echo "  Ejemplo: podman-utils exec mi-api postgres psql -U postgres"
        exit 1
    fi

    local container_name="${project}-${service}"
    [[ "$service" == "${project}-"* ]] && container_name="$service"

    if ! podman ps --filter "name=^${container_name}$" --format "{{.Names}}" | grep -q "^${container_name}$"; then
        log_error "El contenedor '$container_name' no se encuentra en ejecución."
        exit 1
    fi

    if [ ${#cmd[@]} -eq 0 ]; then
        if podman exec "$container_name" which bash &>/dev/null; then
            cmd=("bash")
        else
            cmd=("sh")
        fi
    fi

    log_step "Ejecutando en '${container_name}': ${cmd[*]}..."
    podman exec -it "$container_name" "${cmd[@]}"
}

# =============================================================================
# PS
# =============================================================================
cmd_ps() {
    local project="${1:-}"
    if [ -n "$project" ]; then
        podman ps -a --filter "name=^${project}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
    else
        podman ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
    fi
}

# =============================================================================
# ENV (Edit or View .env)
# =============================================================================
cmd_env() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils env <proyecto>"; exit 1; }

    local env_file="$PROJECTS_DIR/$project/.env"
    if [ ! -f "$env_file" ]; then
        log_error "El archivo .env para '$project' no existe en $env_file"
        exit 1
    fi

    local editor="${EDITOR:-nano}"
    command -v "$editor" &>/dev/null || editor="nano"
    "$editor" "$env_file"
}

# =============================================================================
# VALIDATE
# =============================================================================
cmd_validate() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils validate <proyecto>"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    if [ ! -d "$project_dir" ]; then
        log_error "El proyecto '$project' no existe."
        exit 1
    fi

    log_step "Validando archivos Quadlet para '$project'..."
    local errors=0

    for file in "$project_dir"/*; do
        [ -f "$file" ] || continue
        case "$file" in
            *.container|*.network|*.volume|*.target)
                echo -n "  Verificando $(basename "$file")... "
                if [ -s "$file" ]; then
                    echo -e "${GREEN}OK${NC}"
                else
                    echo -e "${RED}VACÍO${NC}"
                    errors=$((errors + 1))
                fi
                ;;
        esac
    done

    reload_systemd
    if [ $errors -eq 0 ]; then
        log_ok "Validación completada sin errores."
    else
        log_error "Se encontraron $errors advertencias o errores."
    fi
}

# =============================================================================
# DESTROY
# =============================================================================
cmd_destroy() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils destroy <proyecto>"; exit 1; }

    local project_dir="$PROJECTS_DIR/$project"
    if [ ! -d "$project_dir" ]; then
        log_error "El proyecto '$project' no existe en $PROJECTS_DIR"
        exit 1
    fi

    log_warn "Se eliminará completamente el proyecto '$project' junto con sus contenedores y volúmenes."
    log_step "Deteniendo servicios de '$project'..."
    systemctl --user stop "${project}.target" 2>/dev/null || true

    log_step "Eliminando symlinks de Quadlets en systemd..."
    cmd_unlink "$project" 2>/dev/null || true

    log_step "Eliminando contenedores de Podman..."
    local c_ids
    c_ids=$(podman ps -aq --filter "name=^${project}" 2>/dev/null || true)
    if [ -n "$c_ids" ]; then
        echo "$c_ids" | xargs -r podman rm -f 2>/dev/null || true
    fi

    log_step "Eliminando volúmenes de Podman..."
    local v_names
    v_names=$(podman volume ls -q --filter "name=^${project}" 2>/dev/null || true)
    if [ -n "$v_names" ]; then
        echo "$v_names" | xargs -r podman volume rm 2>/dev/null || true
    fi

    log_step "Eliminando red de Podman..."
    podman network rm "$project" 2>/dev/null || true

    log_step "Eliminando directorio del proyecto ($project_dir)..."
    rm -rf "$project_dir"

    reload_systemd

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

    ensure_systemd_dir
    [ ! -d "$SYSTEMD_DIR" ] && return 0

    for file in "$project_dir"/*.container "$project_dir"/*.network "$project_dir"/*.target "$project_dir"/*.volume; do
        [ -f "$file" ] || continue
        local basename
        basename="$(basename "$file")"
        ln -sf "$file" "$SYSTEMD_DIR/$basename" 2>/dev/null || true
    done
}

cmd_link() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils link <proyecto>"; exit 1; }

    link_project_to_systemd "$project"
    reload_systemd
    log_ok "Archivos Quadlet del proyecto '$project' enlazados a $SYSTEMD_DIR/"
}

cmd_unlink() {
    local project="${1:-}"
    [ -z "$project" ] && { log_error "Uso: podman-utils unlink <proyecto>"; exit 1; }

    rm -f "$SYSTEMD_DIR/${project}"* 2>/dev/null || true
    reload_systemd
    log_ok "Archivos Quadlet del proyecto '$project' desenlazados de $SYSTEMD_DIR/"
}

# =============================================================================
# GLOBAL SERVICES
# =============================================================================
cmd_install_global() {
    local service="${1:-}"
    if [ -z "$service" ]; then
        echo -e "${BOLD}Uso:${NC} podman-utils install-global <servicio|all>"
        echo "Servicios compartidos disponibles:"
        ls -1 "$SERVICES_SHARED_DIR"/*.container 2>/dev/null | xargs -n1 basename | sed 's/\.container$//' | sed 's/^/  /'
        exit 1
    fi

    ensure_systemd_dir

    if [ "$service" = "all" ]; then
        log_step "Instalando todos los servicios y redes globales..."
        for f in "$SERVICES_SHARED_DIR"/*; do
            [ -f "$f" ] || continue
            ln -sf "$f" "$SYSTEMD_DIR/$(basename "$f")" 2>/dev/null || true
            log_ok "  $(basename "$f") -> systemd/"
        done
        reload_systemd
        log_ok "Todos los servicios globales han sido instalados."
        return 0
    fi

    local container_file="$SERVICES_SHARED_DIR/${service}.container"
    if [ ! -f "$container_file" ]; then
        log_error "El servicio '$service' no existe en services-shared/"
        echo "Disponibles:"
        ls -1 "$SERVICES_SHARED_DIR"/*.container 2>/dev/null | xargs -n1 basename | sed 's/\.container$//' | sed 's/^/  /'
        exit 1
    fi

    # Enlazar la red compartida proxy-net si existe
    if [ -f "$SERVICES_SHARED_DIR/proxy-net.network" ]; then
        ln -sf "$SERVICES_SHARED_DIR/proxy-net.network" "$SYSTEMD_DIR/proxy-net.network" 2>/dev/null || true
    fi

    # Enlazar el volumen correspondiente si existe
    if [ -f "$SERVICES_SHARED_DIR/${service}-data.volume" ]; then
        ln -sf "$SERVICES_SHARED_DIR/${service}-data.volume" "$SYSTEMD_DIR/${service}-data.volume" 2>/dev/null || true
    fi
    if [ -f "$SERVICES_SHARED_DIR/${service}-config.volume" ]; then
        ln -sf "$SERVICES_SHARED_DIR/${service}-config.volume" "$SYSTEMD_DIR/${service}-config.volume" 2>/dev/null || true
    fi

    ln -sf "$container_file" "$SYSTEMD_DIR/${service}.container" 2>/dev/null || true

    reload_systemd
    log_ok "Servicio global '$service' instalado en systemd."
    echo "  Iniciar con: systemctl --user start ${service}.service"
}

cmd_uninstall_global() {
    local service="${1:-}"
    [ -z "$service" ] && { log_error "Uso: podman-utils uninstall-global <servicio>"; exit 1; }

    log_step "Desinstalando servicio global '$service'..."
    systemctl --user stop "${service}.service" 2>/dev/null || true
    rm -f "$SYSTEMD_DIR/${service}".* 2>/dev/null || true
    reload_systemd
    log_ok "Servicio global '$service' desinstalado."
}

# =============================================================================
# LIST
# =============================================================================
cmd_list() {
    echo -e "${BOLD}Proyectos Registrados:${NC}"
    echo ""

    if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A "$PROJECTS_DIR" 2>/dev/null | grep -v '^\.gitkeep$')" ]; then
        echo "  (ninguno - crea uno con: podman-utils create <template> <nombre>)"
        echo ""
        return 0
    fi

    for dir in "$PROJECTS_DIR"/*/; do
        [ -d "$dir" ] || continue
        local name
        name="$(basename "$dir")"
        [ "$name" = ".gitkeep" ] && continue

        local status="detenido"
        local color_status="$RED"
        if systemctl --user is-active "${name}.target" &>/dev/null; then
            status="activo"
            color_status="$GREEN"
        fi

        local autostart="no-boot"
        if systemctl --user is-enabled "${name}.target" &>/dev/null; then
            autostart="boot"
        fi

        local containers="-"
        if command -v podman &>/dev/null; then
            containers=$(podman ps --filter "name=^${name}" --format "{{.Names}}" 2>/dev/null | tr '\n' ', ' | sed 's/,$//' || true)
            [ -z "$containers" ] && containers="-"
        fi

        printf "  ${CYAN}%-22s${NC} [${color_status}%-8s${NC}] (%-7s) Contenedores: %s\n" "$name" "$status" "$autostart" "$containers"
    done
    echo ""
}

cmd_list_templates() {
    echo -e "${BOLD}Plantillas Disponibles:${NC}"
    echo ""

    for dir in "$TEMPLATES_DIR"/*/; do
        [ -d "$dir" ] || continue
        local name
        name="$(basename "$dir")"
        local desc=""

        case "$name" in
            python-postgres)       desc="FastAPI + PostgreSQL + pg-data Volume" ;;
            python-postgres-redis) desc="FastAPI + PostgreSQL + Redis (Celery/Cache)" ;;
            fullstack)             desc="Vue 3 Vite + FastAPI + PostgreSQL + Traefik Proxy + Keycloak OIDC" ;;
            *)                     desc="Plantilla personalizada" ;;
        esac

        printf "  ${YELLOW}%-24s${NC} %s\n" "$name" "$desc"
    done
    echo ""
}

# =============================================================================
# USAGE
# =============================================================================
usage() {
    echo -e "${BOLD}podman-utils${NC} - Gestor de proyectos Podman + Quadlets en Soplos Linux Tyson"
    echo ""
    echo -e "${BOLD}Uso:${NC} podman-utils <comando> [argumentos]"
    echo ""
    echo -e "${BOLD}Ciclo de Vida de Proyectos:${NC}"
    echo "  create <template> <nombre>   Crear proyecto desde plantilla"
    echo "  start <nombre>               Iniciar proyecto completo con systemd"
    echo "  stop <nombre>                Detener proyecto"
    echo "  restart <nombre>             Reiniciar proyecto"
    echo "  status <nombre>              Ver estado de servicios y contenedores"
    echo "  logs <nombre> [servicio]     Ver logs en vivo con journalctl"
    echo "  exec <nombre> <servicio> [c] Abrir shell o ejecutar comando en contenedor"
    echo "  destroy <nombre>             Eliminar proyecto (contenedores, datos y código)"
    echo ""
    echo -e "${BOLD}Configuración y Enlaces:${NC}"
    echo "  enable <nombre>              Habilitar inicio automático en el boot"
    echo "  disable <nombre>             Deshabilitar inicio automático"
    echo "  env <nombre>                 Editar archivo de variables de entorno (.env)"
    echo "  validate <nombre>            Validar archivos Quadlet del proyecto"
    echo "  link <nombre>                Enlazar archivos Quadlet a systemd"
    echo "  unlink <nombre>              Desenlazar archivos de systemd"
    echo ""
    echo -e "${BOLD}Servicios Globales Compartidos:${NC}"
    echo "  install-global <servicio|all>  Instalar proxy Traefik, PostgreSQL o Redis global"
    echo "  uninstall-global <servicio>    Desinstalar servicio global de systemd"
    echo ""
    echo -e "${BOLD}Consultas:${NC}"
    echo "  list                         Listar todos los proyectos y su estado"
    echo "  list-templates               Listar plantillas disponibles"
    echo "  ps [nombre]                  Listar contenedores activos"
    echo ""
}

# =============================================================================
# MAIN ENTRYPOINT
# =============================================================================
case "${1:-}" in
    create)           shift; cmd_create "$@" ;;
    start)            shift; cmd_start "$@" ;;
    stop)             shift; cmd_stop "$@" ;;
    restart)          shift; cmd_restart "$@" ;;
    status)           shift; cmd_status "$@" ;;
    logs)             shift; cmd_logs "$@" ;;
    exec)             shift; cmd_exec "$@" ;;
    ps)               shift; cmd_ps "$@" ;;
    env)              shift; cmd_env "$@" ;;
    validate)         shift; cmd_validate "$@" ;;
    enable)           shift; cmd_enable "$@" ;;
    disable)          shift; cmd_disable "$@" ;;
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
