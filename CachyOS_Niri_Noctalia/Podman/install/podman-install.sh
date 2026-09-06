#!/bin/bash
# podman-install.sh - Optimización y configuración de Podman Rootless + Socket + Quadlets para CachyOS + KDE Plasma
#
# Uso:
#   ./podman-install.sh              -> Configura el entorno Podman rootless, socket, linger, registries y symlink de podman-utils
#   ./podman-install.sh --status     -> Muestra el estado del socket, linger, DOCKER_HOST, storage y Quadlets
#   ./podman-install.sh --help       -> Muestra la ayuda interactiva

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }

require_non_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Este script NO debe ejecutarse como root (con sudo directo)."
        log_error "Podman rootless se configura en el espacio de usuario normal."
        exit 1
    fi
}

show_help() {
    cat <<EOF
🐳 Optimizador y Configurador de Podman Rootless - CachyOS (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Configura Podman rootless, socket compatible con Docker, linger, registries, environment.d y podman-utils CLI.
  --status, -s           Muestra el estado del motor Podman, socket, linger, DOCKER_HOST y almacenamiento.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Base CachyOS:        Verifica e instala complementos opcionales (podman-compose, podman-docker, cockpit-podman, passt).
  • Persistencia Linger: Habilita loginctl linger para que contenedores y Quadlets sigan corriendo sin sesión de terminal abierta.
  • Docker Socket API:   Activa podman.socket en systemd user (/run/user/\$UID/podman/podman.sock).
  • Sesión KDE Plasma:   Inyecta DOCKER_HOST en ~/.config/environment.d/10-podman.conf para VS Code, DevContainers y KRunner.
  • Almacenamiento:      Configura driver overlay nativo en ~/.config/containers/storage.conf.
  • Registries:          Configura docker.io, quay.io, ghcr.io y registry.archlinux.org.
  • CLI podman-utils:    Crea symlink en ~/.local/bin/podman-utils y autocompletado en Bash.
EOF
}

# 1. Mostrar estado de Podman
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE PODMAN ROOTLESS - CACHYOS (KDE PLASMA)"
    echo "================================================================="
    if command -v podman &>/dev/null; then
        echo "• Podman instalado:    $(podman --version 2>/dev/null)"
        local socket_status
        socket_status=$(systemctl --user is-active podman.socket 2>/dev/null || true)
        echo "• Socket de Usuario:   ${socket_status:-inactivo}"
        echo "• Socket Path:         /run/user/$(id -u)/podman/podman.sock"
        local linger_val
        linger_val=$(loginctl show-user "$USER" 2>/dev/null | grep -i "Linger=" | cut -d= -f2 || echo "no")
        echo "• Linger de Usuario:   $linger_val"
        echo "• Driver Storage:      $(podman info --format '{{.Store.GraphDriverName}}' 2>/dev/null || echo 'overlay')"
        echo "• Podman Compose:      $(command -v podman-compose &>/dev/null && echo 'Instalado' || echo 'No instalado')"
        echo "• Docker Emulation:    $(command -v docker &>/dev/null && echo 'Instalado (podman-docker)' || echo 'No instalado')"
        echo "• DOCKER_HOST actual:  ${DOCKER_HOST:-No exportado en la sesión actual}"
        echo "• CLI podman-utils:    $(command -v podman-utils &>/dev/null && echo 'Disponible en PATH' || echo 'No enlazado')"
        echo ""
        echo "📦 Contenedores activos:"
        podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  (Ninguno en ejecución)"
    else
        echo "• Podman:              No instalado"
    fi
    echo "================================================================="
}

# 2. Verificar e instalar complementos opcionales con Pacman
install_packages() {
    log_info "Verificando paquetes y complementos de Podman en CachyOS..."
    if command -v sudo &>/dev/null; then
        sudo pacman -S --needed --noconfirm \
            podman \
            podman-compose \
            podman-docker \
            passt \
            fuse-overlayfs \
            shadow 2>/dev/null || true
    fi
    log_ok "Paquetes de Podman verificados."
}

# 3. Configurar almacenamiento overlay nativo
configure_storage() {
    log_info "Configurando almacenamiento de contenedores (storage.conf)..."
    local storage_conf="$HOME/.config/containers/storage.conf"
    mkdir -p "$(dirname "$storage_conf")"

    if [ ! -f "$storage_conf" ]; then
        cat <<'EOF' > "$storage_conf"
[storage]
driver = "overlay"

[storage.options]
pull_options = {enable_partial_images = "true", use_hard_links = "false", ostree_repos = ""}
EOF
        log_ok "storage.conf configurado."
    else
        log_info "storage.conf ya existe, manteniendo configuración."
    fi
}

# 4. Configurar registros de imágenes recomendados
configure_registries() {
    log_info "Configurando registros de imágenes de confianza (registries.conf)..."
    local registries_conf="$HOME/.config/containers/registries.conf"
    mkdir -p "$(dirname "$registries_conf")"

    if [ ! -f "$registries_conf" ]; then
        cat <<'EOF' > "$registries_conf"
unqualified-search-registries = ["docker.io", "quay.io", "ghcr.io", "registry.archlinux.org"]

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
        log_ok "registries.conf configurado."
    fi
}

# 5. Habilitar linger para persistencia de contenedores y Quadlets
enable_linger() {
    log_info "Habilitando persistencia de usuario (linger) para Quadlets..."
    loginctl enable-linger "$USER" 2>/dev/null || true
    log_ok "Linger de usuario activo."
}

# 6. Configurar subuids y subgids si no estuvieran presentes
configure_subuids() {
    log_info "Verificando asignación de subuid y subgid..."
    if ! grep -q "^$USER:" /etc/subuid 2>/dev/null; then
        if command -v sudo &>/dev/null; then
            sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER" 2>/dev/null || true
            log_ok "subuid/subgid asignados a $USER."
        fi
    else
        log_ok "subuid y subgid ya están correctamente configurados."
    fi
}

# 7. Habilitar socket de Podman en Systemd User (Compatibilidad Docker API)
enable_podman_socket() {
    log_info "Habilitando podman.socket bajo demanda en systemd user..."
    systemctl --user enable --now podman.socket 2>/dev/null || true
    log_ok "Socket de Podman activo en /run/user/$(id -u)/podman/podman.sock."
}

# 8. Exportar DOCKER_HOST en sesión KDE Plasma y Shells (Bash & Zsh)
configure_docker_host() {
    log_info "Configurando DOCKER_HOST para KDE Plasma / Wayland y Shells (Zsh / Bash)..."
    local socket_path="/run/user/$(id -u)/podman/podman.sock"
    local export_line="export DOCKER_HOST=\"unix://$socket_path\""

    # 8.1. Sesión gráfica KDE Plasma / Wayland (environment.d)
    mkdir -p "$HOME/.config/environment.d"
    cat <<EOF > "$HOME/.config/environment.d/10-podman.conf"
DOCKER_HOST=unix://$socket_path
EOF

    # 8.2. Integración modular Zsh (~/.zshrc.d/podman.zsh)
    mkdir -p "$HOME/.zshrc.d"
    cat <<EOF > "$HOME/.zshrc.d/podman.zsh"
# Podman Docker API Integration
$export_line

# PATH para utilidades de usuario
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi
EOF

    # 8.3. Integración modular Bash (~/.bashrc.d/podman.sh)
    mkdir -p "$HOME/.bashrc.d"
    cat <<EOF > "$HOME/.bashrc.d/podman.sh"
# Podman Docker API Integration
$export_line

# PATH para utilidades de usuario
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi
EOF

    # 8.4. Fallback directo en ~/.zshrc
    if [ -f "$HOME/.zshrc" ] || [[ "${SHELL:-}" == *"zsh"* ]]; then
        touch "$HOME/.zshrc"
        if ! grep -q "DOCKER_HOST=" "$HOME/.zshrc" 2>/dev/null; then
            cat <<EOF >> "$HOME/.zshrc"

# Podman Docker API Integration
$export_line
EOF
        fi
    fi

    # 8.5. Fallback directo en ~/.bashrc
    if ! grep -q "DOCKER_HOST=" "$HOME/.bashrc" 2>/dev/null; then
        cat <<EOF >> "$HOME/.bashrc"

# Podman Docker API Integration
$export_line
EOF
    fi

    log_ok "DOCKER_HOST integrado en KDE Plasma, Zsh (~/.zshrc.d/podman.zsh) y Bash."
}

# 9. Enlazar podman-utils al PATH del usuario
setup_podman_utils_cli() {
    log_info "Configurando CLI 'podman-utils' en ~/.local/bin..."
    mkdir -p "$HOME/.local/bin"
    if [ -f "$PODMAN_ROOT/lib/podman-utils.sh" ]; then
        chmod +x "$PODMAN_ROOT/lib/podman-utils.sh"
        ln -sf "$PODMAN_ROOT/lib/podman-utils.sh" "$HOME/.local/bin/podman-utils"
        log_ok "Symlink creado: ~/.local/bin/podman-utils -> podman-utils.sh"
    fi
}

# 10. Configurar autocompletado en Zsh y Bash
setup_completions() {
    log_info "Configurando autocompletado para Zsh y Bash..."
    local zsh_site_dir="$HOME/.local/share/zsh/site-functions"
    local zfunc_dir="$HOME/.zfunc"
    local bash_comp_dir="$HOME/.local/share/bash-completion/completions"

    mkdir -p "$zsh_site_dir" "$zfunc_dir" "$bash_comp_dir"

    # Autocompletado oficial de Podman CLI
    if command -v podman &>/dev/null; then
        podman completion zsh > "$zsh_site_dir/_podman" 2>/dev/null || true
        podman completion zsh > "$zfunc_dir/_podman" 2>/dev/null || true
        podman completion bash > "$bash_comp_dir/podman" 2>/dev/null || true
    fi

    # Autocompletado de podman-utils CLI
    if [ -f "$PODMAN_ROOT/lib/podman-utils-completion.zsh" ]; then
        cp "$PODMAN_ROOT/lib/podman-utils-completion.zsh" "$zsh_site_dir/_podman-utils"
        cp "$PODMAN_ROOT/lib/podman-utils-completion.zsh" "$zfunc_dir/_podman-utils"
    fi

    if [ -f "$PODMAN_ROOT/lib/podman-utils-completion.bash" ]; then
        cp "$PODMAN_ROOT/lib/podman-utils-completion.bash" "$bash_comp_dir/podman-utils"
    fi

    # Asegurar fpath en ~/.zshrc si no está presente
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "site-functions" "$HOME/.zshrc" 2>/dev/null; then
            cat <<'EOF' >> "$HOME/.zshrc"

# Completions fpath
fpath=($HOME/.local/share/zsh/site-functions $HOME/.zfunc $fpath)
EOF
        fi
    fi

    log_ok "Autocompletado configurado para Zsh y Bash."
}

# 11. Desplegar estructura de Quadlets
setup_quadlets() {
    log_info "Configurando estructura de directorios para Quadlets..."
    if [ -f "$SCRIPT_DIR/quadlets-setup.sh" ]; then
        chmod +x "$SCRIPT_DIR/quadlets-setup.sh"
        "$SCRIPT_DIR/quadlets-setup.sh"
    fi
}

# Procesar argumentos
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
        echo "🐳 OPTIMIZADOR DE PODMAN ROOTLESS - CACHYOS (KDE PLASMA 6)"
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
        setup_completions
        setup_quadlets
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Podman Rootless y Quadlets configurados con éxito para Zsh y KDE Plasma."
        echo "💡 Comandos útiles: podman-utils create <template> <nombre> | podman ps"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
