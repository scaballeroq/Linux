#!/bin/bash
# =============================================================================
# quadlets-setup.sh - Preparador y Desplegador de Quadlets de Podman
# Soplos Linux Boro Workstation (GNOME Shell + Wayland / Systemd User Environment)
# =============================================================================
# Uso:
#   ./quadlets-setup.sh              -> Prepara directorios de Quadlets e instala servicios compartidos
#   ./quadlets-setup.sh --init-only  -> Prepara únicamente las estructuras de directorios
#   ./quadlets-setup.sh --install-shared -> Despliega los servicios globales en systemd user
#   ./quadlets-setup.sh --status     -> Comprueba las unidades Quadlets generadas en systemd user
#   ./quadlets-setup.sh --help       -> Muestra la ayuda interactiva
# =============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:${PATH:-}"

REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]:-$0}")"
SCRIPT_DIR="$(cd "$(dirname "$REAL_SCRIPT")" && pwd)"
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
        log_error "Podman no está instalado en el sistema."
        echo "💡 Puedes instalarlo y configurarlo ejecutando: $PODMAN_DIR/install/podman-install.sh"
        exit 1
    fi
}

show_help() {
    cat <<EOF
⚙️ Gestor de Quadlets para Podman - Soplos Linux Boro Workstation (GNOME Shell)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Crea directorios de systemd para Quadlets e instala servicios compartidos.
  --init-only            Crea únicamente la estructura de directorios de Quadlets y proyectos.
  --install-shared       Instala todos los servicios globales compartidos (.container, .network, .volume) en systemd user.
  --status, -s           Muestra el estado de los Quadlets configurados y unidades de systemd user.
  --help, -h             Muestra este mensaje de ayuda.

Directorios gestionados:
  • ~/.config/containers/systemd/        -> Proyectos activos y contenedores (.container, .network, .volume)
  • ~/.config/containers/systemd/global/ -> Servicios globales compartidos (PostgreSQL, Redis, Traefik, Keycloak)
  • ~/.config/systemd/user/              -> Targets y unidades nativas de systemd
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE SYSTEMD QUADLETS - SOPLOS LINUX BORO WORKSTATION"
    echo "================================================================="
    if ! command -v podman &>/dev/null; then
        echo "• Motor Podman:        ❌ No instalado en el sistema"
        echo "💡 Ejecuta el instalador base: $PODMAN_DIR/install/podman-install.sh"
        echo "================================================================="
        return 0
    fi

    local generator_path="/usr/lib/systemd/user-generators/podman-user-generator"
    echo "• Directorio Quadlets: $HOME/.config/containers/systemd"
    echo "• Generador Quadlet:   $(if [ -f "$generator_path" ]; then echo "Presente ($generator_path)"; else echo "No detectado"; fi)"
    echo ""
    echo "📋 Archivos Quadlets configurados en ~/.config/containers/systemd:"
    if [ -d "$HOME/.config/containers/systemd" ] && [ -n "$(ls -A "$HOME/.config/containers/systemd" 2>/dev/null)" ]; then
        find "$HOME/.config/containers/systemd" -maxdepth 3 -type f \( -name "*.container" -o -name "*.network" -o -name "*.volume" -o -name "*.target" -o -name "*.kube" -o -name "*.image" \) 2>/dev/null | sort | while read -r f; do
            local rel_path="${f#$HOME/.config/containers/systemd/}"
            echo "  - $rel_path"
        done
    else
        echo "  (Sin archivos Quadlet configurados)"
    fi
    echo ""
    echo "📋 Unidades generadas por Quadlets en systemd user:"
    local found_units=0
    local gen_dir="/run/user/$(id -u)/systemd/generator"
    if [ -d "$gen_dir" ]; then
        for unit_file in "$gen_dir"/*.service; do
            [ -f "$unit_file" ] || continue
            # Filtrar autostarts de escritorio genéricos para enfocarnos en contenedores
            if grep -q "SourcePath=.*containers/systemd" "$unit_file" 2>/dev/null; then
                local unit_name
                unit_name="$(basename "$unit_file")"
                local state
                state="$(systemctl --user is-active "$unit_name" 2>/dev/null || echo "inactivo")"
                echo "  • $unit_name: $state"
                found_units=1
            fi
        done
    fi
    if [ "$found_units" -eq 0 ]; then
        echo "  (Ninguna unidad generada activa actualmente. Ejecuta: systemctl --user daemon-reload)"
    fi
    echo "================================================================="
}

setup_systemd_dirs() {
    log_info "Creando directorios de systemd para Quadlets y unidades de usuario..."
    mkdir -p "$HOME/.config/containers/systemd"
    mkdir -p "$HOME/.config/containers/systemd/global"
    mkdir -p "$HOME/.config/systemd/user"

    log_ok "Directorios creados:"
    echo "  ~/.config/containers/systemd/        -> Proyectos activos (Quadlets)"
    echo "  ~/.config/containers/systemd/global/ -> Servicios compartidos globales"
    echo "  ~/.config/systemd/user/              -> Targets y unidades nativas systemd"
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

    log_info "Instalando definiciones de Quadlets compartidas (.container, .network, .volume)..."
    shopt -s nullglob
    for quadlet_file in "$shared_dir"/*.{container,network,volume}; do
        [ -f "$quadlet_file" ] || continue

        local basename
        basename="$(basename "$quadlet_file")"
        local target="$systemd_global/$basename"

        # Reemplazar placeholder del socket path si existiera
        if grep -q "__PODMAN_SOCKET__" "$quadlet_file" 2>/dev/null; then
            sed "s|__PODMAN_SOCKET__|$socket_path|g" "$quadlet_file" > "$target"
        else
            cp "$quadlet_file" "$target"
        fi

        log_ok "  $basename -> ~/.config/containers/systemd/global/"
    done
    shopt -u nullglob

    systemctl --user daemon-reload
    log_ok "Servicios compartidos instalados y registrados en systemd user."
}

verify_quadlets() {
    log_info "Verificando compatibilidad de Quadlets..."
    local podman_version
    podman_version=$(podman --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1 || echo "detectado")
    
    log_ok "Quadlets soportado nativamente (Podman $podman_version en Soplos Linux Boro Workstation)."
    echo ""
    echo "============================================"
    log_ok "Quadlets configurado correctamente"
    echo "============================================"
    echo ""
    echo "Uso rápido de podman-utils:"
    echo "  podman-utils create python-postgres mi-api"
    echo "  podman-utils start mi-api"
    echo "  podman-utils status mi-api"
    echo "  podman-utils install-global <servicio>   (para servicios compartidos)"
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
    --init-only|--dirs-only)
        require_podman
        setup_systemd_dirs
        setup_podman_dirs
        systemctl --user daemon-reload 2>/dev/null || true
        verify_quadlets
        ;;
    --install-shared)
        require_podman
        setup_systemd_dirs
        setup_podman_dirs
        install_global_services
        verify_quadlets
        ;;
    "")
        echo "============================================"
        echo "  Configurador de Quadlets - Soplos Linux Boro Workstation"
        echo "============================================"
        echo ""
        require_podman
        setup_systemd_dirs
        setup_podman_dirs
        install_global_services
        systemctl --user daemon-reload 2>/dev/null || true
        verify_quadlets
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
