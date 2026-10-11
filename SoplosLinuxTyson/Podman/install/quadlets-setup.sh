#!/bin/bash
# =============================================================================
# Quadlets Setup - Configuración de systemd para Soplos Linux Tyson
# =============================================================================
# Crea la estructura de directorios necesaria para que systemd gestione
# contenedores Podman de forma nativa mediante Quadlets (.container, .network, .volume).
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

    log_ok "Directorio de Quadlets listo: ~/.config/containers/systemd/"
}

setup_podman_dirs() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    log_info "Creando estructura de directorios de proyectos..."

    mkdir -p "$script_dir/projects"
    mkdir -p "$script_dir/services-shared"

    touch "$script_dir/projects/.gitkeep"

    log_ok "Estructura de proyectos lista en: $script_dir"
}

verify_quadlets() {
    log_info "Verificando compatibilidad de Quadlets..."

    local podman_version
    podman_version=$(podman --version | grep -oP '\d+\.\d+' | head -1 || echo "5.0")
    local major
    major=$(echo "$podman_version" | cut -d. -f1)

    if [ "$major" -lt 4 ]; then
        log_error "Quadlets requiere Podman 4.0+. Tu versión: $podman_version"
        exit 1
    fi

    log_ok "Quadlets soportado (Podman $podman_version)"
    echo ""
    echo "============================================================"
    log_ok "Quadlets configurado correctamente para Soplos Linux"
    echo "============================================================"
    echo ""
    echo "Uso recomendado:"
    echo "  export PATH=\"$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd):\$PATH\""
    echo ""
    echo "Comandos disponibles:"
    echo "  podman-utils list-templates"
    echo "  podman-utils create python-postgres mi-api"
    echo "  podman-utils start mi-api"
    echo ""
}

main() {
    echo "============================================================"
    echo "  Configuración de Quadlets - Soplos Linux Tyson"
    echo "============================================================"
    echo ""

    require_podman

    setup_systemd_dirs
    setup_podman_dirs
    systemctl --user daemon-reload 2>/dev/null || true
    verify_quadlets
}

main "$@"
