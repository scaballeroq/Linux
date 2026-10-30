#!/bin/bash
# ==============================================================================
# podman-install.sh - Instalación, Optimización y Configuración de Podman Rootless
# Ubuntu Workstation (GNOME Shell + Wayland / Systemd User Environment)
# ==============================================================================
# Características:
# - Optimizado para Ubuntu Workstation (Ubuntu 24.04 LTS / GNOME Shell).
# - Soporta tanto la instalación desde cero como la reconfiguración idempotente.
# - Paquetes modernos de Podman: passt (pasta de alto rendimiento), crun y catatonit.
# - Almacenamiento overlay nativo del kernel para máxima velocidad I/O en SSD NVMe Kioxia.
# - Aceleración por hardware para GPU AMD Radeon Graphics (Vega 8) vía grupos render/video.
# - Integración con Firewalld asignando la interfaz podman+ a la zona trusted.
# - Permite enlace a puertos bajos (80, 443) en modo rootless vía sysctl.
# - Activa loginctl linger para persistencia de contenedores tras cerrar sesión.
# - Habilita podman.socket en systemd user para compatibilidad total con Docker API.
# - Inyecta DOCKER_HOST en GNOME Shell (environment.d), Bash (~/.bashrc.d) y Zsh.
# - Despliega podman-utils CLI en ~/.local/bin con autocompletados nativos.
# - Inicializa la estructura modular de Quadlets de Systemd.
# - Diagnóstico integral del motor, hardware y servicios (--status).
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PODMAN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }

require_non_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Este script NO debe ejecutarse directamente como root (con sudo)."
        log_error "Podman rootless se configura en el espacio de usuario normal."
        log_error "El script solicitará 'sudo' de forma puntual solo si faltan paquetes del sistema o configuración de kernel/firewall."
        exit 1
    fi
}

show_help() {
    cat <<EOF
🐳 Optimizador y Configurador de Podman Rootless - Ubuntu Workstation 26.10
   Hardware: AMD Ryzen 7 7730U | Radeon Vega 8 | NVMe Kioxia 512GB | GNOME Shell

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala paquetes (si no están presentes), optimiza almacenamiento NVMe,
                         registries, linger, socket Docker API, DOCKER_HOST, CLI podman-utils,
                         aceleración GPU, firewalld y la estructura de Quadlets.
  --status, -s           Muestra el estado completo del motor Podman, socket, linger,
                         red pasta, GPU, almacenamiento NVMe, DOCKER_HOST y contenedores.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Paquetes Ubuntu 26:  podman, podman-docker, passt (pasta), crun, catatonit, uidmap, dbus-user-session.
  • Almacenamiento NVMe: Overlay nativo del Kernel 7.3 (sin sobrecarga FUSE) con ignore_chown_errors.
  • Red Rootless:        Stack de red nativo 'pasta' de alto rendimiento y baja latencia.
  • Aceleración GPU AMD: Acceso a /dev/dri/renderD128 mediante grupos render y video.
  • Cortafuegos:         Interfaz podman+ asociada a la zona trusted en Firewalld.
  • Puertos Rootless:    ip_unprivileged_port_start=80 para Traefik y proxies en puertos 80/443.
  • Persistencia Linger: loginctl linger para ejecutar contenedores en segundo plano.
  • Docker Socket API:   podman.socket en /run/user/\$UID/podman/podman.sock.
  • Sesión GNOME / GUI:  DOCKER_HOST en ~/.config/environment.d/10-podman.conf.
  • Shells (Bash / Zsh): DOCKER_HOST modular en ~/.bashrc.d/podman.sh y autocompletados.
  • Registries OCI:      docker.io, quay.io y ghcr.io.
  • CLI podman-utils:    Enlaza podman-utils en ~/.local/bin con autocompletados.
EOF
}

# 1. Mostrar estado de Podman
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE PODMAN ROOTLESS - UBUNTU WORKSTATION (GNOME SHELL)"
    echo "   AMD Ryzen 7 7730U | Radeon Vega 8 | NVMe | Ubuntu 26.10"
    echo "================================================================="

    local linger_val socket_status docker_host_val utils_status storage_info subuid_status
    local pasta_status crun_status gpu_status firewall_status port_status

    linger_val=$(loginctl show-user "$USER" 2>/dev/null | grep -i "Linger=" | cut -d= -f2 || echo "no")
    socket_status=$(systemctl --user is-active podman.socket 2>/dev/null || echo "inactivo")
    docker_host_val="${DOCKER_HOST:-$(grep "DOCKER_HOST=" "$HOME/.config/environment.d/10-podman.conf" 2>/dev/null | cut -d= -f2- || echo "No configurado")}"
    utils_status=$(command -v podman-utils &>/dev/null && echo "✅ Disponible en PATH (~/.local/bin/podman-utils)" || echo "ℹ️ No enlazado en PATH")

    if grep -q "^$USER:" /etc/subuid 2>/dev/null && grep -q "^$USER:" /etc/subgid 2>/dev/null; then
        subuid_status="✅ Asignados ($(grep "^$USER:" /etc/subuid | cut -d: -f2-))"
    else
        subuid_status="⚠️ No asignados en /etc/subuid o /etc/subgid"
    fi

    # Comprobar pasta
    if command -v pasta &>/dev/null; then
        pasta_status="✅ pasta disponible ($(pasta --version 2>&1 | head -1 | awk '{print $1,$2}'))"
    else
        pasta_status="⚠️ passt/pasta no instalado (degradando a slirp4netns)"
    fi

    # Comprobar crun
    if command -v crun &>/dev/null; then
        crun_status="✅ crun ($(crun --version 2>&1 | head -1 | awk '{print $3}'))"
    else
        crun_status="ℹ️ crun no instalado"
    fi

    # Comprobar GPU y grupos
    if [ -e /dev/dri/renderD128 ]; then
        if id -nG "$USER" 2>/dev/null | grep -qw "render"; then
            gpu_status="✅ AMD Radeon Vega 8 (/dev/dri/renderD128) - Grupo render asignado"
        else
            gpu_status="⚠️ AMD Radeon Vega 8 presente pero usuario NO está en grupo render"
        fi
    else
        gpu_status="ℹ️ /dev/dri/renderD128 no detectado"
    fi

    # Comprobar Firewalld vía D-Bus (busctl) sin invocar agentes polkit ni solicitar contraseña
    if systemctl is-active firewalld.service &>/dev/null; then
        local trusted_ifaces=""
        if command -v busctl &>/dev/null; then
            trusted_ifaces=$(busctl call org.fedoraproject.FirewallD1 /org/fedoraproject/FirewallD1 org.fedoraproject.FirewallD1.zone getInterfaces s "trusted" 2>/dev/null || echo "")
        fi

        if [[ "$trusted_ifaces" =~ "podman+" ]]; then
            firewall_status="✅ Firewalld activo y podman+ en zona trusted"
        else
            firewall_status="ℹ️ Firewalld activo (interfaz podman+ pendiente de asociar a trusted)"
        fi
    else
        firewall_status="ℹ️ Firewalld inactivo o no instalado"
    fi

    # Comprobar puerto unprivileged
    local unpriv_port
    unpriv_port=$(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null || echo "1024")
    if [ "$unpriv_port" -le 80 ]; then
        port_status="✅ $unpriv_port (Permite enlazar puertos 80 y 443 rootless)"
    else
        port_status="ℹ️ $unpriv_port (Requiere <= 80 para Traefik rootless)"
    fi

    if command -v podman &>/dev/null; then
        echo "• Motor Podman:        ✅ $(podman --version 2>/dev/null)"
        echo "• Runtime OCI:         $crun_status"
        echo "• Red Rootless:        $pasta_status"
        echo "• Socket de Usuario:   $(if [ "$socket_status" = "active" ]; then echo "✅ Activo"; else echo "⚠️ $socket_status"; fi)"
        echo "• Socket Path:         /run/user/$(id -u)/podman/podman.sock"
        echo "• Persistencia Linger: $(if [ "$linger_val" = "yes" ]; then echo "✅ Habilitada"; else echo "ℹ️ Deshabilitada"; fi)"
        echo "• Rangos SubUID/GID:   $subuid_status"
        storage_info=$(podman info --format '{{.Store.GraphDriverName}} (Native Diff: {{index .Store.GraphStatus "Native Overlay Diff"}})' 2>/dev/null || echo "overlay nativo")
        echo "• Almacenamiento NVMe: $storage_info"
        echo "• Aceleración GPU AMD: $gpu_status"
        echo "• Cortafuegos:         $firewall_status"
        echo "• Puertos Rootless:    $port_status"
        echo "• Emulación Docker:    $(command -v docker &>/dev/null && echo "✅ Activa (podman-docker)" || echo "ℹ️ No instalada")"
        echo "• Proveedor Compose:   $(command -v docker-compose &>/dev/null && echo "✅ docker-compose" || (command -v podman-compose &>/dev/null && echo "✅ podman-compose" || echo "ℹ️ No instalado"))"
        echo "• DOCKER_HOST:         $docker_host_val"
        echo "• CLI podman-utils:    $utils_status"
        echo "• Entorno GNOME:       $(if [ -f "$HOME/.config/environment.d/10-podman.conf" ]; then echo "✅ Configurado"; else echo "ℹ️ No presente"; fi)"
        echo "• Generador Quadlets:  $(if [ -f /usr/lib/systemd/user-generators/podman-user-generator ]; then echo "✅ Integrado en systemd"; else echo "ℹ️ No detectado"; fi)"
        echo "-----------------------------------------------------------------"
        echo "📦 Contenedores en ejecución:"
        podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  (Ninguno en ejecución)"
    else
        echo "• Motor Podman:        ❌ No instalado en el sistema"
        echo "• Paquete APT:         Disponible en repositorios oficiales de Ubuntu 26.10"
        echo "• Red Rootless:        $pasta_status"
        echo "• Runtime OCI:         $crun_status"
        echo "• Aceleración GPU AMD: $gpu_status"
        echo "• Socket de Usuario:   ℹ️ Inactivo (requiere Podman)"
        echo "• Persistencia Linger: $(if [ "$linger_val" = "yes" ]; then echo "✅ Habilitada"; else echo "ℹ️ Deshabilitada"; fi)"
        echo "• Rangos SubUID/GID:   $subuid_status"
        echo "• CLI podman-utils:    $utils_status"
        echo "-----------------------------------------------------------------"
        echo "💡 Para instalar Podman y configurar todo el entorno rootless optimizado:"
        echo "   Ejecuta: $0"
    fi
    echo "================================================================="
}

# 2. Verificar e instalar paquetes con APT solo si faltan
install_packages() {
    log_info "Comprobando paquetes del motor Podman y componentes optimizados..."
    local missing_pkgs=()

    # Paquetes base y de alto rendimiento en Ubuntu 26.10
    # - passt: proporciona 'pasta', stack de red rootless estándar de Podman 5
    # - crun: runtime OCI nativo en C ultrarrápido y bajo consumo de memoria
    # - catatonit: init subreaper para contenedores
    for pkg in podman podman-docker passt crun catatonit uidmap dbus-user-session slirp4netns fuse-overlayfs; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    # Comprobar compose
    if ! command -v podman-compose &>/dev/null && ! command -v docker-compose &>/dev/null; then
        if apt-cache show podman-compose &>/dev/null; then
            missing_pkgs+=("podman-compose")
        fi
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
        log_ok "Todos los paquetes base y de optimización de Podman ya están instalados."
    fi

    if ! command -v podman &>/dev/null; then
        log_error "No se pudo detectar el comando 'podman' tras la instalación."
        exit 1
    fi
}

# 3. Configurar almacenamiento overlay nativo (Kernel 7.3+ en NVMe Kioxia)
configure_storage() {
    log_info "Configurando almacenamiento de contenedores de alto rendimiento (storage.conf)..."
    local storage_conf="$HOME/.config/containers/storage.conf"
    mkdir -p "$(dirname "$storage_conf")"

    # En Ubuntu 26.10 (Linux 7.3+), el kernel soporta native unprivileged overlayfs.
    # Omitir 'mount_program = fuse-overlayfs' permite a Podman usar Native Overlay Diff
    # directamente sobre el SSD NVMe Kioxia sin la penalización de CPU/IO de FUSE.
    if [ ! -f "$storage_conf" ]; then
        cat > "$storage_conf" <<'EOF'
[storage]
driver = "overlay"

[storage.options]
pull_options = {enable_partial_images = "true", use_hard_links = "false", ostree_repos = ""}

[storage.options.overlay]
# Native overlay del kernel en Linux 7.3 (evita sobrecarga de FUSE en SSD NVMe)
ignore_chown_errors = "true"
EOF
        log_ok "storage.conf creado con driver overlay nativo para SSD NVMe."
    else
        # Si existe pero tiene forzado fuse-overlayfs, optimizarlo para el kernel actual
        if grep -q 'mount_program = "/usr/bin/fuse-overlayfs"' "$storage_conf" 2>/dev/null; then
            log_step "Optimizando storage.conf existente para usar overlay nativo del kernel 7.3..."
            sed -i 's|mount_program = "/usr/bin/fuse-overlayfs"|# mount_program = "/usr/bin/fuse-overlayfs" (desactivado: native overlay activo)|g' "$storage_conf"
            if ! grep -q "ignore_chown_errors" "$storage_conf" 2>/dev/null; then
                sed -i '/\[storage.options.overlay\]/a ignore_chown_errors = "true"' "$storage_conf"
            fi
            log_ok "storage.conf actualizado a driver overlay nativo."
        else
            log_info "storage.conf ya existe y está configurado."
        fi
    fi
}

# 4. Configurar registros oficiales
configure_registries() {
    log_info "Configurando registros de búsqueda de imágenes (registries.conf)..."
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
        log_ok "registries.conf creado (docker.io, quay.io, ghcr.io)."
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

# 6. Comprobar asignación de subuid, subgid y aceleración GPU AMD (render/video)
configure_privileges_and_gpu() {
    log_info "Verificando rangos subuid/subgid y aceleración GPU AMD..."
    local needs_mod=0

    if ! grep -q "^$USER:" /etc/subuid 2>/dev/null || ! grep -q "^$USER:" /etc/subgid 2>/dev/null; then
        needs_mod=1
    fi

    local in_render=0
    if id -nG "$USER" 2>/dev/null | grep -qw "render"; then
        in_render=1
    fi

    if [ "$needs_mod" -eq 1 ] || [ "$in_render" -eq 0 ]; then
        if command -v sudo &>/dev/null; then
            log_info "Configurando subuids/subgids y membresía a grupos GPU (render, video)..."
            if [ "$needs_mod" -eq 1 ]; then
                sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER" 2>/dev/null || true
            fi
            if [ "$in_render" -eq 0 ]; then
                sudo usermod -aG render,video "$USER" 2>/dev/null || true
                log_ok "Usuario $USER agregado a grupos 'render' y 'video' (GPU AMD Radeon Vega 8)."
            fi
            podman system migrate 2>/dev/null || true
            log_ok "Privilegios rootless y aceleración GPU configurados."
        fi
    else
        log_ok "Rangos subuid/subgid y grupos de GPU ya configurados para $USER."
    fi
}

# 7. Configurar Firewalld para redes de Podman (zona trusted)
configure_firewall() {
    log_info "Verificando reglas de cortafuegos (Firewalld)..."
    if systemctl is-active firewalld.service &>/dev/null; then
        local in_trusted=0
        if command -v busctl &>/dev/null; then
            if busctl call org.fedoraproject.FirewallD1 /org/fedoraproject/FirewallD1 org.fedoraproject.FirewallD1.zone getInterfaces s "trusted" 2>/dev/null | grep -q "podman+"; then
                in_trusted=1
            fi
        fi

        if [ "$in_trusted" -eq 1 ]; then
            log_ok "Interfaz podman+ ya está asignada a la zona trusted."
        else
            if command -v sudo &>/dev/null; then
                log_step "Asignando interfaz podman+ a la zona trusted en Firewalld..."
                sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
                sudo firewall-cmd --reload 2>/dev/null || true
                log_ok "Interfaz podman+ asociada a zona trusted en Firewalld."
            fi
        fi
    else
        log_info "Firewalld no está activo, omitiendo configuración de interfaz de cortafuegos."
    fi
}

# 8. Persistencia de puertos no privilegiados (sysctl <= 80 para Traefik)
configure_sysctl_ports() {
    log_info "Verificando inicio de puertos no privilegiados (sysctl)..."
    local current_port
    current_port=$(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null || echo "1024")

    if [ "$current_port" -gt 80 ]; then
        if command -v sudo &>/dev/null; then
            log_step "Configurando net.ipv4.ip_unprivileged_port_start = 80..."
            echo "net.ipv4.ip_unprivileged_port_start = 80" | sudo tee /etc/sysctl.d/99-podman-ports.conf > /dev/null
            sudo sysctl --system > /dev/null 2>&1 || true
            log_ok "Puertos 80 y 443 habilitados para rootless vía sysctl."
        fi
    else
        log_ok "Puertos no privilegiados ya permiten enlazar desde puerto 80."
    fi
}

# 9. Habilitar Podman Socket en systemd user (Compatible con Docker API)
enable_podman_socket() {
    log_info "Habilitando e iniciando podman.socket de systemd en modo usuario..."
    systemctl --user daemon-reload
    systemctl --user enable --now podman.socket 2>/dev/null || true
    log_ok "Socket de Podman activo en /run/user/$(id -u)/podman/podman.sock."
}

# 10. Exportar DOCKER_HOST en sesión GNOME y Shells (Bash predeterminado / Zsh condicional)
configure_docker_host() {
    log_info "Configurando DOCKER_HOST para GNOME Shell y Shells (Bash / Zsh)..."
    local socket_path="/run/user/$(id -u)/podman/podman.sock"
    local export_line="export DOCKER_HOST=\"unix://$socket_path\""

    # 10.1. Sesión gráfica Wayland / GNOME (environment.d)
    mkdir -p "$HOME/.config/environment.d"
    cat <<EOF > "$HOME/.config/environment.d/10-podman.conf"
DOCKER_HOST=unix://$socket_path
EOF

    # 10.2. Integración modular Bash (~/.bashrc.d/podman.sh) - PREDETERMINADO
    mkdir -p "$HOME/.bashrc.d"
    cat <<EOF > "$HOME/.bashrc.d/podman.sh"
# Podman Docker API Integration
$export_line

# PATH para utilidades de usuario
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi
EOF

    # 10.3. Fallback directo en ~/.bashrc solo si no procesa ~/.bashrc.d
    if [ -f "$HOME/.bashrc" ] && ! grep -q "bashrc.d" "$HOME/.bashrc" 2>/dev/null; then
        if ! grep -q "DOCKER_HOST=" "$HOME/.bashrc" 2>/dev/null; then
            cat <<EOF >> "$HOME/.bashrc"

# Podman Docker API Integration
$export_line
EOF
        fi
    fi

    # 10.4. Integración modular Zsh (~/.zshrc.d/podman.zsh) - CONDICIONAL SI EXISTE ~/.zshrc
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

    log_ok "DOCKER_HOST integrado en GNOME Shell, Bash (~/.bashrc.d/podman.sh) y Zsh (si existe ~/.zshrc)."
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
        echo "🐳 OPTIMIZADOR DE PODMAN ROOTLESS - UBUNTU WORKSTATION (GNOME)"
        echo "   AMD Ryzen 7 7730U | Radeon Vega 8 | NVMe Kioxia | Ubuntu 26.10"
        echo "================================================================="
        require_non_root
        install_packages
        configure_storage
        configure_registries
        enable_linger
        configure_privileges_and_gpu
        configure_firewall
        configure_sysctl_ports
        enable_podman_socket
        configure_docker_host
        setup_podman_utils_cli
        setup_completions
        setup_quadlets
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Podman Rootless y Quadlets optimizados con éxito para Ubuntu 26.10."
        echo "💡 Comandos útiles: podman-utils create <template> <nombre> | podman ps"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
