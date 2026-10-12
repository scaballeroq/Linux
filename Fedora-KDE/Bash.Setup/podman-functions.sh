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
# ALIASES RÁPIDOS Y QUADLETS
# -----------------------------------------------------------------------------
alias p='podman'
alias pps='podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias psa='podman ps -a'
alias pi='podman images'
alias pv='podman volume ls'

# Parada y eliminación segura
pstop-all() {
    local running
    running=$(podman ps -q)
    if [ -n "$running" ]; then
        podman stop $running
    else
        echo "ℹ️ No hay contenedores en ejecución para detener."
    fi
}

prm-all() {
    local all_containers
    all_containers=$(podman ps -aq)
    if [ -n "$all_containers" ]; then
        podman rm -f $all_containers
    else
        echo "ℹ️ No hay contenedores para eliminar."
    fi
}

prmi-all() {
    local all_images
    all_images=$(podman images -q)
    if [ -n "$all_images" ]; then
        podman rmi -f $all_images
    else
        echo "ℹ️ No hay imágenes para eliminar."
    fi
}

# Quadlets de Podman (Systemd User Units)
alias quadlet-reload='systemctl --user daemon-reload'
alias quadlet-status='systemctl --user status "container-*"'
quadlet-logs() {
    local service="${1:-container}"
    journalctl --user -u "$service" -f -n 50
}

echo "✅ Funciones y atajos de Podman cargados (pps, pexec, Quadlets)"
