#!/bin/bash
# =============================================================================
# Docker & Lazydocker Setup - Omarchy (Arch Linux)
# =============================================================================
# Omarchy incluye Docker y Lazydocker instalados por defecto.
# Este script realiza la configuración inicial del entorno:
#   1. Habilita e inicia docker.service en systemd
#   2. Agrega el usuario al grupo 'docker' para operar sin sudo
#   3. Aplica optimizaciones en /etc/docker/daemon.json (rotación de logs, etc.)
#   4. Crea la red global 'proxy-net'
#   5. Inicializa la configuración de Lazydocker
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
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }

require_non_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Este script NO debe ejecutarse como root."
        log_error "Ejecútalo con tu usuario normal (solicitará sudo cuando sea necesario)."
        exit 1
    fi
}

verify_omarchy_tools() {
    log_info "Verificando herramientas preinstaladas en Omarchy..."

    if ! command -v docker &>/dev/null; then
        log_info "Docker no encontrado en PATH, instalando mediante pacman..."
        sudo pacman -S --needed --noconfirm docker docker-compose docker-buildx
    else
        log_ok "Docker detectado: $(docker --version)"
    fi

    if ! command -v lazydocker &>/dev/null; then
        log_info "Lazydocker no encontrado en PATH, instalando..."
        sudo pacman -S --needed --noconfirm lazydocker
    else
        log_ok "Lazydocker detectado: $(lazydocker --version | head -1)"
    fi
}

configure_docker_service() {
    log_info "Configurando servicio systemd de Docker..."

    if ! systemctl is-enabled docker.service &>/dev/null; then
        log_step "Habilitando docker.service para inicio automático..."
        sudo systemctl enable docker.service
        log_ok "docker.service habilitado."
    else
        log_ok "docker.service ya está habilitado en el arranque."
    fi

    if ! systemctl is-active docker.service &>/dev/null; then
        log_step "Iniciando docker.service..."
        sudo systemctl start docker.service
        log_ok "docker.service iniciado con éxito."
    else
        log_ok "docker.service ya se encuentra en ejecución."
    fi
}

configure_docker_group() {
    log_info "Configurando permisos del grupo 'docker'..."

    if ! getent group docker >/dev/null; then
        sudo groupadd docker
        log_ok "Grupo 'docker' creado."
    fi

    if ! groups "$USER" | grep -qw "docker"; then
        log_step "Añadiendo a $USER al grupo docker..."
        sudo usermod -aG docker "$USER"
        log_ok "Usuario $USER añadido al grupo docker."
        echo ""
        log_info "⚠️ Para usar Docker sin sudo en tu terminal actual, ejecuta:"
        log_info "   newgrp docker"
        echo ""
    else
        log_ok "El usuario $USER ya pertenece al grupo docker."
    fi
}

configure_daemon_json() {
    log_info "Configurando optimizaciones en /etc/docker/daemon.json..."

    local daemon_conf="/etc/docker/daemon.json"

    if [ ! -f "$daemon_conf" ]; then
        log_step "Creando $daemon_conf con configuración optimizada (rotación de logs 50MB, live-restore)..."
        sudo mkdir -p /etc/docker
        cat <<'EOF' | sudo tee "$daemon_conf" >/dev/null
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "live-restore": true,
  "default-address-pools": [
    {
      "base": "172.28.0.0/16",
      "size": 24
    }
  ]
}
EOF
        log_ok "daemon.json creado correctamente."
        sudo systemctl restart docker.service
        log_ok "docker.service reiniciado con la nueva configuración."
    else
        log_info "$daemon_conf ya existe, se mantiene la configuración actual."
    fi
}

configure_global_network() {
    log_info "Configurando red puente 'proxy-net'..."

    if sudo docker network inspect proxy-net &>/dev/null; then
        log_ok "Red 'proxy-net' lista."
    else
        log_step "Creando red 'proxy-net'..."
        sudo docker network create proxy-net >/dev/null 2>&1 || true
        log_ok "Red 'proxy-net' creada con éxito."
    fi
}

setup_lazydocker_config() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [ -f "$script_dir/lazydocker-setup.sh" ]; then
        bash "$script_dir/lazydocker-setup.sh"
    fi
}

summary() {
    echo ""
    echo "============================================"
    log_ok "Configuración de Docker y Lazydocker completada"
    echo "============================================"
    echo ""
    echo "🚀 Ya puedes gestionar contenedores en Omarchy:"
    echo "  - Terminal gráfica:      lazydocker (o atajo: lzd)"
    echo "  - Crear proyectos:       docker-utils create <template> <nombre>"
    echo "  - Si aún no tienes permisos en esta ventana: newgrp docker"
    echo ""
}

main() {
    echo "============================================"
    echo "  Configuración de Docker & Lazydocker (Omarchy)"
    echo "============================================"
    echo ""

    require_non_root
    verify_omarchy_tools
    configure_docker_service
    configure_docker_group
    configure_daemon_json
    configure_global_network
    setup_lazydocker_config
    summary
}

main "$@"
