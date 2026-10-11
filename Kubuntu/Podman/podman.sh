#!/bin/bash
# =============================================================================
# podman.sh - Instalador y Configurador de Podman Rootless + Quadlets para Kubuntu
# =============================================================================
# Optimizado para Kubuntu 26.04.1 LTS (KDE Plasma 6 / Wayland)
# - Instala Podman, podman-compose, emulación docker y pasta (passt)
# - Configura subuid/subgid, almacenamiento overlay y registries seguros
# - Activa persistencia de usuario (systemd linger) y podman.socket
# - Integra DOCKER_HOST en ~/.bashrc.d y ~/.config/environment.d
# - Configura red compartida dev-net y CLI podman-utils
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -eq 0 ]; then
    echo "❌ Error: Este script debe ejecutarse como tu usuario normal (no con sudo ni como root)."
    echo "   El script solicitará sudo internamente cuando sea estrictamente necesario."
    exit 1
fi

REAL_USER="$USER"
USER_HOME="$HOME"
USER_UID="$(id -u)"
SOCKET_PATH="/run/user/$USER_UID/podman/podman.sock"

show_help() {
    cat <<EOF
Instalador y Configurador de Podman Rootless - Kubuntu 26.04.1 LTS

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala y configura el stack completo de Podman rootless, socket y Quadlets.
  --status, -s           Muestra el diagnóstico detallado del motor Podman, socket y redes.
  --quadlets, -q         Configura o reinstala únicamente los servicios Systemd Quadlets.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE PODMAN ROOTLESS - KUBUNTU 26.04.1 LTS"
    echo "================================================================="
    if command -v podman &>/dev/null; then
        echo "Versión Podman:        $(podman --version 2>/dev/null)"
        echo "Socket de Usuario:     $(systemctl --user is-active podman.socket 2>/dev/null || echo 'inactivo')"
        echo "Socket Path:           $SOCKET_PATH"
        echo "Linger de Usuario:     $(loginctl show-user "$REAL_USER" 2>/dev/null | grep -i "Linger=" | cut -d= -f2 || echo 'no')"
        echo "Driver Storage:        $(podman info --format '{{.Store.GraphDriverName}}' 2>/dev/null || echo 'overlay')"
        echo "Red de Desarrollo:     $(podman network exists dev-net 2>/dev/null && echo 'dev-net (Activa)' || echo 'dev-net (No creada)')"
        echo "Podman Compose:        $(command -v podman-compose &>/dev/null && echo 'Instalado' || echo 'No instalado')"
        echo "CLI podman-utils:      $(command -v podman-utils &>/dev/null && echo 'Instalado (~/.local/bin/podman-utils)' || echo 'No instalado')"
        echo "DOCKER_HOST actual:    ${DOCKER_HOST:-No exportado en la sesión actual}"
    else
        echo "Podman:                No instalado"
    fi
    echo "================================================================="
}

install_and_configure() {
    echo "================================================================="
    echo "CONFIGURANDO PODMAN ROOTLESS - KUBUNTU (KDE PLASMA 6)"
    echo "================================================================="

    # 1. Delegar en podman-install.sh
    if [ -f "$SCRIPT_DIR/install/podman-install.sh" ]; then
        bash "$SCRIPT_DIR/install/podman-install.sh"
    else
        echo "❌ Error: No se encontró install/podman-install.sh"
        exit 1
    fi
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
    --quadlets|-q)
        if [ -f "$SCRIPT_DIR/install/quadlets-setup.sh" ]; then
            bash "$SCRIPT_DIR/install/quadlets-setup.sh"
        fi
        ;;
    "")
        install_and_configure
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
