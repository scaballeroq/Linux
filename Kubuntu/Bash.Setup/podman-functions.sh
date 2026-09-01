#!/bin/bash
# =============================================================================
# FUNCIONES DE PODMAN (podman-functions.sh) - Kubuntu
# Incluye funciones basicas + Quadlets
# =============================================================================

# psh: Shell interactiva en contenedor
psh() {
    if [ -z "$1" ]; then
        echo "Uso: psh <nombre_o_id_contenedor> [shell]"
        return 1
    fi
    local shell="${2:-/bin/bash}"
    podman exec -it "$1" "$shell"
}

# plogs: Ver logs de un contenedor
plogs() {
    if [ -z "$1" ]; then
        echo "Uso: plogs <nombre_o_id_contenedor> [lineas]"
        return 1
    fi
    local lines="${2:-100}"
    podman logs -f --tail "$lines" "$1"
}

# prmf: Borrado forzoso
prmf() {
    if [ -z "$1" ]; then
        echo "Uso: prmf <nombre_o_id_contenedor>"
        return 1
    fi
    podman stop "$1" && podman rm "$1"
}

# pinfo: Inspeccionar contenedor
pinfo() {
    if [ -z "$1" ]; then
        echo "Uso: pinfo <nombre_o_id_contenedor>"
        return 1
    fi
    podman inspect "$1" | less
}

# pcp: Copiar archivos
pcp() {
    if [ $# -lt 2 ]; then
        echo "Uso: pcp <contenedor:ruta_origen> <ruta_destino>"
        return 1
    fi
    podman cp "$1" "$2"
}

# ppsf / ppsaf: Listados con formato limpio
ppsf() {
    podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

ppsaf() {
    podman ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# pstats: Estadisticas en vivo
pstats() {
    podman stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Limpieza Profunda
pclean-all() {
    podman system prune -af --volumes
}

prm-stopped() {
    local stopped_containers
    stopped_containers=$(podman ps -aq -f status=exited)
    if [ -n "$stopped_containers" ]; then
        podman rm $stopped_containers
    else
        echo "No hay contenedores parados para eliminar."
    fi
}

prmi-dangling() {
    local dangling_images
    dangling_images=$(podman images -f "dangling=true" -q)
    if [ -n "$dangling_images" ]; then
        podman rmi $dangling_images
    else
        echo "No hay imagenes huerfanas para eliminar."
    fi
}

# =============================================================================
# FUNCIONES DE QUADLETS
# =============================================================================

# qstatus: Estado de Quadlets
qstatus() {
    systemctl --user list-units "*podman*" "*container*" 2>/dev/null
}

# qlogs: Logs de un Quadlet
qlogs() {
    if [ -z "$1" ]; then
        echo "Uso: qlogs <nombre-quadlet>"
        return 1
    fi
    journalctl --user -u "$1" -f --no-pager
}

# qrestart: Reiniciar un Quadlet
qrestart() {
    if [ -z "$1" ]; then
        echo "Uso: qrestart <nombre-quadlet>"
        return 1
    fi
    systemctl --user restart "$1"
}

# qstop: Detener un Quadlet
qstop() {
    if [ -z "$1" ]; then
        echo "Uso: qstop <nombre-quadlet>"
        return 1
    fi
    systemctl --user stop "$1"
}

# qstart: Iniciar un Quadlet
qstart() {
    if [ -z "$1" ]; then
        echo "Uso: qstart <nombre-quadlet>"
        return 1
    fi
    systemctl --user start "$1"
}

# qclean: Limpiar Quadlets inactivos
qclean() {
    systemctl --user daemon-reload
    echo "Quadlets recargados."
}

# =============================================================================
# ALIASES DE PODMAN
# =============================================================================
alias p='podman'
alias pc='podman-compose'
alias pps='podman ps'
alias ppsa='podman ps -a'
alias pimg='podman images'
alias pv='podman volume ls'
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

# =============================================================================
echo "Funciones Podman cargadas"
