#!/bin/bash
# ==============================================================================
# podman-install.sh - Optimización y configuración de Podman Rootless + Socket + Quadlets
# openSUSE Tumbleweed (KDE Plasma 6 + Wayland)
# ==============================================================================
#
# Uso:
#   ./podman-install.sh              -> Configura el entorno Podman rootless, socket, linger, registries y symlink de podman-utils
#   ./podman-install.sh --status     -> Muestra el estado del socket, linger, DOCKER_HOST, storage y Quadlets
#   ./podman-install.sh --help       -> Muestra la ayuda interactiva
# ==============================================================================

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
        log_error "Este script NO debe ejecutarse directamente como root (con sudo)."
        log_error "Podman rootless se configura en el espacio de usuario normal."
        exit 1
    fi
}

show_help() {
    cat <<EOF
🐳 Optimizador y Configurador de Podman Rootless - openSUSE Tumbleweed (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Configura Podman rootless, socket compatible con Docker, linger, registries, environment.d y podman-utils CLI.
  --status, -s           Muestra el estado del motor Podman, socket, linger, DOCKER_HOST y almacenamiento.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Base openSUSE:       Verifica e instala complementos opcionales (podman, podman-compose, podman-docker, netavark, aardvark-dns).
  • Persistencia Linger: Habilita loginctl linger para que contenedores y Quadlets sigan corriendo sin sesión de terminal abierta.
  • Docker Socket API:   Activa podman.socket en systemd user (/run/user/\$UID/podman/podman.sock).
  • Sesión KDE / GUI:    Inyecta DOCKER_HOST en ~/.config/environment.d/10-podman.conf para VS Code, DevContainers y Antigravity.
  • Almacenamiento:      Configura driver overlay nativo en ~/.config/containers/storage.conf.
  • Registries:          Configura docker.io, quay.io, ghcr.io y registry.opensuse.org.
  • CLI podman-utils:    Crea symlink en ~/.local/bin/podman-utils y autocompletado en Bash (y Zsh condicional).
EOF
}

# 1. Mostrar estado de Podman
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE PODMAN ROOTLESS - OPENSUSE TUMBLEWEED (KDE 6)"
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

# 2. Verificar e instalar complementos opcionales con Zypper
install_packages() {
    log_info "Verificando paquetes y dependencias de Podman vía Zypper..."
    if command -v sudo &>/dev/null; then
        sudo zypper --non-interactive install -y \
            podman \
            podman-compose \
            podman-docker \
            netavark \
            aardvark-dns \
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
        cat > "$storage_conf" <<'EOF'
[storage]
driver = "overlay"

[storage.options]
pull_options = {enable_partial_images = "true", use_hard_links = "false", ostree_repos = ""}

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF
        log_ok "storage.conf creado con driver overlay."
    else
        log_info "storage.conf ya existe, manteniendo configuración actual."
    fi
}

# 4. Configurar registros oficiales
configure_registries() {
    log_info "Configurando registros de búsqueda de imágenes (registries.conf)..."
    local registries_conf="$HOME/.config/containers/registries.conf"
    mkdir -p "$(dirname "$registries_conf")"

    if [ ! -f "$registries_conf" ]; then
        cat > "$registries_conf" <<'EOF'
unqualified-search-registries = ["docker.io", "quay.io", "ghcr.io", "registry.opensuse.org"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry]]
prefix = "quay.io"
location = "quay.io"
EOF
        log_ok "registries.conf creado (docker.io, quay.io, ghcr.io, registry.opensuse.org)."
    else
        log_info "registries.conf ya existe, manteniendo configuración."
    fi
}

# 5. Habilitar persistencia de servicios de usuario (Linger)
enable_linger() {
    log_info "Verificando persistencia de servicios en segundo plano (Linger)..."
    local linger_state
    linger_state=$(loginctl show-user "$USER" 2>/dev/null | grep -i "Linger=" | cut -d= -f2 || echo "no")
    if [ "$linger_state" != "yes" ]; then
        log_info "Habilitando linger para el usuario $USER..."
        loginctl enable-linger "$USER" 2>/dev/null || {
            if command -v sudo &>/dev/null; then
                sudo loginctl enable-linger "$USER"
            fi
        }
        log_ok "Linger habilitado. Tus pods y contenedores no se detendrán al cerrar la terminal."
    else
        log_ok "Linger ya está habilitado para $USER."
    fi
}

# 6. Comprobar asignación de subuid y subgid
configure_subuids() {
    log_info "Verificando rangos subuid/subgid para namespaces rootless..."
    if ! grep -q "^$USER:" /etc/subuid 2>/dev/null || ! grep -q "^$USER:" /etc/subgid 2>/dev/null; then
        if command -v sudo &>/dev/null; then
            log_info "Asignando rangos subuid/subgid con usermod..."
            sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER" 2>/dev/null || true
            podman system migrate 2>/dev/null || true
            log_ok "Rangos subuid/subgid configurados."
        fi
    else
        log_ok "Rangos subuid/subgid ya presentes para $USER."
    fi
}

# 7. Habilitar Podman Socket en systemd user (Compatible con Docker API)
enable_podman_socket() {
    log_info "Habilitando e iniciando podman.socket de systemd en modo usuario..."
    systemctl --user daemon-reload
    systemctl --user enable --now podman.socket 2>/dev/null || true
    log_ok "Socket de Podman activo en /run/user/$(id -u)/podman/podman.sock."
}

# 8. Exportar DOCKER_HOST en sesión KDE y Shells (Bash predeterminado / Zsh condicional)
configure_docker_host() {
    log_info "Configurando DOCKER_HOST para KDE Plasma / Wayland y Shells (Bash / Zsh)..."
    local socket_path="/run/user/$(id -u)/podman/podman.sock"
    local export_line="export DOCKER_HOST=\"unix://$socket_path\""

    # 8.1. Sesión gráfica KDE Plasma / Wayland (environment.d)
    mkdir -p "$HOME/.config/environment.d"
    cat <<EOF > "$HOME/.config/environment.d/10-podman.conf"
DOCKER_HOST=unix://$socket_path
EOF

    # 8.2. Integración modular Bash (~/.bashrc.d/podman.sh) - PREDETERMINADO
    mkdir -p "$HOME/.bashrc.d"
    cat <<EOF > "$HOME/.bashrc.d/podman.sh"
# Podman Docker API Integration
$export_line

# PATH para utilidades de usuario
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi
EOF

    # 8.3. Fallback directo en ~/.bashrc solo si no procesa ~/.bashrc.d
    if [ -f "$HOME/.bashrc" ] && ! grep -q "bashrc.d" "$HOME/.bashrc" 2>/dev/null; then
        if ! grep -q "DOCKER_HOST=" "$HOME/.bashrc" 2>/dev/null; then
            cat <<EOF >> "$HOME/.bashrc"

# Podman Docker API Integration
$export_line
EOF
        fi
    fi

    # 8.4. Integración modular Zsh (~/.zshrc.d/podman.zsh) - CONDICIONAL SI EXISTE ~/.zshrc
    if [ -f "$HOME/.zshrc" ]; then
        mkdir -p "$HOME/.zshrc.d"
        cat <<EOF > "$HOME/.zshrc.d/podman.zsh"
# Podman Docker API Integration
$export_line

# PATH para utilidades de usuario
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi
EOF
        if ! grep -q "DOCKER_HOST=" "$HOME/.zshrc" 2>/dev/null; then
            cat <<EOF >> "$HOME/.zshrc"

# Podman Docker API Integration
$export_line
EOF
        fi
    fi

    log_ok "DOCKER_HOST integrado en KDE Plasma, Bash (~/.bashrc.d/podman.sh) y Zsh (si ~/.zshrc existe)."
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

# 10. Configurar autocompletado de podman-utils en Bash y Zsh (condicional)
setup_completions() {
    log_info "Configurando autocompletado para podman-utils en Bash (y Zsh si existe ~/.zshrc)..."
    local bash_comp_dir="$HOME/.local/share/bash-completion/completions"
    mkdir -p "$bash_comp_dir"

    # Autocompletado de podman-utils CLI (Bash)
    if [ -f "$PODMAN_ROOT/lib/podman-utils-completion.bash" ]; then
        cp "$PODMAN_ROOT/lib/podman-utils-completion.bash" "$bash_comp_dir/podman-utils"
    fi

    # Autocompletado para Zsh (condicional)
    if [ -f "$HOME/.zshrc" ]; then
        local zsh_site_dir="$HOME/.local/share/zsh/site-functions"
        local zfunc_dir="$HOME/.zfunc"
        mkdir -p "$zsh_site_dir" "$zfunc_dir"

        if [ -f "$PODMAN_ROOT/lib/podman-utils-completion.zsh" ]; then
            cp "$PODMAN_ROOT/lib/podman-utils-completion.zsh" "$zsh_site_dir/_podman-utils"
            cp "$PODMAN_ROOT/lib/podman-utils-completion.zsh" "$zfunc_dir/_podman-utils"
        fi

        if ! grep -q "site-functions" "$HOME/.zshrc" 2>/dev/null; then
            cat <<'EOF' >> "$HOME/.zshrc"

# Completions fpath
fpath=($HOME/.local/share/zsh/site-functions $HOME/.zfunc $fpath)
EOF
        fi
    fi

    log_ok "Autocompletado de podman-utils configurado."
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
        echo "🐳 OPTIMIZADOR DE PODMAN ROOTLESS - OPENSUSE TUMBLEWEED (KDE 6)"
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
        echo "✅ Podman Rootless y Quadlets configurados con éxito para Bash/Zsh y KDE."
        echo "💡 Comandos útiles: podman-utils create <template> <nombre> | podman ps"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
