#!/bin/bash
# =============================================================================
# Podman Professional Installation - Omarchy / Arch Linux
# =============================================================================
# Instala Podman rootless con todas las dependencias necesarias para
# usar Quadlets (integración systemd).
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }

require_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Este script NO debe ejecutarse como root."
        log_error "Podman rootless se instala como usuario normal."
        exit 1
    fi
}

check_system() {
    if [ ! -f /etc/arch-release ] && ! grep -qiE "ID(=|_LIKE=).*(arch|omarchy)" /etc/os-release 2>/dev/null; then
        log_error "Este script solo soporta Omarchy / Arch Linux."
        exit 1
    fi
}

install_podman() {
    if command -v podman &>/dev/null; then
        log_ok "Podman ya está instalado: $(podman --version)"
        return 0
    fi

    log_info "Instalando Podman y dependencias para Arch Linux / Omarchy..."
    sudo pacman -S --needed --noconfirm \
        podman \
        podman-compose \
        netavark \
        aardvark-dns \
        slirp4netns \
        passt \
        fuse-overlayfs

    log_ok "Podman instalado: $(podman --version)"
}

configure_storage() {
    log_info "Configurando almacenamiento (overlay)..."

    local storage_conf="$HOME/.config/containers/storage.conf"
    mkdir -p "$(dirname "$storage_conf")"

    if [ ! -f "$storage_conf" ]; then
        cat > "$storage_conf" <<'EOF'
[storage]
driver = "overlay"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF
        log_ok "storage.conf creado"
    else
        log_info "storage.conf ya existe, se mantiene"
    fi

    if ! command -v fuse-overlayfs &>/dev/null; then
        log_info "Instalando fuse-overlayfs..."
        sudo pacman -S --needed --noconfirm fuse-overlayfs
    fi
}

configure_registries() {
    log_info "Configurando registros de imágenes..."

    local registries_conf="$HOME/.config/containers/registries.conf"
    mkdir -p "$(dirname "$registries_conf")"

    if [ ! -f "$registries_conf" ]; then
        cat > "$registries_conf" <<'EOF'
unqualified-search-registries = ["docker.io", "quay.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"
EOF
        log_ok "registries.conf creado"
    else
        log_info "registries.conf ya existe, se mantiene"
    fi
}

enable_linger() {
    log_info "Habilitando linger para contenedores persistentes..."
    loginctl enable-linger "$USER"
    log_ok "Linger habilitado"
}

configure_subuids() {
    log_info "Ajustando límites de recursos (subuid/subgid)..."
    if ! grep -q "$USER" /etc/subuid 2>/dev/null; then
        sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER" 2>/dev/null || true
        log_ok "subuid/subgid asignados a $USER"
    else
        log_info "subuid/subgid ya están configurados"
    fi
}

enable_podman_socket() {
    log_info "Habilitando socket de Podman (compatibilidad Docker)..."
    systemctl --user enable --now podman.socket 2>/dev/null || true
    log_ok "Socket de Podman habilitado"
}

configure_docker_host() {
    local export_line='export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"'
    local bashrc_d="$HOME/.bashrc.d/podman.sh"

    if [ -d "$HOME/.bashrc.d" ] || [ -d /etc/bashrc.d ]; then
        mkdir -p "$HOME/.bashrc.d"
        if [ ! -f "$bashrc_d" ]; then
            echo "$export_line" > "$bashrc_d"
            log_ok "DOCKER_HOST configurado en ~/.bashrc.d/podman.sh"
        elif ! grep -q "DOCKER_HOST=" "$bashrc_d" 2>/dev/null; then
            echo "$export_line" >> "$bashrc_d"
            log_ok "DOCKER_HOST añadido a ~/.bashrc.d/podman.sh"
        fi
    else
        if ! grep -q "DOCKER_HOST=" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# Podman Docker Host" >> "$HOME/.bashrc"
            echo "$export_line" >> "$HOME/.bashrc"
            log_ok "DOCKER_HOST añadido a ~/.bashrc"
        fi
    fi

    # Soporte para Zsh si existe ~/.zshrc
    local zshrc="$HOME/.zshrc"
    if [ -f "$zshrc" ] || [ "${SHELL##*/}" = "zsh" ]; then
        if ! grep -q "DOCKER_HOST=" "$zshrc" 2>/dev/null; then
            echo "" >> "$zshrc"
            echo "# Podman Docker Host" >> "$zshrc"
            echo "$export_line" >> "$zshrc"
            log_ok "DOCKER_HOST añadido a ~/.zshrc"
        fi
    fi
}

configure_network() {
    log_info "Verificando configuración de red..."

    local netavark_conf="$HOME/.config/containers/containers.conf"
    mkdir -p "$(dirname "$netavark_conf")"

    if [ ! -f "$netavark_conf" ]; then
        cat > "$netavark_conf" <<'EOF'
[containers]
netns = "private"

[network]
default_network = "podman"
EOF
        log_ok "containers.conf creado"
    fi
}

verify_installation() {
    log_info "Verificando instalación..."

    if ! podman info &>/dev/null; then
        log_error "Podman no funciona correctamente. Ejecuta 'podman info' para diagnosticar."
        exit 1
    fi

    log_ok "Podman funciona correctamente"
    echo ""
    echo "============================================"
    log_ok "Podman instalado y configurado para Omarchy"
    echo "============================================"
    echo ""
    echo "Siguientes pasos:"
    echo "  1. Reinicia tu terminal o ejecuta: source ~/.bashrc"
    echo "  2. Configura Quadlets: ./install/quadlets-setup.sh"
    echo ""
}

main() {
    echo "============================================"
    echo "  Podman Professional Installation (Omarchy)"
    echo "============================================"
    echo ""

    require_root
    check_system

    install_podman
    configure_storage
    configure_registries
    configure_network
    enable_linger
    configure_subuids
    enable_podman_socket
    configure_docker_host
    verify_installation
}

main "$@"
