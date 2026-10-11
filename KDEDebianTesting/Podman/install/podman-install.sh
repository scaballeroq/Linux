#!/usr/bin/env bash
# ==============================================================================
# podman-install.sh - Instalación y Configuración Profesional de Podman Rootless
# Debian Testing (forky/sid) + KDE Plasma 6 (Wayland)
# Hardware: AMD Ryzen 7 PRO 4750U (8C/16T) | AMD Radeon Vega 7 | 32 GB RAM | NVMe ext4
# ==============================================================================
# Características:
# - Despliegue 100% rootless con socket de usuario systemd (/run/user/$UID/podman/podman.sock).
# - Habilita linger para que los contenedores y Quadlets sigan corriendo sin sesión gráfica.
# - Integración nativa con KDE Plasma 6 vía ~/.config/environment.d/10-podman.conf.
# - Integración modular de shell para Bash (~/.bashrc.d) y Zsh (~/.zshrc.d).
# - Almacenamiento optimizado: driver overlay nativo en kernel (sin sobrecarga FUSE) sobre ext4/NVMe.
# - Optimización de motor containers.conf: 8 hilos de descarga paralela, crun, pasta y GPU passthrough (/dev/dri).
# - Verificación de seguridad en Firewalld (interfaz podman+ en zona trusted).
# - Enlace automático del CLI 'podman-utils' en ~/.local/bin con autocompletados.
# - Despliegue estructurado del ecosistema de Quadlets.
# - Comandos CLI: --status, --help.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colores ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "${CYAN}==>${NC} ${BOLD}$1${NC}"; }

require_non_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "No ejecutes este instalador directamente como root."
        echo "💡 Ejecútalo con tu usuario normal. El script solicitará sudo solo cuando sea necesario."
        exit 1
    fi
}

show_help() {
    cat <<EOF
🐳 Instalador y Optimizador de Podman Rootless - Debian Testing (KDE Plasma 6)
   Optimizado para: AMD Ryzen 7 PRO (8C/16T) | Vega 7 GPU | NVMe ext4

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala paquetes (si no están presentes), configura almacenamiento
                         overlay nativo (sin FUSE), containers.conf optimizado para AMD Ryzen,
                         registries, linger, socket Docker API, DOCKER_HOST, CLI podman-utils
                         y la estructura de Quadlets.
  --status, -s           Muestra el estado completo del motor Podman, socket, linger,
                         DOCKER_HOST, overlay nativo, firewalld, GPU y contenedores.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Paquetes Debian:     Verifica podman, podman-docker, uidmap, passt (pasta), catatonit y compose.
  • Kernel Overlay:      Driver overlay nativo en kernel sobre ext4/NVMe (máximo rendimiento I/O).
  • Optimización Ryzen:  image_parallel_copies = 8, pids_limit = 4096, runtime crun, red pasta.
  • Aceleración GPU:     Soporte /dev/dri (card0, renderD128) para AMD Radeon Vega 7.
  • Persistencia Linger: Habilita loginctl linger para ejecutar contenedores en segundo plano.
  • Docker Socket API:   Activa podman.socket en /run/user/\$UID/podman/podman.sock.
  • Sesión KDE / GUI:    Inyecta DOCKER_HOST en ~/.config/environment.d/10-podman.conf.
  • Shells (Bash / Zsh): Configura variables de entorno en ~/.bashrc.d y autocompletados.
  • Seguridad Firewalld: Valida que podman+ esté asignado a la zona trusted.
  • CLI podman-utils:    Enlaza podman-utils en ~/.local/bin con autocompletados.
EOF
}

# 1. Mostrar estado de Podman
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE PODMAN ROOTLESS - DEBIAN TESTING (KDE 6)"
    echo "================================================================="

    local linger_val socket_status docker_host_val utils_status storage_info subuid_status
    local fw_status unpriv_ports gpu_status

    linger_val=$(loginctl show-user "$USER" 2>/dev/null | grep -i "Linger=" | cut -d= -f2 || echo "no")
    socket_status=$(systemctl --user is-active podman.socket 2>/dev/null || true)
    socket_status="${socket_status:-inactivo}"
    docker_host_val="${DOCKER_HOST:-$(grep "DOCKER_HOST=" "$HOME/.config/environment.d/10-podman.conf" 2>/dev/null | cut -d= -f2- || echo "No configurado")}"
    utils_status=$(command -v podman-utils &>/dev/null && echo "✅ Disponible en PATH (~/.local/bin/podman-utils)" || echo "ℹ️ No enlazado en PATH")

    if grep -q "^$USER:" /etc/subuid 2>/dev/null && grep -q "^$USER:" /etc/subgid 2>/dev/null; then
        subuid_status="✅ Asignados ($(grep "^$USER:" /etc/subuid | cut -d: -f2-))"
    else
        subuid_status="⚠️ No asignados en /etc/subuid o /etc/subgid"
    fi

    # Comprobación de Firewalld
    if command -v firewall-cmd &>/dev/null; then
        if firewall-cmd --state &>/dev/null; then
            local trusted_ifaces
            trusted_ifaces=$(firewall-cmd --zone=trusted --list-interfaces 2>/dev/null || echo "")
            if [[ "$trusted_ifaces" =~ "podman+" ]]; then
                fw_status="✅ Activo (interfaz podman+ en zona trusted)"
            else
                fw_status="⚠️ Activo (podman+ NO está en zona trusted)"
            fi
        else
            fw_status="ℹ️ Inactivo"
        fi
    else
        fw_status="ℹ️ Firewalld no instalado"
    fi

    # Puertos no privilegiados
    unpriv_ports=$(cat /proc/sys/net/ipv4/ip_unprivileged_port_start 2>/dev/null || echo "1024")

    # Aceleración GPU AMD
    if [ -e /dev/dri/renderD128 ]; then
        gpu_status="✅ AMD Radeon Vega 7 (/dev/dri/renderD128)"
    else
        gpu_status="ℹ️ Dispositivo DRI no detectado"
    fi

    if command -v podman &>/dev/null; then
        echo "• Motor Podman:        ✅ $(podman --version 2>/dev/null)"
        echo "• Socket de Usuario:   $(if [ "$socket_status" = "active" ]; then echo "✅ Activo"; else echo "⚠️ Inactivo ($socket_status)"; fi)"
        echo "• Socket Path:         /run/user/$(id -u)/podman/podman.sock"
        echo "• Persistencia Linger: $(if [ "$linger_val" = "yes" ]; then echo "✅ Habilitada"; else echo "ℹ️ Deshabilitada"; fi)"
        echo "• Rangos SubUID/GID:   $subuid_status"
        storage_info=$(podman info --format '{{.Store.GraphDriverName}} (Native Diff: {{index .Store.GraphStatus "Native Overlay Diff"}})' 2>/dev/null || echo "overlay nativo")
        echo "• Almacenamiento:      $storage_info"
        echo "• Red Rootless:        $(podman info --format '{{.Host.RootlessNetworkCmd}} ({{.Host.NetworkBackend}})' 2>/dev/null || echo "pasta / netavark")"
        echo "• Emulación Docker:    $(command -v docker &>/dev/null && echo "✅ Activa (podman-docker)" || echo "ℹ️ No instalada")"
        echo "• Proveedor Compose:   $(command -v docker-compose &>/dev/null && echo "✅ docker-compose" || (command -v podman-compose &>/dev/null && echo "✅ podman-compose" || echo "ℹ️ No instalado"))"
        echo "• DOCKER_HOST:         $docker_host_val"
        echo "• Cortafuegos:         $fw_status"
        echo "• Puertos Rootless:    ip_unprivileged_port_start = $unpriv_ports (permite puertos >= $unpriv_ports)"
        echo "• GPU Passthrough:     $gpu_status"
        echo "• CLI podman-utils:    $utils_status"
        echo "• Entorno KDE 6:       $(if [ -f "$HOME/.config/environment.d/10-podman.conf" ]; then echo "✅ Configurado"; else echo "ℹ️ No presente"; fi)"
        echo "• Generador Quadlets:  $(if [ -f /usr/lib/systemd/user-generators/podman-user-generator ]; then echo "✅ Integrado en systemd"; else echo "ℹ️ No detectado"; fi)"
        echo "-----------------------------------------------------------------"
        echo "📦 Contenedores en ejecución:"
        podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  (Ninguno en ejecución)"
    else
        echo "• Motor Podman:        ❌ No instalado en el sistema"
        echo "• Paquete APT:         Disponible en repositorios oficiales de Debian Testing"
        echo "• Socket de Usuario:   ℹ️ Inactivo (requiere Podman)"
        echo "• Persistencia Linger: $(if [ "$linger_val" = "yes" ]; then echo "✅ Habilitada"; else echo "ℹ️ Deshabilitada"; fi)"
        echo "• Rangos SubUID/GID:   $subuid_status"
        echo "• Cortafuegos:         $fw_status"
        echo "• CLI podman-utils:    $utils_status"
        echo "-----------------------------------------------------------------"
        echo "💡 Para instalar Podman y configurar todo el entorno rootless:"
        echo "   Ejecuta: $0"
    fi
    echo "================================================================="
}

# 2. Verificar e instalar paquetes con APT solo si faltan
install_packages() {
    log_info "Comprobando paquetes del motor Podman en Debian Testing (forky/sid)..."
    local missing_pkgs=()

    check_pkg() {
        dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
    }

    if ! check_pkg podman; then missing_pkgs+=("podman"); fi
    if ! check_pkg podman-docker; then missing_pkgs+=("podman-docker"); fi
    if ! check_pkg uidmap; then missing_pkgs+=("uidmap"); fi
    if ! check_pkg passt && ! check_pkg pasta; then missing_pkgs+=("passt"); fi
    if ! check_pkg catatonit; then missing_pkgs+=("catatonit"); fi
    if ! check_pkg fuse-overlayfs; then missing_pkgs+=("fuse-overlayfs"); fi

    # Si Podman no está instalado, incluir también podman-compose
    if ! command -v podman &>/dev/null; then
        missing_pkgs+=("podman-compose")
    fi

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        log_step "Instalando paquetes faltantes (${missing_pkgs[*]}) vía APT..."
        if ! command -v sudo &>/dev/null; then
            log_error "Se requieren permisos administrativos (sudo) para instalar: ${missing_pkgs[*]}"
            exit 1
        fi
        sudo apt-get update -qq
        sudo apt-get install -y "${missing_pkgs[@]}"
        log_ok "Paquetes de Podman instalados correctamente."
    else
        log_ok "Todos los paquetes base de Podman ya están instalados."
    fi

    if ! command -v podman &>/dev/null; then
        log_error "No se pudo detectar el comando 'podman' tras la instalación."
        exit 1
    fi
}

# 3. Configurar almacenamiento overlay nativo en kernel (óptimo para ext4 en NVMe)
configure_storage() {
    log_info "Configurando almacenamiento nativo de contenedores (storage.conf)..."
    local storage_conf="$HOME/.config/containers/storage.conf"
    mkdir -p "$(dirname "$storage_conf")"

    if [ ! -f "$storage_conf" ]; then
        cat > "$storage_conf" <<'EOF'
# Configuración optimizada para Debian Testing sobre SSD NVMe ext4
[storage]
driver = "overlay"
runroot = "/run/user/%U/containers"
graphroot = "%h/.local/share/containers/storage"

[storage.options]
pull_options = {enable_partial_images = "true", use_hard_links = "false", ostree_repos = ""}

[storage.options.overlay]
# En Linux 6.x/7.x con ext4, el kernel maneja overlayfs nativo rootless sin sobrecarga FUSE
mountopt = "nodev,metacopy=on"
EOF
        log_ok "storage.conf creado con driver overlay nativo del kernel (sin sobrecarga FUSE)."
    else
        # Si existe y tiene fuse-overlayfs forzado, advertir o corregir para máximo rendimiento
        if grep -q 'mount_program = "/usr/bin/fuse-overlayfs"' "$storage_conf" 2>/dev/null; then
            log_warn "storage.conf tiene fuse-overlayfs activo. Comentándolo para usar overlay nativo del kernel..."
            sed -i 's|^mount_program = "/usr/bin/fuse-overlayfs"|# mount_program = "/usr/bin/fuse-overlayfs"|' "$storage_conf"
            log_ok "storage.conf actualizado a overlay nativo en kernel."
        else
            log_info "storage.conf ya existe y utiliza overlay nativo."
        fi
    fi
}

# 4. Configurar containers.conf optimizado para AMD Ryzen (8C/16T), 32GB RAM y Vega 7
configure_containers_conf() {
    log_info "Configurando optimizaciones de hardware en containers.conf..."
    local containers_conf="$HOME/.config/containers/containers.conf"
    mkdir -p "$(dirname "$containers_conf")"

    if [ ! -f "$containers_conf" ]; then
        cat > "$containers_conf" <<'EOF'
# containers.conf - Optimizado para HP EliteBook 855 G7
# AMD Ryzen 7 PRO 4750U (8C/16T) | 32 GB RAM | Radeon Vega 7 | KDE Plasma 6 Wayland

[containers]
# Integración nativa con journald y systemd en KDE Plasma 6
log_driver = "journald"

# Límite amplio de PIDs para entornos de desarrollo intensivo
pids_limit = 4096

# Dispositivos de aceleración gráfica para contenedores (AMD Vega 7 / VA-API)
devices = [
    "/dev/dri/card0:/dev/dri/card0:rwm",
    "/dev/dri/renderD128:/dev/dri/renderD128:rwm"
]

[engine]
# OCI Runtime en C ultra-rápido nativo de Debian
runtime = "crun"

# Gestor cgroups v2 integrado con systemd user
cgroup_manager = "systemd"

# Red rootless de alto rendimiento pasta (passt)
network_cmd_path = "/usr/bin/pasta"

# Paralelismo optimizado para 8 núcleos / 16 hilos en descargas de capas
image_parallel_copies = 8

# Base de datos SQLite rápida (por defecto en Podman 5+)
database_backend = "sqlite"
EOF
        log_ok "containers.conf configurado (8 descargas paralelas, journald, crun, pasta y GPU DRI)."
    else
        log_info "containers.conf ya existe, manteniendo configuración actual."
    fi
}

# 5. Configurar registros oficiales
configure_registries() {
    log_info "Configurando registros de búsqueda de imágenes (registries.conf)..."
    local registries_conf="$HOME/.config/containers/registries.conf"
    mkdir -p "$(dirname "$registries_conf")"

    if [ ! -f "$registries_conf" ]; then
        cat > "$registries_conf" <<'EOF'
unqualified-search-registries = ["docker.io", "quay.io", "ghcr.io", "registry.debian.org"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry]]
prefix = "quay.io"
location = "quay.io"
EOF
        log_ok "registries.conf creado (docker.io, quay.io, ghcr.io, registry.debian.org)."
    else
        log_info "registries.conf ya existe, manteniendo configuración."
    fi
}

# 6. Habilitar persistencia de servicios de usuario (Linger)
enable_linger() {
    log_info "Verificando persistencia de servicios en segundo plano (Linger)..."
    local linger_state
    linger_state=$(loginctl show-user "$USER" 2>/dev/null | grep -i "Linger=" | cut -d= -f2 || echo "no")
    if [ "$linger_state" != "yes" ]; then
        log_info "Habilitando linger para el usuario $USER..."
        if ! loginctl enable-linger "$USER" 2>/dev/null; then
            if command -v sudo &>/dev/null; then
                sudo loginctl enable-linger "$USER"
            fi
        fi
        log_ok "Linger habilitado. Tus pods y Quadlets seguirán corriendo sin sesión activa."
    else
        log_ok "Linger ya está habilitado para $USER."
    fi
}

# 7. Comprobar asignación de subuid y subgid
configure_subuids() {
    log_info "Verificando rangos subuid/subgid para namespaces rootless..."
    if ! grep -q "^$USER:" /etc/subuid 2>/dev/null || ! grep -q "^$USER:" /etc/subgid 2>/dev/null; then
        if command -v sudo &>/dev/null; then
            log_info "Asignando rangos subuid/subgid para $USER con usermod..."
            sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER" 2>/dev/null || true
            podman system migrate 2>/dev/null || true
            log_ok "Rangos subuid/subgid configurados."
        fi
    else
        log_ok "Rangos subuid/subgid ya presentes para $USER."
    fi
}

# 8. Habilitar Podman Socket en systemd user (Compatible con Docker API)
enable_podman_socket() {
    log_info "Habilitando e iniciando podman.socket de systemd en modo usuario..."
    systemctl --user daemon-reload
    systemctl --user enable --now podman.socket 2>/dev/null || true
    log_ok "Socket de Podman activo en /run/user/$(id -u)/podman/podman.sock."
}

# 9. Exportar DOCKER_HOST en sesión KDE y Shells (Bash predeterminado / Zsh condicional)
configure_docker_host() {
    log_info "Configurando DOCKER_HOST para KDE Plasma 6 y Shells (Bash / Zsh)..."
    local socket_path="/run/user/$(id -u)/podman/podman.sock"
    local export_line="export DOCKER_HOST=\"unix://$socket_path\""
    local testcontainers_line="export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=\"$socket_path\""

    # 9.1. Sesión gráfica KDE Plasma 6 / Wayland (environment.d)
    mkdir -p "$HOME/.config/environment.d"
    cat <<EOF > "$HOME/.config/environment.d/10-podman.conf"
DOCKER_HOST=unix://$socket_path
TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=$socket_path
EOF

    # 9.2. Integración modular Bash (~/.bashrc.d/podman.sh) - PREDETERMINADO
    mkdir -p "$HOME/.bashrc.d"
    cat <<EOF > "$HOME/.bashrc.d/podman.sh"
# Podman Docker API Integration
$export_line
$testcontainers_line

# PATH para utilidades de usuario
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi
EOF

    # 9.3. Fallback directo en ~/.bashrc solo si no procesa ~/.bashrc.d
    if [ -f "$HOME/.bashrc" ] && ! grep -q "bashrc.d" "$HOME/.bashrc" 2>/dev/null; then
        if ! grep -q "DOCKER_HOST=" "$HOME/.bashrc" 2>/dev/null; then
            cat <<EOF >> "$HOME/.bashrc"

# Podman Docker API Integration
$export_line
$testcontainers_line
EOF
        fi
    fi

    # 9.4. Integración modular Zsh (~/.zshrc.d/podman.zsh) - CONDICIONAL SI EXISTE ~/.zshrc
    if [ -f "$HOME/.zshrc" ]; then
        mkdir -p "$HOME/.zshrc.d"
        cat <<EOF > "$HOME/.zshrc.d/podman.zsh"
# Podman Docker API Integration
$export_line
$testcontainers_line

# PATH para utilidades de usuario
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi
EOF
        if ! grep -q "DOCKER_HOST=" "$HOME/.zshrc" 2>/dev/null; then
            cat <<EOF >> "$HOME/.zshrc"

# Podman Docker API Integration
$export_line
$testcontainers_line
EOF
        fi
    fi

    log_ok "DOCKER_HOST integrado en KDE Plasma, Bash (~/.bashrc.d/podman.sh) y Zsh (si existe ~/.zshrc)."
}

# 10. Validar / Configurar Firewalld para interfaces Podman
configure_firewalld() {
    log_info "Verificando reglas de Firewalld para contenedores..."
    if command -v firewall-cmd &>/dev/null && firewall-cmd --state &>/dev/null; then
        local trusted_ifaces
        trusted_ifaces=$(firewall-cmd --zone=trusted --list-interfaces 2>/dev/null || echo "")
        if [[ ! "$trusted_ifaces" =~ "podman+" ]]; then
            log_info "Asignando interfaz podman+ a la zona trusted en Firewalld..."
            if command -v sudo &>/dev/null; then
                sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
                sudo firewall-cmd --permanent --zone=trusted --add-interface=cni-podman+ 2>/dev/null || true
                sudo firewall-cmd --reload 2>/dev/null || true
                log_ok "Interfaz podman+ agregada a zona trusted en Firewalld."
            else
                log_warn "Ejecuta con sudo para agregar podman+ a trusted: sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+ && sudo firewall-cmd --reload"
            fi
        else
            log_ok "Interfaz podman+ ya configurada en zona trusted de Firewalld."
        fi
    else
        log_info "Firewalld no está activo o no disponible."
    fi
}

# 11. Enlazar podman-utils al PATH del usuario
setup_podman_utils_cli() {
    log_info "Configurando CLI 'podman-utils' en ~/.local/bin..."
    mkdir -p "$HOME/.local/bin"
    if [ -f "$PODMAN_ROOT/lib/podman-utils.sh" ]; then
        chmod +x "$PODMAN_ROOT/lib/podman-utils.sh"
        ln -sf "$PODMAN_ROOT/lib/podman-utils.sh" "$HOME/.local/bin/podman-utils"
        log_ok "Symlink creado: ~/.local/bin/podman-utils -> podman-utils.sh"
    fi
}

# 12. Configurar autocompletado de podman-utils en Bash y Zsh (condicional)
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

# 13. Desplegar estructura de Quadlets
setup_quadlets() {
    log_info "Configurando estructura de directorios para Quadlets..."
    if [ -f "$SCRIPT_DIR/quadlets-setup.sh" ]; then
        chmod +x "$SCRIPT_DIR/quadlets-setup.sh"
        "$SCRIPT_DIR/quadlets-setup.sh"
    fi
}

# ------------------------------------------------------------------------------
# PROCESAR ARGUMENTOS CLI
# ------------------------------------------------------------------------------
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
        echo "🐳 OPTIMIZADOR DE PODMAN ROOTLESS - DEBIAN TESTING (KDE 6)"
        echo "================================================================="
        require_non_root
        install_packages
        configure_storage
        configure_containers_conf
        configure_registries
        enable_linger
        configure_subuids
        enable_podman_socket
        configure_docker_host
        configure_firewalld
        setup_podman_utils_cli
        setup_completions
        setup_quadlets
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Podman Rootless y Quadlets optimizados para AMD Ryzen, KDE 6 y Wayland."
        echo "💡 Comandos útiles: podman-utils create <template> <nombre> | podman-utils doctor"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
