#!/bin/bash
# =============================================================================
# FUNCIONES PARA PODMAN (podman-functions.sh)
# =============================================================================

# -----------------------------------------------------------------------------
# pexec: Ejecutar comandos en un contenedor
# Uso: pexec <contenedor> [comando]
# -----------------------------------------------------------------------------
pexec() {
    if [ -z "$1" ]; then
        echo "Uso: pexec <nombre_o_id_contenedor> [comando]"
        return 1
    fi
    local cmd="${2:-bash}"
    podman exec -it "$1" "$cmd"
}

# -----------------------------------------------------------------------------
# plogs: Ver logs de un contenedor
# Uso: plogs <contenedor> [lineas]
# -----------------------------------------------------------------------------
plogs() {
    if [ -z "$1" ]; then
        echo "Uso: plogs <nombre_o_id_contenedor> [lineas]"
        return 1
    fi
    local lines="${2:-100}"
    podman logs -f --tail "$lines" "$1"
}

# -----------------------------------------------------------------------------
# pinfo: Inspeccionar contenedor
# -----------------------------------------------------------------------------
pinfo() {
    if [ -z "$1" ]; then
        echo "Uso: pinfo <nombre_o_id_contenedor>"
        return 1
    fi
    podman inspect "$1" | less
}

# -----------------------------------------------------------------------------
# pcp: Copiar archivos
# -----------------------------------------------------------------------------
pcp() {
    if [ $# -lt 2 ]; then
        echo "Uso: pcp <contenedor:ruta_origen> <ruta_destino>"
        return 1
    fi
    podman cp "$1" "$2"
}

# -----------------------------------------------------------------------------
# LIMPIEZA
# -----------------------------------------------------------------------------

# Limpieza total del sistema (imágenes, contenedores parados, redes y caché)
pclean-total() {
    echo "⚠️ Realizando limpieza total de Podman..."
    podman system prune -af --volumes
}

# Eliminar contenedores parados
prm-stopped() {
    local stopped_containers=$(podman ps -aq -f status=exited)
    if [ -n "$stopped_containers" ]; then
        podman rm $stopped_containers
    else
        echo "No hay contenedores parados para eliminar."
    fi
}

# Eliminar imágenes huérfanas
prmi-dangling() {
    local dangling_images=$(podman images -f "dangling=true" -q)
    if [ -n "$dangling_images" ]; then
        podman rmi $dangling_images
    else
        echo "No hay imágenes huérfanas para eliminar."
    fi
}

# -----------------------------------------------------------------------------
# ALIASES RÁPIDOS
# -----------------------------------------------------------------------------
alias p='podman'
alias ps='podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias psa='podman ps -a'
alias pi='podman images'
alias pv='podman volume ls'
alias pstop-all='podman stop $(podman ps -q)'
alias prm-all='podman rm $(podman ps -aq)'
alias prmi-all='podman rmi $(podman images -q)'

echo "✅ Funciones de Podman cargadas"
