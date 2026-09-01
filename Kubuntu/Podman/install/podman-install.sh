#!/bin/bash
# =============================================================================
# podman-install.sh - Configuración de Podman Rootless + Socket + Quadlets
# =============================================================================
# Optimizado para Kubuntu 26.04.1 LTS (KDE Plasma 6 / Wayland)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

require_non_root() {
    if [ "$EUID" -eq 0 ]; then
        echo "❌ Error: Este script NO debe ejecutarse como root ni con sudo."
        echo "   Ejecútalo como usuario normal: ./install/podman-install.sh"
        exit 1
    fi
}

show_help() {
    cat <<EOF
Configurador de Podman Rootless - Kubuntu 26.04.1 LTS

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Configura Podman rootless, socket, linger, registries, dev-net y environment.d.
  --status, -s           Muestra el estado del motor Podman, socket, linger, DOCKER_HOST y red.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE PODMAN ROOTLESS - KUBUNTU 26.04.1 LTS"
    echo "================================================================="
    if command -v podman &>/dev/null; then
        echo "Podman instalado:      $(podman --version 2>/dev/null)"
        echo "Socket de Usuario:     $(systemctl --user is-active podman.socket 2>/dev/null || echo 'inactivo')"
        echo "Socket Path:           /run/user/$(id -u)/podman/podman.sock"
        echo "Linger de Usuario:     $(loginctl show-user "$USER" 2>/dev/null | grep -i "Linger=" | cut -d= -f2 || echo 'no')"
        echo "Driver Storage:        $(podman info --format '{{.Store.GraphDriverName}}' 2>/dev/null || echo 'overlay')"
        echo "Red de Desarrollo:     $(podman network exists dev-net 2>/dev/null && echo 'dev-net (Activa)' || echo 'dev-net (No creada)')"
        echo "Podman Compose:        $(command -v podman-compose &>/dev/null && echo 'Instalado' || echo 'No instalado')"
        echo "DOCKER_HOST actual:    ${DOCKER_HOST:-No exportado en la sesión actual}"
    else
        echo "Podman:                No instalado"
    fi
    echo "================================================================="
}

install_packages() {
    echo "ℹ️ [1/9] Verificando paquetes de Podman..."
    if ! command -v podman &>/dev/null; then
        sudo apt update
        sudo apt install -y podman podman-compose podman-docker uidmap slirp4netns passt dbus-user-session
    else
        echo "   - Podman ya instalado."
    fi
}

configure_storage() {
    echo "ℹ️ [2/9] Configurando almacenamiento de contenedores (overlay)..."
    local storage_conf="$HOME/.config/containers/storage.conf"
    mkdir -p "$(dirname "$storage_conf")"

    if [ ! -f "$storage_conf" ]; then
        cat <<'EOF' > "$storage_conf"
[storage]
driver = "overlay"

[storage.options]
pull_options = {enable_partial_images = "true", use_hard_links = "false", ostree_repos = ""}
EOF
        echo "   - storage.conf creado."
    else
        echo "   - storage.conf ya configurado."
    fi
}

configure_registries() {
    echo "ℹ️ [3/9] Configurando registros de imágenes..."
    local registries_conf="$HOME/.config/containers/registries.conf"
    mkdir -p "$(dirname "$registries_conf")"

    if [ ! -f "$registries_conf" ]; then
        cat <<'EOF' > "$registries_conf"
unqualified-search-registries = ["docker.io", "quay.io", "ghcr.io"]
EOF
        echo "   - registries.conf creado."
    else
        echo "   - registries.conf ya configurado."
    fi
}

enable_linger() {
    echo "ℹ️ [4/9] Habilitando persistencia de usuario (systemd linger)..."
    loginctl enable-linger "$USER" 2>/dev/null || true
    echo "   - Linger activo."
}

configure_subuids() {
    echo "ℹ️ [5/9] Verificando mapeo subuid y subgid..."
    if ! grep -q "^$USER:" /etc/subuid 2>/dev/null; then
        sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER" 2>/dev/null || true
        echo "   - subuid/subgid asignados para '$USER'."
    else
        echo "   - subuid/subgid ya configurados."
    fi
}

enable_podman_socket() {
    echo "ℹ️ [6/9] Habilitando podman.socket (emulación Docker API)..."
    systemctl --user enable --now podman.socket 2>/dev/null || true
    echo "   - Socket activo en /run/user/$(id -u)/podman/podman.sock."
}

configure_docker_host() {
    echo "ℹ️ [7/9] Configurando integración DOCKER_HOST..."
    local socket_path="/run/user/$(id -u)/podman/podman.sock"

    mkdir -p "$HOME/.config/environment.d"
    cat <<EOF > "$HOME/.config/environment.d/10-podman.conf"
DOCKER_HOST=unix://$socket_path
EOF

    mkdir -p "$HOME/.bashrc.d"
    cat <<EOF > "$HOME/.bashrc.d/podman.sh"
# Podman Docker API Integration
if [ -S "$socket_path" ]; then
    export DOCKER_HOST="unix://$socket_path"
fi
EOF

    if ! grep -q "DOCKER_HOST=" "$HOME/.bashrc" 2>/dev/null; then
        echo -e "\n# Podman Docker API Integration\nif [ -S \"$socket_path\" ]; then export DOCKER_HOST=\"unix://$socket_path\"; fi" >> "$HOME/.bashrc"
    fi

    echo "   - DOCKER_HOST integrado en KDE Plasma y Bash."
}

create_default_network() {
    echo "ℹ️ [8/9] Configurando red compartida de desarrollo (dev-net)..."
    if command -v podman &>/dev/null; then
        if ! podman network exists dev-net 2>/dev/null; then
            podman network create dev-net 2>/dev/null || true
            echo "   - Red 'dev-net' creada correctamente."
        else
            echo "   - Red 'dev-net' ya existe."
        fi
    fi
}

setup_quadlets_and_cli() {
    echo "ℹ️ [9/9] Configurando CLI podman-utils y Quadlets..."
    mkdir -p "$HOME/.local/bin"
    if [ -f "$PODMAN_ROOT/lib/podman-utils.sh" ]; then
        chmod +x "$PODMAN_ROOT/lib/podman-utils.sh"
        ln -sf "$PODMAN_ROOT/lib/podman-utils.sh" "$HOME/.local/bin/podman-utils"
        echo "   - Symlink creado: ~/.local/bin/podman-utils"
    fi

    if [ -f "$SCRIPT_DIR/quadlets-setup.sh" ]; then
        chmod +x "$SCRIPT_DIR/quadlets-setup.sh"
        bash "$SCRIPT_DIR/quadlets-setup.sh"
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
        echo "CONFIGURANDO PODMAN ROOTLESS - KUBUNTU 26.04.1 LTS"
        echo "================================================================="
        require_non_root
        install_packages
        configure_storage
        configure_registries
        enable_linger
        configure_subuids
        enable_podman_socket
        configure_docker_host
        create_default_network
        setup_quadlets_and_cli
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Podman Rootless y Quadlets configurados con éxito."
        echo "================================================================="
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
