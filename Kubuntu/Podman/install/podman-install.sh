#!/bin/bash
# podman-install.sh - Configuracion de Podman Rootless + Socket + Quadlets para Kubuntu

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

require_non_root() {
    if [ "$EUID" -eq 0 ]; then
        echo "Error: Este script NO debe ejecutarse como root."
        exit 1
    fi
}

show_help() {
    cat <<EOF
Configurador de Podman Rootless - Kubuntu (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Configura Podman rootless, socket, linger, registries, environment.d.
  --status, -s           Muestra el estado del motor Podman, socket, linger, DOCKER_HOST.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE PODMAN ROOTLESS - KUBUNTU"
    echo "================================================================="
    if command -v podman &>/dev/null; then
        echo "Podman instalado:    $(podman --version 2>/dev/null)"
        echo "Socket de Usuario:   $(systemctl --user is-active podman.socket 2>/dev/null || echo 'inactivo')"
        echo "Socket Path:         /run/user/$(id -u)/podman/podman.sock"
        echo "Linger de Usuario:   $(loginctl show-user "$USER" 2>/dev/null | grep -i "Linger=" | cut -d= -f2 || echo 'no')"
        echo "Driver Storage:      $(podman info --format '{{.Store.GraphDriverName}}' 2>/dev/null || echo 'overlay')"
        echo "Podman Compose:      $(command -v podman-compose &>/dev/null && echo 'Instalado' || echo 'No instalado')"
        echo "DOCKER_HOST actual:  ${DOCKER_HOST:-No exportado}"
    else
        echo "Podman:              No instalado"
    fi
    echo "================================================================="
}

install_packages() {
    echo "Verificando paquetes de Podman..."
    if ! command -v podman &>/dev/null; then
        sudo apt update
        sudo apt install -y podman podman-compose podman-docker uidmap slirp4netns passt
    else
        echo "Podman ya instalado."
    fi
}

configure_storage() {
    echo "Configurando almacenamiento de contenedores..."
    local storage_conf="$HOME/.config/containers/storage.conf"
    mkdir -p "$(dirname "$storage_conf")"

    if [ ! -f "$storage_conf" ]; then
        cat <<'EOF' > "$storage_conf"
[storage]
driver = "overlay"

[storage.options]
pull_options = {enable_partial_images = "true", use_hard_links = "false", ostree_repos = ""}
EOF
        echo "storage.conf configurado."
    else
        echo "storage.conf ya existe."
    fi
}

configure_registries() {
    echo "Configurando registros de imagenes..."
    local registries_conf="$HOME/.config/containers/registries.conf"
    mkdir -p "$(dirname "$registries_conf")"

    if [ ! -f "$registries_conf" ]; then
        cat <<'EOF' > "$registries_conf"
unqualified-search-registries = ["docker.io", "quay.io", "ghcr.io"]
EOF
        echo "registries.conf configurado."
    fi
}

enable_linger() {
    echo "Habilitando persistencia de usuario (linger)..."
    loginctl enable-linger "$USER" 2>/dev/null || true
    echo "Linger activo."
}

configure_subuids() {
    echo "Verificando subuid y subgid..."
    if ! grep -q "^$USER:" /etc/subuid 2>/dev/null; then
        sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER" 2>/dev/null || true
        echo "subuid/subgid asignados."
    else
        echo "subuid/subgid ya configurados."
    fi
}

enable_podman_socket() {
    echo "Habilitando podman.socket..."
    systemctl --user enable --now podman.socket 2>/dev/null || true
    echo "Socket activo en /run/user/$(id -u)/podman/podman.sock."
}

configure_docker_host() {
    echo "Configurando DOCKER_HOST..."
    local socket_path="/run/user/$(id -u)/podman/podman.sock"

    mkdir -p "$HOME/.config/environment.d"
    cat <<EOF > "$HOME/.config/environment.d/10-podman.conf"
DOCKER_HOST=unix://$socket_path
EOF

    mkdir -p "$HOME/.bashrc.d"
    cat <<EOF > "$HOME/.bashrc.d/podman.sh"
# Podman Docker API Integration
export DOCKER_HOST="unix://$socket_path"
EOF

    if ! grep -q "DOCKER_HOST=" "$HOME/.bashrc" 2>/dev/null; then
        echo -e "\n# Podman Docker API Integration\nexport DOCKER_HOST=\"unix://$socket_path\"" >> "$HOME/.bashrc"
    fi

    echo "DOCKER_HOST integrado en KDE Plasma y shell."
}

setup_podman_utils_cli() {
    echo "Configurando CLI podman-utils..."
    mkdir -p "$HOME/.local/bin"
    if [ -f "$PODMAN_ROOT/lib/podman-utils.sh" ]; then
        chmod +x "$PODMAN_ROOT/lib/podman-utils.sh"
        ln -sf "$PODMAN_ROOT/lib/podman-utils.sh" "$HOME/.local/bin/podman-utils"
        echo "Symlink creado: ~/.local/bin/podman-utils"
    fi
}

setup_quadlets() {
    echo "Configurando Quadlets..."
    if [ -f "$SCRIPT_DIR/quadlets-setup.sh" ]; then
        chmod +x "$SCRIPT_DIR/quadlets-setup.sh"
        "$SCRIPT_DIR/quadlets-setup.sh"
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
    "")
        echo "================================================================="
        echo "CONFIGURANDO PODMAN ROOTLESS - KUBUNTU (KDE PLASMA 6)"
        echo "================================================================="
        require_non_root
        install_packages
        configure_storage
        configure_registries
        enable_linger
        configure_subuids
        enable_podman_socket
        configure_docker_host
        setup_podman_utils_cli
        setup_quadlets
        echo ""
        show_status
        echo "================================================================="
        echo "Podman Rootless y Quadlets configurados con exito."
        echo "================================================================="
        ;;
    *)
        echo "Opcion no reconocida: $1"
        show_help
        exit 1
        ;;
esac
