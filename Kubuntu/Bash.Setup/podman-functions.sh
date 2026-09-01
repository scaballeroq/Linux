# =============================================================================
# FUNCIONES DE PODMAN (podman-functions.sh) - Kubuntu
# Incluye funciones para contenedores, pods y Quadlets
# =============================================================================

# psh: Shell interactiva en contenedor
psh() {
    if [ -z "${1:-}" ]; then
        echo "Uso: psh <nombre_o_id_contenedor> [shell]"
        return 1
    fi
    local shell="${2:-/bin/bash}"
    podman exec -it "$1" "$shell"
}

# plogs: Ver logs en tiempo real de un contenedor
plogs() {
    if [ -z "${1:-}" ]; then
        echo "Uso: plogs <nombre_o_id_contenedor> [lineas]"
        return 1
    fi
    local lines="${2:-100}"
    podman logs -f --tail "$lines" "$1"
}

# prmf: Parada y borrado forzoso de un contenedor
prmf() {
    if [ -z "${1:-}" ]; then
        echo "Uso: prmf <nombre_o_id_contenedor>"
        return 1
    fi
    podman stop -t 2 "$1" 2>/dev/null || true
    podman rm -f "$1" 2>/dev/null || true
}

# pinfo: Inspeccionar contenedor con visor less
pinfo() {
    if [ -z "${1:-}" ]; then
        echo "Uso: pinfo <nombre_o_id_contenedor>"
        return 1
    fi
    podman inspect "$1" | less
}

# pcp: Copiar archivos entre host y contenedor
pcp() {
    if [ $# -lt 2 ]; then
        echo "Uso: pcp <contenedor:ruta_origen> <ruta_destino>"
        return 1
    fi
    podman cp "$1" "$2"
}

# ppsf / ppsaf: Listados tabulares limpios
ppsf() {
    podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

ppsaf() {
    podman ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# pstats: Monitor de recursos en vivo
pstats() {
    podman stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Limpieza segura de contenedores e imágenes
pstop-all() {
    podman ps -q | xargs -r podman stop
}

prm-all() {
    podman ps -aq | xargs -r podman rm -f
}

prmi-all() {
    podman images -q | xargs -r podman rmi -f
}

pclean-all() {
    podman system prune -af --volumes
}

prm-stopped() {
    podman ps -aq -f status=exited | xargs -r podman rm
}

prmi-dangling() {
    podman images -f "dangling=true" -q | xargs -r podman rmi
}

# =============================================================================
# FUNCIONES PARA QUADLETS (SYSTEMD USER)
# =============================================================================

# qstatus: Estado de servicios de usuario de contenedores
qstatus() {
    systemctl --user list-units "*podman*" "*container*" 2>/dev/null
}

# qlogs: Ver logs de un servicio Quadlet
qlogs() {
    if [ -z "${1:-}" ]; then
        echo "Uso: qlogs <nombre-quadlet>"
        return 1
    fi
    journalctl --user -u "$1" -f --no-pager
}

# qrestart: Reiniciar un servicio Quadlet
qrestart() {
    if [ -z "${1:-}" ]; then
        echo "Uso: qrestart <nombre-quadlet>"
        return 1
    fi
    systemctl --user restart "$1"
}

# qstop / qstart: Control de servicios Quadlet
qstop() {
    if [ -z "${1:-}" ]; then
        echo "Uso: qstop <nombre-quadlet>"
        return 1
    fi
    systemctl --user stop "$1"
}

qstart() {
    if [ -z "${1:-}" ]; then
        echo "Uso: qstart <nombre-quadlet>"
        return 1
    fi
    systemctl --user start "$1"
}

# qreload: Recargar generador de Quadlets y Systemd
qreload() {
    systemctl --user daemon-reload
    echo "✅ Quadlets y Systemd de usuario recargados."
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
