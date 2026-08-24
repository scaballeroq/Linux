#!/bin/bash
# =============================================================================
# Quadlets Setup - Configura systemd para gestionar contenedores (Omarchy)
# =============================================================================
# Crea la estructura de directorios necesaria para que systemd gestione
# contenedores Podman mediante archivos .container (Quadlets).
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }

require_podman() {
    if ! command -v podman &>/dev/null; then
        log_error "Podman no está instalado. Ejecuta primero: ./install/podman-install.sh"
        exit 1
    fi
}

setup_systemd_dirs() {
    log_info "Creando directorios de systemd para Quadlets..."

    mkdir -p "$HOME/.config/containers/systemd"
    mkdir -p "$HOME/.config/containers/systemd/global"

    log_ok "Directorios creados:"
    echo "  ~/.config/containers/systemd/        -> proyectos activos"
    echo "  ~/.config/containers/systemd/global/  -> servicios compartidos"
}

setup_podman_dirs() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    log_info "Creando estructura de directorios de proyectos..."

    mkdir -p "$script_dir/projects"
    mkdir -p "$script_dir/services-shared"

    touch "$script_dir/projects/.gitkeep"

    log_ok "Estructura lista en: $script_dir"
}

install_global_services() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local shared_dir="$script_dir/services-shared"
    local systemd_global="$HOME/.config/containers/systemd/global"
    local socket_path="/run/user/$(id -u)/podman/podman.sock"

    if [ ! -d "$shared_dir" ] || [ -z "$(ls -A "$shared_dir" 2>/dev/null)" ]; then
        log_info "No hay servicios compartidos para instalar"
        return 0
    fi

    log_info "Instalando servicios compartidos..."

    for container_file in "$shared_dir"/*.container; do
        [ -f "$container_file" ] || continue

        local basename
        basename="$(basename "$container_file")"
        local target="$systemd_global/$basename"

        # Reemplazar placeholder del socket path
        if grep -q "__PODMAN_SOCKET__" "$container_file" 2>/dev/null; then
            sed "s|__PODMAN_SOCKET__|$socket_path|g" "$container_file" > "$target"
        else
            cp "$container_file" "$target"
        fi

        log_ok "  $basename -> global/"
    done

    systemctl --user daemon-reload
    log_ok "Servicios compartidos instalados (detenidos por defecto)"
}

verify_quadlets() {
    log_info "Verificando Quadlets..."

    local podman_version
    podman_version=$(podman --version | grep -oP '\d+\.\d+' | head -1)
    local major
    major=$(echo "$podman_version" | cut -d. -f1)

    if [ "$major" -lt 4 ]; then
        log_error "Quadlets requiere Podman 4.0+. Tu versión: $podman_version"
        exit 1
    fi

    log_ok "Quadlets soportado (Podman $podman_version)"
    echo ""
    echo "============================================"
    log_ok "Quadlets configurado correctamente"
    echo "============================================"
    echo ""
    echo "Uso:"
    echo "  export PATH=\"$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd):\$PATH\""
    echo "  podman-utils create python-postgres mi-api"
    echo "  podman-utils start mi-api"
    echo ""
}

main() {
    echo "============================================"
    echo "  Quadlets Setup (Omarchy)"
    echo "============================================"
    echo ""

    require_podman

    setup_systemd_dirs
    setup_podman_dirs
    install_global_services
    verify_quadlets
}

main "$@"
