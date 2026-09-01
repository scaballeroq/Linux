#!/bin/bash
# podman-utils.sh - CLI para gestion de proyectos Podman con Quadlets

set -euo pipefail

PODMAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTS_DIR="$PODMAN_DIR/projects"
TEMPLATES_DIR="$PODMAN_DIR/templates"
SYSTEMD_DIR="$HOME/.config/containers/systemd"
NETWORK_NAME="devfed-net"

create_project() {
    local template="$1"
    local name="$2"

    if [ -z "$template" ] || [ -z "$name" ]; then
        echo "Uso: podman-utils create <template> <nombre>"
        echo "Templates disponibles:"
        ls "$TEMPLATES_DIR" 2>/dev/null || echo "  (ninguno)"
        return 1
    fi

    local template_dir="$TEMPLATES_DIR/$template"
    if [ ! -d "$template_dir" ]; then
        echo "Template no encontrado: $template"
        return 1
    fi

    local project_dir="$PROJECTS_DIR/$name"
    if [ -d "$project_dir" ]; then
        echo "El proyecto ya existe: $name"
        return 1
    fi

    mkdir -p "$project_dir"
    cp -r "$template_dir"/* "$project_dir"/ 2>/dev/null || true

    local PROJECT_UPPER
    PROJECT_UPPER=$(echo "$name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    find "$project_dir" -type f -exec sed -i \
        -e "s/__PROJECT__/$name/g" \
        -e "s/__PROJECT_UPPER__/$PROJECT_UPPER/g" \
        -e "s|__PROJECT_DIR__|$project_dir|g" \
        {} +

    mkdir -p "$SYSTEMD_DIR/$name"
    if [ -d "$project_dir" ]; then
        cp "$project_dir"/*.container "$SYSTEMD_DIR/$name/" 2>/dev/null || true
    fi

    systemctl --user daemon-reload
    echo "Proyecto '$name' creado desde template '$template'."
}

start_project() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "Uso: podman-utils start <nombre>"
        return 1
    fi
    systemctl --user start "$name"*.service 2>/dev/null || \
    systemctl --user start "$(ls "$SYSTEMD_DIR/$name/"*.container 2>/dev/null | xargs -I{} basename {} .container)" 2>/dev/null || true
    echo "Proyecto '$name' iniciado."
}

stop_project() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "Uso: podman-utils stop <nombre>"
        return 1
    fi
    systemctl --user stop "$(ls "$SYSTEMD_DIR/$name/"*.container 2>/dev/null | xargs -I{} basename {} .container)" 2>/dev/null || true
    echo "Proyecto '$name' detenido."
}

status_project() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "Uso: podman-utils status <nombre>"
        return 1
    fi
    systemctl --user status "$(ls "$SYSTEMD_DIR/$name/"*.container 2>/dev/null | xargs -I{} basename {} .container)" 2>/dev/null || \
    systemctl --user list-units "*${name}*" 2>/dev/null || echo "Proyecto no encontrado: $name"
}

destroy_project() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "Uso: podman-utils destroy <nombre>"
        return 1
    fi

    stop_project "$name"
    rm -rf "$SYSTEMD_DIR/$name" 2>/dev/null || true
    rm -rf "$PROJECTS_DIR/$name" 2>/dev/null || true
    systemctl --user daemon-reload
    echo "Proyecto '$name' eliminado."
}

list_projects() {
    echo "Proyectos activos:"
    ls "$PROJECTS_DIR" 2>/dev/null || echo "  (ninguno)"
}

list_templates() {
    echo "Templates disponibles:"
    ls "$TEMPLATES_DIR" 2>/dev/null || echo "  (ninguno)"
}

doctor() {
    echo "Diagnostico de Podman:"
    echo "Podman: $(podman --version 2>/dev/null || echo 'No instalado')"
    echo "Socket: $(systemctl --user is-active podman.socket 2>/dev/null || echo 'Inactivo')"
    echo "Linger: $(loginctl show-user "$USER" 2>/dev/null | grep -i 'Linger=' | cut -d= -f2 || echo 'no')"
    echo "DOCKER_HOST: ${DOCKER_HOST:-No exportado}"
    echo "Redes: $(podman network ls 2>/dev/null | grep "$NETWORK_NAME" || echo "Red '$NETWORK_NAME' no encontrada")"
}

case "${1:-}" in
    create)
        create_project "$2" "$3"
        ;;
    start)
        start_project "$2"
        ;;
    stop)
        stop_project "$2"
        ;;
    status)
        status_project "$2"
        ;;
    destroy)
        destroy_project "$2"
        ;;
    list|ls)
        list_projects
        ;;
    templates)
        list_templates
        ;;
    doctor)
        doctor
        ;;
    *)
        echo "Uso: podman-utils {create|start|stop|status|destroy|list|templates|doctor}"
        ;;
esac
