# =============================================================================
# FUNCIONES Y ALIASES DE DOCKER Y LAZYDOCKER (docker-functions.sh)
# =============================================================================

# -----------------------------------------------------------------------------
# FUNCIONES UTILITARIAS
# -----------------------------------------------------------------------------

# Entrar a una shell en un contenedor (bash o sh)
dsh() {
    if [ -z "${1:-}" ]; then
        echo "Uso: dsh <nombre_o_id_contenedor> [shell]"
        return 1
    fi
    local shell="${2:-}"
    if [ -n "$shell" ]; then
        docker exec -it "$1" "$shell"
    else
        docker exec -it "$1" /bin/bash 2>/dev/null || docker exec -it "$1" /bin/sh
    fi
}

# Seguir logs de un contenedor
dlogs() {
    if [ -z "${1:-}" ]; then
        echo "Uso: dlogs <nombre_o_id_contenedor>"
        return 1
    fi
    docker logs -f "$1"
}

# Detener y eliminar un contenedor
drmf() {
    if [ -z "${1:-}" ]; then
        echo "Uso: drmf <nombre_o_id_contenedor>"
        return 1
    fi
    docker stop "$1" && docker rm "$1"
}

# Lista formateada de contenedores activos
dpsf() {
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Lista formateada de todos los contenedores
dpsaf() {
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Estadísticas de contenedores
dstats() {
    docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Limpieza total de recursos no utilizados en Docker
dclean-total() {
    echo "⚠️ Realizando limpieza total de Docker (contenedores detenidos, imágenes huérfanas y volúmenes)..."
    docker system prune -af --volumes
}

# -----------------------------------------------------------------------------
# ALIASES DE DOCKER
# -----------------------------------------------------------------------------
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dstop-all='docker stop $(docker ps -q)'
alias drm-all='docker rm $(docker ps -aq)'
alias drmi-all='docker rmi $(docker images -q)'
alias dexec='docker exec -it'
alias dinspect='docker inspect'
alias dpull='docker pull'
alias dbuild='docker build'
alias drun='docker run'

# Limpieza
alias dclean='docker system prune -af'
alias dclean-volumes='docker volume prune -f'
alias dclean-all='docker system prune -af --volumes'

# -----------------------------------------------------------------------------
# LAZYDOCKER & DOCKER UTILS
# -----------------------------------------------------------------------------
alias lzd='lazydocker'
alias ldocker='lazydocker'

# Localización dinámica o estática de docker-utils
_DOCKER_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../Docker/lib" 2>/dev/null && pwd || true)"
if [ -f "$_DOCKER_LIB_DIR/docker-utils.sh" ]; then
    alias docker-utils="$_DOCKER_LIB_DIR/docker-utils.sh"
    alias dutils="$_DOCKER_LIB_DIR/docker-utils.sh"
else
    alias docker-utils='$HOME/Work/Linux/Omarchy/Docker/lib/docker-utils.sh'
    alias dutils='$HOME/Work/Linux/Omarchy/Docker/lib/docker-utils.sh'
fi
unset _DOCKER_LIB_DIR
