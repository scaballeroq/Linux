#!/bin/bash
# quadlets-setup.sh - Configuracion de directorios y servicios systemd Quadlets para Kubuntu

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

require_podman() {
    if ! command -v podman &>/dev/null; then
        echo "Error: Podman no esta instalado. Ejecuta primero: ./install/podman-install.sh"
        exit 1
    fi
}

show_help() {
    cat <<EOF
Gestor de Quadlets para Podman - Kubuntu (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Crea directorios de systemd para Quadlets, instala servicios compartidos.
  --status, -s           Muestra el estado de los Quadlets.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE SYSTEMD QUADLETS - KUBUNTU"
    echo "================================================================="
    echo "Directorio Quadlets: $HOME/.config/containers/systemd"
    echo ""
    echo "Archivos Quadlets configurados:"
    ls -la "$HOME/.config/containers/systemd" 2>/dev/null || echo "  (Sin archivos)"
    echo ""
    echo "Unidades activas:"
    systemctl --user list-units "*podman*" 2>/dev/null || echo "  (Ninguna)"
    echo "================================================================="
}

setup_systemd_dirs() {
    echo "Creando directorios de systemd para Quadlets..."
    mkdir -p "$HOME/.config/containers/systemd"
    mkdir -p "$HOME/.config/containers/systemd/global"
    echo "Directorios creados."
}

setup_podman_dirs() {
    echo "Creando estructura de proyectos..."
    mkdir -p "$PODMAN_DIR/projects"
    mkdir -p "$PODMAN_DIR/services-shared"
    touch "$PODMAN_DIR/projects/.gitkeep"
    echo "Estructura de proyectos lista."
}

install_global_services() {
    local shared_dir="$PODMAN_DIR/services-shared"
    local systemd_global="$HOME/.config/containers/systemd/global"

    if [ ! -d "$shared_dir" ] || [ -z "$(ls -A "$shared_dir" 2>/dev/null)" ]; then
        echo "No hay servicios compartidos para instalar."
        return 0
    fi

    echo "Instalando servicios compartidos..."
    for container_file in "$shared_dir"/*.container; do
        [ -f "$container_file" ] || continue
        local basename
        basename="$(basename "$container_file")"
        cp "$container_file" "$systemd_global/$basename"
        echo "  $basename -> ~/.config/containers/systemd/global/"
    done

    systemctl --user daemon-reload
    echo "Servicios compartidos instalados."
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    "")
        echo "Configurador de Quadlets - Kubuntu"
        require_podman
        setup_systemd_dirs
        setup_podman_dirs
        install_global_services
        echo "Quadlets configurado correctamente."
        ;;
    *)
        echo "Opcion no reconocida: $1"
        show_help
        exit 1
        ;;
esac
