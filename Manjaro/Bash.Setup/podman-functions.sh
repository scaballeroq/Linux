#!/bin/bash
# =============================================================================
# FUNCIONES PARA PODMAN (podman-functions.sh) - Manjaro Linux (Bash)
# =============================================================================

pexec() {
    if [ -z "$1" ]; then
        echo "Uso: pexec <nombre_o_id_contenedor> [comando]"
        return 1
    fi
    local cmd="${2:-bash}"
    podman exec -it "$1" "$cmd"
}

plogs() {
    if [ -z "$1" ]; then
        echo "Uso: plogs <nombre_o_id_contenedor> [lineas]"
        return 1
    fi
    local lines="${2:-100}"
    podman logs -f --tail "$lines" "$1"
}

pinfo() {
    if [ -z "$1" ]; then
        echo "Uso: pinfo <nombre_o_id_contenedor>"
        return 1
    fi
    podman inspect "$1" | less
}

pcp() {
    if [ $# -lt 2 ]; then
        echo "Uso: pcp <contenedor:ruta_origen> <ruta_destino>"
        return 1
    fi
    podman cp "$1" "$2"
}

pclean-total() {
    echo "⚠️ Realizando limpieza total de Podman..."
    podman system prune -af --volumes
}

prm-stopped() {
    local stopped_containers=$(podman ps -aq -f status=exited 2>/dev/null || true)
    if [ -n "$stopped_containers" ]; then
        echo "$stopped_containers" | xargs -r podman rm
    else
        echo "No hay contenedores parados para eliminar."
    fi
}

prmi-dangling() {
    local dangling_images=$(podman images -f "dangling=true" -q 2>/dev/null || true)
    if [ -n "$dangling_images" ]; then
        echo "$dangling_images" | xargs -r podman rmi
    else
        echo "No hay imágenes huérfanas para eliminar."
    fi
}

alias p='podman'
alias ps='podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias psa='podman ps -a'
alias pi='podman images'
alias pv='podman volume ls'
pstop-all() { podman ps -q | xargs -r podman stop; }
prm-all() { podman ps -aq | xargs -r podman rm; }
prmi-all() { podman images -q | xargs -r podman rmi; }

echo "✅ Funciones de Podman para Bash cargadas"
