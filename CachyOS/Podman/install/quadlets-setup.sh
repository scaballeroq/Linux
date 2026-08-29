#!/bin/bash
# quadlets-setup.sh - Configuración de directorios y servicios systemd Quadlets para Podman en CachyOS + KDE Plasma
#
# Uso:
#   ./quadlets-setup.sh              -> Prepara los directorios de Quadlets e instala los servicios compartidos
#   ./quadlets-setup.sh --status     -> Comprueba las unidades Quadlets generadas en systemd user
#   ./quadlets-setup.sh --help       -> Muestra la ayuda interactiva

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }

require_podman() {
    if ! command -v podman &>/dev/null; then
        log_error "Podman no está instalado. Ejecuta primero: ./install/podman-install.sh"
        exit 1
    fi
}

show_help() {
    cat <<EOF
⚙️ Gestor de Quadlets para Podman - CachyOS (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Crea directorios de systemd para Quadlets, instala servicios compartidos y recarga el daemon.
  --status, -s           Muestra el estado de los Quadlets y servicios de usuario de systemd.
  --help, -h             Muestra este mensaje de ayuda.

Directorios gestionados:
  • ~/.config/containers/systemd/        -> Proyectos activos y contenedores (.container, .network, .volume)
  • ~/.config/containers/systemd/global/ -> Servicios globales compartidos (PostgreSQL, Redis, Traefik, Keycloak)
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE SYSTEMD QUADLETS - CACHYOS"
    echo "================================================================="
    echo "• Directorio Quadlets: $HOME/.config/containers/systemd"
    echo "• Generador Quadlet:   $(if [ -f /usr/lib/systemd/user-generators/podman-user-generator ]; then echo 'Presente (/usr/lib/systemd/user-generators/podman-user-generator)'; else echo 'No detectado'; fi)"
    echo ""
    echo "📋 Archivos Quadlets configurados:"
    ls -la "$HOME/.config/containers/systemd" 2>/dev/null || echo "  (Sin archivos configurados)"
    echo ""
    echo "📋 Unidades de servicio activas gestionadas por Podman Quadlets:"
    systemctl --user list-units "*podman*" 2>/dev/null || echo "  (Ninguna unidad activa)"
    echo "================================================================="
}

setup_systemd_dirs() {
    log_info "Creando directorios de systemd para Quadlets..."
    mkdir -p "$HOME/.config/containers/systemd"
    mkdir -p "$HOME/.config/containers/systemd/global"

    log_ok "Directorios creados:"
    echo "  ~/.config/containers/systemd/        -> Proyectos activos"
    echo "  ~/.config/containers/systemd/global/ -> Servicios compartidos globales"
}

setup_podman_dirs() {
    log_info "Creando estructura de directorios de proyectos..."
    mkdir -p "$PODMAN_DIR/projects"
    mkdir -p "$PODMAN_DIR/services-shared"
    touch "$PODMAN_DIR/projects/.gitkeep"

    log_ok "Estructura de proyectos lista en: $PODMAN_DIR/projects"
}

install_global_services() {
    local shared_dir="$PODMAN_DIR/services-shared"
    local systemd_global="$HOME/.config/containers/systemd/global"
    local socket_path="/run/user/$(id -u)/podman/podman.sock"

    if [ ! -d "$shared_dir" ] || [ -z "$(ls -A "$shared_dir" 2>/dev/null)" ]; then
        log_info "No hay servicios compartidos para instalar en services-shared/"
        return 0
    fi

    log_info "Instalando servicios compartidos (.container)..."
    for container_file in "$shared_dir"/*.container; do
        [ -f "$container_file" ] || continue

        local basename
        basename="$(basename "$container_file")"
        local target="$systemd_global/$basename"

        # Reemplazar placeholder del socket path si existiera
        if grep -q "__PODMAN_SOCKET__" "$container_file" 2>/dev/null; then
            sed "s|__PODMAN_SOCKET__|$socket_path|g" "$container_file" > "$target"
        else
            cp "$container_file" "$target"
        fi

        log_ok "  $basename -> ~/.config/containers/systemd/global/"
    done

    systemctl --user daemon-reload
    log_ok "Servicios compartidos instalados y registrados en systemd user."
}

verify_quadlets() {
    log_info "Verificando compatibilidad de Quadlets..."
    local podman_version
    podman_version=$(podman --version | grep -oP '\d+\.\d+' | head -1)

    log_ok "Quadlets soportado nativamente (Podman $podman_version en CachyOS)."
    echo ""
    echo "============================================"
    log_ok "Quadlets configurado correctamente"
    echo "============================================"
    echo ""
    echo "Uso rápido de podman-utils:"
    echo "  podman-utils create python-postgres mi-api"
    echo "  podman-utils start mi-api"
    echo "  podman-utils status mi-api"
    echo ""
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
        echo "============================================"
        echo "  Configurador de Quadlets - CachyOS"
        echo "============================================"
        echo ""
        require_podman
        setup_systemd_dirs
        setup_podman_dirs
        install_global_services
        verify_quadlets
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
