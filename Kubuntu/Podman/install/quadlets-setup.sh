#!/bin/bash
# =============================================================================
# quadlets-setup.sh - Configuración de Systemd Quadlets para Kubuntu
# =============================================================================
# - Configura directorios systemd de usuario para Quadlets
# - Instala servicios compartidos (PostgreSQL, Redis, Traefik, Keycloak)
# - Recarga el generador de Quadlets en systemd (--user daemon-reload)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

require_podman() {
    if ! command -v podman &>/dev/null; then
        echo "❌ Error: Podman no está instalado. Ejecuta primero: ./install/podman-install.sh"
        exit 1
    fi
}

show_help() {
    cat <<EOF
Gestor de Quadlets para Podman - Kubuntu 26.04.1 LTS

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Crea directorios de systemd para Quadlets e instala servicios compartidos.
  --status, -s           Muestra el estado de los Quadlets y unidades systemd de usuario.
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
    echo "Unidades activas de contenedores (systemd --user):"
    systemctl --user list-units "*podman*" "*container*" 2>/dev/null || echo "  (Ninguna)"
    echo "================================================================="
}

setup_systemd_dirs() {
    echo "   - Creando directorios de systemd para Quadlets..."
    mkdir -p "$HOME/.config/containers/systemd"
    mkdir -p "$HOME/.config/containers/systemd/global"
}

setup_podman_dirs() {
    echo "   - Creando estructura de proyectos de contenedores..."
    mkdir -p "$PODMAN_DIR/projects"
    mkdir -p "$PODMAN_DIR/services-shared"
    touch "$PODMAN_DIR/projects/.gitkeep"
}

install_global_services() {
    local shared_dir="$PODMAN_DIR/services-shared"
    local systemd_global="$HOME/.config/containers/systemd/global"

    if [ ! -d "$shared_dir" ] || [ -z "$(ls -A "$shared_dir" 2>/dev/null)" ]; then
        echo "   - No hay servicios compartidos para instalar."
        return 0
    fi

    echo "   - Instalando servicios compartidos en ~/.config/containers/systemd/global/..."
    for container_file in "$shared_dir"/*.container; do
        [ -f "$container_file" ] || continue
        local basename
        basename="$(basename "$container_file")"
        cp "$container_file" "$systemd_global/$basename"
        echo "     * $basename"
    done

    systemctl --user daemon-reload 2>/dev/null || true
    echo "   - Generador Quadlet recargado (systemctl --user daemon-reload)."
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
        echo "================================================================="
        echo "CONFIGURANDO SERVICIOS QUADLETS - KUBUNTU"
        echo "================================================================="
        require_podman
        setup_systemd_dirs
        setup_podman_dirs
        install_global_services
        echo "✅ Quadlets configurados correctamente."
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
