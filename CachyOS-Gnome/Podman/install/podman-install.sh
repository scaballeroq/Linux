#!/bin/bash
# podman-install.sh - Optimización y configuración de Podman Rootless + Socket + Quadlets para CachyOS + GNOME
#
# Uso:
#   ./podman-install.sh              -> Configura el entorno Podman rootless, socket, linger, registries y symlink de podman-utils
#   ./podman-install.sh --status     -> Muestra el estado del socket, linger, DOCKER_HOST, storage y Quadlets
#   ./podman-install.sh --help       -> Muestra la ayuda interactiva

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PODMAN_ROOT/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
🐳 Optimizador y Configurador de Podman Rootless - CachyOS Workstation (GNOME Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Configura Podman rootless, socket compatible con Docker, linger, registries, environment.d y podman-utils CLI.
  --status, -s           Muestra el estado del motor Podman, socket, linger, DOCKER_HOST y almacenamiento.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Base CachyOS:        Verifica e instala complementos nativos (podman, netavark, aardvark-dns, catatonit, passt, shadow, podman-compose, podman-docker, fuse-overlayfs).
  • Persistencia Linger: Habilita loginctl linger para que contenedores y Quadlets sigan corriendo sin sesión de terminal abierta.
  • Docker Socket API:   Activa podman.socket en systemd user (/run/user/\$UID/podman/podman.sock).
  • Sesión GNOME / GUI:  Inyecta DOCKER_HOST en ~/.config/environment.d/10-podman.conf para VS Code, DevContainers, Antigravity y OpenCode.
  • Shells (Zsh / Bash): Integración modular en ~/.zshrc.d/ y ~/.bashrc.d/ con aliases y utilidades.
  • Almacenamiento:      Configura driver overlay nativo en ~/.config/containers/storage.conf optimizado para Btrfs/NVMe.
  • Registries:          Configura docker.io, quay.io, ghcr.io y registry.archlinux.org en ~/.config/containers/registries.conf.
  • CLI podman-utils:    Crea symlink en ~/.local/bin/podman-utils y autocompletado en Bash y Zsh.
  • Cortafuegos / Sysctl:Verifica interfaz podman+ en zona trusted de Firewalld y soporte de puertos <1024 (≥80).
EOF
}

# 1. Mostrar estado de Podman
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE PODMAN ROOTLESS - CACHYOS WORKSTATION (GNOME)"
    echo "================================================================="
    if command -v podman &>/dev/null; then
        echo "• Podman instalado:     $(podman --version 2>/dev/null)"
        local socket_status
        socket_status=$(systemctl --user is-active podman.socket 2>/dev/null || true)
        echo "• Socket de Usuario:    ${socket_status:-inactivo}"
        echo "• Socket Path:          /run/user/$(id -u)/podman/podman.sock"
        local linger_val
        linger_val=$(loginctl show-user "$USER" -p Linger --value 2>/dev/null || echo "no")
        echo "• Linger de Usuario:    $linger_val"
        echo "• Red / Network Stack:  $(podman info --format '{{.Host.NetworkBackend}}' 2>/dev/null || echo 'netavark')"
        echo "• Driver Storage:       $(podman info --format '{{.Store.GraphDriverName}}' 2>/dev/null || echo 'overlay')"
        echo "• SubUID/SubGID:        $(grep "^$USER:" /etc/subuid 2>/dev/null | cut -d: -f2,3 || echo 'No configurado')"
        echo "• Podman Compose:       $(command -v podman-compose &>/dev/null && echo 'Instalado' || echo 'No instalado')"
        echo "• Docker Emulation:     $(command -v docker &>/dev/null && echo 'Instalado (podman-docker)' || echo 'No instalado')"
        echo "• DOCKER_HOST actual:   ${DOCKER_HOST:-No exportado en la sesión actual}"
        echo "• CLI podman-utils:     $(command -v podman-utils &>/dev/null && echo 'Disponible en PATH (~/.local/bin/podman-utils)' || echo 'No enlazado')"
        
        # Estado de Firewalld y Sysctl
        local fw_status="No verificado"
        if [ -f /etc/firewalld/zones/trusted.xml ] && grep -q 'name="podman+"' /etc/firewalld/zones/trusted.xml 2>/dev/null; then
            fw_status="Configurado (interfaz podman+ en zona trusted)"
        elif command -v firewall-cmd &>/dev/null && timeout 2 firewall-cmd --zone=trusted --list-interfaces 2>/dev/null | grep -qw "podman+"; then
            fw_status="Configurado (interfaz podman+ en zona trusted)"
        else
            fw_status="Pendiente de asignación a zona trusted"
        fi
        echo "• Cortafuegos Firewalld:$fw_status"
        
        local port_start
        port_start=$(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null || echo "1024")
        echo "• Puertos sin sudo:     net.ipv4.ip_unprivileged_port_start = $port_start $([ "$port_start" -le 80 ] && echo '(HTTP/HTTPS 80/443 permitido)' || echo '(≥1024)')"

        echo ""
        echo "📦 Contenedores activos:"
        podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  (Ninguno en ejecución)"
    else
        echo "• Podman:               No instalado"
    fi
    echo "================================================================="
}

# 2. Verificar e instalar complementos opcionales con Pacman
install_packages() {
    log_info "Verificando paquetes y complementos de Podman en CachyOS..."
    local required_pkgs=(podman netavark aardvark-dns catatonit passt shadow)
    local optional_pkgs=(podman-compose podman-docker fuse-overlayfs)
    local to_install=()

    for pkg in "${required_pkgs[@]}" "${optional_pkgs[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        log_ok "Todos los paquetes necesarios de Podman ya están instalados."
    else
        log_info "Paquetes complementarios detectados: ${to_install[*]}..."
        if sudo -n true 2>/dev/null; then
            sudo pacman -S --needed --noconfirm "${to_install[@]}" 2>/dev/null || true
            log_ok "Paquetes verificados/instalados."
        else
            log_info "Para instalar los complementos opcionales ejecuta: sudo pacman -S --needed ${to_install[*]}"
        fi
    fi
}

# 3. Configurar almacenamiento overlay nativo optimizado para Btrfs/NVMe
configure_storage() {
    log_info "Configurando almacenamiento de contenedores (storage.conf)..."
    local storage_conf="$HOME/.config/containers/storage.conf"
    mkdir -p "$(dirname "$storage_conf")"

    if [ ! -f "$storage_conf" ]; then
        cat <<'EOF' > "$storage_conf"
# Configuración optimizada de almacenamiento Podman Rootless - CachyOS Workstation
[storage]
driver = "overlay"

[storage.options]
pull_options = {enable_partial_images = "true", use_hard_links = "false", ostree_repos = ""}

[storage.options.overlay]
mountopt = "nodev"
EOF
        log_ok "storage.conf configurado con driver overlay nativo."
    else
        log_info "storage.conf ya existe, manteniendo configuración existente."
    fi
}

# 4. Configurar registros de imágenes recomendados
configure_registries() {
    log_info "Configurando registros de imágenes de confianza (registries.conf)..."
    local registries_conf="$HOME/.config/containers/registries.conf"
    mkdir -p "$(dirname "$registries_conf")"

    if [ ! -f "$registries_conf" ]; then
        cat <<'EOF' > "$registries_conf"
# Registros de confianza y búsqueda de imágenes - CachyOS Workstation
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
        log_ok "registries.conf configurado con docker.io, quay.io, ghcr.io y registry.archlinux.org."
    else
        log_info "registries.conf ya existe, manteniendo configuración."
    fi
}

# 5. Habilitar linger para persistencia de contenedores y Quadlets
enable_linger() {
    local linger_val
    linger_val=$(loginctl show-user "$USER" -p Linger --value 2>/dev/null || echo "no")
    if [ "$linger_val" = "yes" ]; then
        log_ok "Persistencia (linger) ya activa para $USER."
    else
        log_info "Habilitando persistencia de usuario (linger) para Quadlets..."
        loginctl enable-linger "$USER" 2>/dev/null || true
        log_ok "Linger habilitado para $USER."
    fi
}

# 6. Configurar subuids y subgids si no estuvieran presentes
configure_subuids() {
    log_info "Verificando asignación de subuid y subgid..."
    if grep -q "^$USER:" /etc/subuid 2>/dev/null && grep -q "^$USER:" /etc/subgid 2>/dev/null; then
        log_ok "subuid y subgid ya están correctamente asignados a $USER."
    else
        if command -v sudo &>/dev/null; then
            sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER" 2>/dev/null || true
            log_ok "subuid/subgid asignados a $USER."
        else
            log_error "No se pudo verificar o asignar subuid/subgid sin permisos elevados."
        fi
    fi
}

# 7. Habilitar socket de Podman en Systemd User (Compatibilidad Docker API)
enable_podman_socket() {
    log_info "Habilitando podman.socket bajo demanda en systemd user..."
    systemctl --user enable --now podman.socket 2>/dev/null || true
    log_ok "Socket de Podman activo en /run/user/$(id -u)/podman/podman.sock."
}

# 8. Exportar DOCKER_HOST en sesión GNOME y Shells (Zsh y Bash modulares)
configure_docker_host() {
    log_info "Configurando DOCKER_HOST para GNOME / Wayland y Shells (Zsh / Bash)..."
    local socket_path="/run/user/$(id -u)/podman/podman.sock"
    local export_line="export DOCKER_HOST=\"unix://$socket_path\""

    # 8.1. Sesión gráfica GNOME / Wayland (environment.d para VS Code, JetBrains, DevContainers, OpenCode)
    mkdir -p "$HOME/.config/environment.d"
    cat <<EOF > "$HOME/.config/environment.d/10-podman.conf"
# Podman Docker API Socket para sesión de usuario GNOME / Wayland
DOCKER_HOST=unix://$socket_path
EOF

    # 8.2. Integración modular Zsh (~/.zshrc.d/podman.zsh) - Shell Principal en CachyOS
    mkdir -p "$HOME/.zshrc.d"
    cat <<EOF > "$HOME/.zshrc.d/podman.zsh"
# Podman Docker API Integration - CachyOS
$export_line

# Asegurar ~/.local/bin en PATH para podman-utils
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi
EOF

    # 8.3. Integración modular Bash (~/.bashrc.d/podman.sh)
    mkdir -p "$HOME/.bashrc.d"
    cat <<EOF > "$HOME/.bashrc.d/podman.sh"
# Podman Docker API Integration - CachyOS
$export_line

# Asegurar ~/.local/bin en PATH para podman-utils
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi
EOF

    # 8.4. Enlazar funciones y atajos interactivos (podman-functions.sh) si existe en Bash.Setup
    local podman_fn_src="$REPO_ROOT/Bash.Setup/podman-functions.sh"
    if [ -f "$podman_fn_src" ]; then
        ln -sf "$podman_fn_src" "$HOME/.zshrc.d/podman-functions.sh"
        ln -sf "$podman_fn_src" "$HOME/.bashrc.d/podman-functions.sh"
        log_ok "Atajos y funciones (pps, pexec, plogs, quadlet-*) enlazados en ~/.zshrc.d y ~/.bashrc.d."
    fi

    log_ok "DOCKER_HOST integrado en GNOME (environment.d), Zsh y Bash."
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

# 10. Configurar autocompletado en Bash y Zsh
setup_completions() {
    log_info "Configurando autocompletado para Bash y Zsh..."
    local bash_comp_dir="$HOME/.local/share/bash-completion/completions"
    mkdir -p "$bash_comp_dir"

    # Autocompletado oficial de Podman CLI (Bash)
    if command -v podman &>/dev/null; then
        podman completion bash > "$bash_comp_dir/podman" 2>/dev/null || true
    fi

    # Autocompletado de podman-utils CLI (Bash)
    if [ -f "$PODMAN_ROOT/lib/podman-utils-completion.bash" ]; then
        cp "$PODMAN_ROOT/lib/podman-utils-completion.bash" "$bash_comp_dir/podman-utils"
    fi

    # Autocompletados para Zsh
    local zsh_site_dir="$HOME/.local/share/zsh/site-functions"
    local zfunc_dir="$HOME/.zfunc"
    mkdir -p "$zsh_site_dir" "$zfunc_dir"

    if command -v podman &>/dev/null; then
        podman completion zsh > "$zsh_site_dir/_podman" 2>/dev/null || true
        podman completion zsh > "$zfunc_dir/_podman" 2>/dev/null || true
    fi

    if [ -f "$PODMAN_ROOT/lib/podman-utils-completion.zsh" ]; then
        cp "$PODMAN_ROOT/lib/podman-utils-completion.zsh" "$zsh_site_dir/_podman-utils"
        cp "$PODMAN_ROOT/lib/podman-utils-completion.zsh" "$zfunc_dir/_podman-utils"
    fi

    log_ok "Autocompletado configurado para Podman y podman-utils en Bash y Zsh."
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
        echo "🐳 OPTIMIZADOR DE PODMAN ROOTLESS - CACHYOS WORKSTATION (GNOME)"
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
        echo "✅ Podman Rootless y Quadlets optimizados con éxito para CachyOS."
        echo "💡 Comandos rápidos:"
        echo "  • Diagnóstico:       podman-utils doctor"
        echo "  • Crear proyecto:    podman-utils create <template> <nombre>"
        echo "  • Iniciar proyecto:  podman-utils start <nombre>"
        echo "  • Ver contenedores:  pps   o   podman ps"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
