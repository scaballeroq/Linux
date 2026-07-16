# =============================================================================
# FUNCIONES DE PODMAN (podman-functions.sh)
# =============================================================================

psh() {
    if [ -z "$1" ]; then
        echo "Uso: psh <nombre_o_id_contenedor> [shell]"
        return 1
    fi
    local shell="${2:-/bin/bash}"
    podman exec -it "$1" "$shell"
}

plogs() {
    if [ -z "$1" ]; then
        echo "Uso: plogs <nombre_o_id_contenedor>"
        return 1
    fi
    podman logs -f "$1"
}

prmf() {
    if [ -z "$1" ]; then
        echo "Uso: prmf <nombre_o_id_contenedor>"
        return 1
    fi
    podman stop "$1" && podman rm "$1"
}

ppsf() {
    podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

ppsaf() {
    podman ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

pstats() {
    podman stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

pclean-total() {
    echo "⚠️ Realizando limpieza total de Podman..."
    podman system prune -af --volumes
}

# -----------------------------------------------------------------------------
# ALIASES DE PODMAN
# -----------------------------------------------------------------------------
alias p='podman'
alias pc='podman-compose'
alias pps='podman ps'
alias ppsa='podman ps -a'
alias pimg='podman images'
alias pstop-all='podman stop $(podman ps -q)'
alias prm-all='podman rm $(podman ps -aq)'
alias prmi-all='podman rmi $(podman images -q)'
alias pexec='podman exec -it'
alias pinspect='podman inspect'
alias ppull='podman pull'
alias pbuild='podman build'
alias prun='podman run'

alias pods='podman pod ps'
alias podsa='podman pod ps -a'
alias podstop='podman pod stop'
alias podstart='podman pod start'
alias podrm='podman pod rm'

alias pclean='podman system prune -af'
alias pclean-volumes='podman volume prune -f'
alias pclean-all='podman system prune -af --volumes'
# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Funciones Podman cargadas"
