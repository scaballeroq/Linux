#!/bin/bash
# =============================================================================
# Podman Professional Installation - Soplos Linux Tyson (Debian Testing / Trixie)
# =============================================================================
# Instala Podman rootless con todas las dependencias necesarias para
# usar Quadlets (integración nativa con systemd).
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

require_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Este script NO debe ejecutarse como root."
        log_error "Podman rootless se instala y configura como usuario normal (solicitará sudo cuando sea necesario)."
        exit 1
    fi
}

check_debian() {
    if [ ! -f /etc/debian_version ]; then
        log_error "Este script solo soporta Debian / Soplos Linux Tyson."
        exit 1
    fi
}

install_podman() {
    log_info "Actualizando índices de repositorios..."
    sudo apt update -qq

    log_info "Instalando Podman, Netavark, Quadlets y dependencias para Debian Testing..."
    sudo apt install -y \
        podman \
        podman-compose \
        podman-docker \
        uidmap \
        slirp4netns \
        passt \
        netavark \
        aardvark-dns \
        containernetworking-plugins \
        fuse-overlayfs \
        crun \
        catatonit \
        dbus-user-session \
        curl \
        jq

    log_ok "Podman instalado: $(podman --version 2>/dev/null || echo 'instalado')"
}

configure_storage() {
    log_info "Configurando almacenamiento de contenedores (overlay)..."

    local storage_conf="$HOME/.config/containers/storage.conf"
    mkdir -p "$(dirname "$storage_conf")"

    if [ ! -f "$storage_conf" ]; then
        cat > "$storage_conf" <<'EOF'
[storage]
driver = "overlay"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
mountopt = "nodev,metacopy=on"
EOF
        log_ok "storage.conf creado"
    else
        log_info "storage.conf ya existe, se mantiene"
    fi
}

configure_registries() {
    log_info "Configurando registros de imágenes predeterminados..."

    local registries_conf="$HOME/.config/containers/registries.conf"
    mkdir -p "$(dirname "$registries_conf")"

    if [ ! -f "$registries_conf" ]; then
        cat > "$registries_conf" <<'EOF'
unqualified-search-registries = ["docker.io", "quay.io", "ghcr.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry]]
prefix = "quay.io"
location = "quay.io"

[[registry]]
prefix = "ghcr.io"
location = "ghcr.io"
EOF
        log_ok "registries.conf creado"
    else
        log_info "registries.conf ya existe, se mantiene"
    fi
}

enable_linger() {
    log_info "Habilitando loginctl linger para persistencia de servicios de usuario..."
    if command -v loginctl &>/dev/null; then
        loginctl enable-linger "$USER" 2>/dev/null || sudo loginctl enable-linger "$USER" 2>/dev/null || true
        log_ok "Linger habilitado para el usuario '$USER'"
    fi
}

configure_subuids() {
    log_info "Verificando mapeo de subuid/subgid..."
    local user_entry
    user_entry=$(grep -E "^${USER}:" /etc/subuid 2>/dev/null || true)

    if [ -z "$user_entry" ]; then
        log_info "Asignando rango de subuid/subgid para $USER..."
        sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER" 2>/dev/null || {
            echo "$USER:100000:65536" | sudo tee -a /etc/subuid >/dev/null
            echo "$USER:100000:65536" | sudo tee -a /etc/subgid >/dev/null
        }
        podman system migrate 2>/dev/null || true
        log_ok "subuid/subgid asignados correctamente"
    else
        log_ok "subuid/subgid ya configurados: $user_entry"
    fi
}

enable_podman_socket() {
    log_info "Habilitando socket de Podman en systemd (compatibilidad API Docker)..."
    systemctl --user enable --now podman.socket 2>/dev/null || true
    log_ok "Socket de Podman habilitado"
}

configure_docker_host() {
    local export_line='export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"'
    local bashrc_d="$HOME/.bashrc.d/podman.sh"

    if [ -d "$HOME/.bashrc.d" ]; then
        if [ ! -f "$bashrc_d" ]; then
            echo "$export_line" > "$bashrc_d"
            log_ok "DOCKER_HOST configurado en ~/.bashrc.d/podman.sh"
        fi
    else
        if ! grep -q "DOCKER_HOST=" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# Podman Docker Host" >> "$HOME/.bashrc"
            echo "$export_line" >> "$HOME/.bashrc"
            log_ok "DOCKER_HOST añadido a ~/.bashrc"
        fi
    fi

    # Zsh support
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
    log_info "Configurando containers.conf..."

    local containers_conf="$HOME/.config/containers/containers.conf"
    mkdir -p "$(dirname "$containers_conf")"

    if [ ! -f "$containers_conf" ]; then
        cat > "$containers_conf" <<'EOF'
[containers]
netns = "private"

[network]
default_network = "podman"
network_backend = "netavark"
EOF
        log_ok "containers.conf creado con backend netavark"
    fi
}

verify_installation() {
    log_info "Verificando instalación de Podman..."

    if ! podman info &>/dev/null; then
        log_error "Podman no pudo inicializarse correctamente. Ejecuta 'podman info' para diagnosticar."
        return 1
    fi

    log_ok "Podman rootless verificado correctamente"
    echo ""
    echo "============================================================"
    log_ok "Podman instalado y configurado con éxito en Soplos Linux"
    echo "============================================================"
    echo ""
    echo "Siguientes pasos:"
    echo "  1. Reinicia tu terminal o ejecuta: source ~/.bashrc"
    echo "  2. Configura el entorno Quadlets: ./install/quadlets-setup.sh"
    echo ""
}

main() {
    echo "============================================================"
    echo "  Instalación de Podman - Soplos Linux Tyson"
    echo "============================================================"
    echo ""

    require_root
    check_debian

    install_podman
    configure_storage
    configure_registries
    configure_network
    enable_linger
    configure_subuids
    enable_podman_socket
    configure_docker_host
    verify_installation || true
}

main "$@"
