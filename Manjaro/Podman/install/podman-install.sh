#!/bin/bash
# =============================================================================
# Podman Installation - Manjaro Linux (Arch-based)
# =============================================================================
# Instala Podman rootless con todas las dependencias necesarias para
# usar Quadlets (systemd integration).
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }

require_non_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Este script NO debe ejecutarse como root con sudo."
        log_error "Podman rootless se instala como usuario normal (el script pedirá sudo cuando lo requiera)."
        exit 1
    fi
}

install_podman() {
    if command -v podman &>/dev/null; then
        log_ok "Podman ya está instalado: $(podman --version)"
        return 0
    fi

    log_info "Instalando Podman y dependencias vía Pacman..."
    sudo pacman -S --needed --noconfirm \
        podman \
        podman-compose \
        podman-docker \
        shadow \
        slirp4netns \
        passt \
        cni-plugins \
        fuse-overlayfs \
        netavark \
        aardvark-dns

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
}

configure_registries() {
    log_info "Configurando registros de imagenes..."

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
    fi
}

configure_unprivileged_ports() {
    log_info "Configurando puertos no privilegiados (>=80) para rootless..."

    local sysctl_conf="/etc/sysctl.d/99-podman-ports.conf"
    if [ ! -f "$sysctl_conf" ] || ! grep -q "ip_unprivileged_port_start=80" "$sysctl_conf" 2>/dev/null; then
        echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee "$sysctl_conf" >/dev/null
        sudo sysctl --system >/dev/null 2>&1 || true
        log_ok "Puertos >=80 configurados para Podman rootless (HTTP/HTTPS)"
    else
        log_info "Puertos rootless ya configurados"
    fi
}

enable_linger() {
    local current_user
    current_user="$(id -un)"
    log_info "Habilitando linger para contenedores persistentes ($current_user)..."
    loginctl enable-linger "$current_user" 2>/dev/null || sudo loginctl enable-linger "$current_user" || true
    log_ok "Linger habilitado para $current_user"
}

configure_subuid_subgid() {
    local current_user
    current_user="$(id -un)"
    log_info "Configurando subuid y subgid..."

    if ! grep -q "^$current_user:" /etc/subuid 2>/dev/null; then
        echo "$current_user:100000:65536" | sudo tee -a /etc/subuid >/dev/null
        log_ok "subuid configurado"
    else
        log_info "subuid ya configurado"
    fi

    if ! grep -q "^$current_user:" /etc/subgid 2>/dev/null; then
        echo "$current_user:100000:65536" | sudo tee -a /etc/subgid >/dev/null
        log_ok "subgid configurado"
    else
        log_info "subgid ya configurado"
    fi
}

enable_socket() {
    log_info "Habilitando socket de Podman para el usuario..."
    systemctl --user enable --now podman.socket
    log_ok "podman.socket activo en: /run/user/$(id -u)/podman/podman.sock"
}

configure_shell_env() {
    log_info "Configurando variables de entorno DOCKER_HOST para Bash y ZSH..."

    mkdir -p "$HOME/.bashrc.d" "$HOME/.zshrc.d"

    cat <<'EOF' > "$HOME/.bashrc.d/podman.sh"
# Configurar DOCKER_HOST para apuntar al socket rootless de Podman
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
EOF

    cat <<'EOF' > "$HOME/.zshrc.d/podman.zsh"
# Configurar DOCKER_HOST para apuntar al socket rootless de Podman
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
EOF

    log_ok "DOCKER_HOST configurado en ~/.bashrc.d/ y ~/.zshrc.d/"
}

verify_installation() {
    log_info "Verificando instalacion..."

    if ! podman info &>/dev/null; then
        log_error "podman info fallo. Comprueba la configuracion rootless."
        exit 1
    fi

    log_ok "Podman rootless verificado correctamente"
    echo ""
    echo "============================================"
    log_ok "Instalacion completada con exito"
    echo "============================================"
    echo ""
    echo "Siguiente paso:"
    echo "  ./install/quadlets-setup.sh"
    echo ""
}

main() {
    echo "============================================"
    echo "  Instalacion de Podman en Manjaro Linux"
    echo "============================================"
    echo ""

    require_non_root
    install_podman
    configure_subuid_subgid
    configure_unprivileged_ports
    configure_storage
    configure_registries
    enable_linger
    enable_socket
    configure_shell_env
    verify_installation
}

main "$@"
