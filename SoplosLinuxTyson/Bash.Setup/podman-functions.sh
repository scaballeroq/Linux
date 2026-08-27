#!/bin/bash
# =============================================================================
# FUNCIONES PARA PODMAN (podman-functions.sh) - Soplos Linux Tyson
# =============================================================================
# Gestión avanzada de contenedores rootless, imágenes, pods y Podman Quadlets.

# -----------------------------------------------------------------------------
# 1. EJECUCIÓN Y ACCESO INTERACTIVO
# -----------------------------------------------------------------------------

# pexec / psh / dsh: Entrar en una shell interactiva de un contenedor
pexec() {
    if [ -z "$1" ]; then
        echo "Uso: pexec <nombre_o_id_contenedor> [comando]"
        return 1
    fi
    local cmd="${2:-bash}"
    podman exec -it "$1" "$cmd"
}
alias psh='pexec'
alias dsh='pexec'

# -----------------------------------------------------------------------------
# 2. LOGS E INSPECCIÓN
# -----------------------------------------------------------------------------

# plogs / dlogs: Seguir logs en tiempo real
plogs() {
    if [ -z "$1" ]; then
        echo "Uso: plogs <nombre_o_id_contenedor> [lineas]"
        return 1
    fi
    local lines="${2:-100}"
    podman logs -f --tail "$lines" "$1"
}
alias dlogs='plogs'

# pinfo: Inspeccionar metadatos de contenedor
pinfo() {
    if [ -z "$1" ]; then
        echo "Uso: pinfo <nombre_o_id_contenedor>"
        return 1
    fi
    podman inspect "$1" | less
}

# pcp: Copiar archivos hacia/desde contenedor
pcp() {
    if [ $# -lt 2 ]; then
        echo "Uso: pcp <contenedor:ruta_origen> <ruta_destino>"
        return 1
    fi
    podman cp "$1" "$2"
}

# -----------------------------------------------------------------------------
# 3. LIMPIEZA Y MANTENIMIENTO
# -----------------------------------------------------------------------------

# pclean: Limpieza estándar de contenedores parados, redes e imágenes huérfanas
pclean() {
    echo "🧹 Limpiando contenedores parados, redes no utilizadas e imágenes huérfanas..."
    podman container prune -f
    podman image prune -f
    podman network prune -f
}
alias dclean='pclean'

# pclean-total: Limpieza profunda total del sistema (incluyendo volúmenes huérfanos)
pclean-total() {
    echo "⚠️  Realizando limpieza profunda total de Podman (incluyendo volúmenes)..."
    podman system prune -af --volumes
}

# Eliminar contenedores parados
prm-stopped() {
    local stopped_containers
    stopped_containers=$(podman ps -aq -f status=exited -f status=created 2>/dev/null)
    if [ -n "$stopped_containers" ]; then
        podman rm $stopped_containers
    else
        echo "No hay contenedores detenidos para eliminar."
    fi
}

# Eliminar imágenes huérfanas (dangling)
prmi-dangling() {
    podman image prune -f
}

# -----------------------------------------------------------------------------
# 4. OPERACIONES MASIVAS Y ALIASES RÁPIDOS
# -----------------------------------------------------------------------------
alias p='podman'
alias psa='podman ps -a'
alias pi='podman images'
alias pv='podman volume ls'
alias pstats='podman stats'
alias dstats='podman stats'

# Quadlets de Podman (systemd user units)
alias podman-quadlet-reload='systemctl --user daemon-reload'

# Detener todos los contenedores activos de forma segura
pstop-all() {
    local running
    running=$(podman ps -q 2>/dev/null)
    if [ -n "$running" ]; then
        podman stop $running
    else
        echo "No hay contenedores en ejecución."
    fi
}

# Eliminar todos los contenedores
prm-all() {
    local all_containers
    all_containers=$(podman ps -aq 2>/dev/null)
    if [ -n "$all_containers" ]; then
        podman rm -f $all_containers
    else
        echo "No hay contenedores registrados."
    fi
}

# Eliminar todas las imágenes
prmi-all() {
    local all_images
    all_images=$(podman images -q 2>/dev/null)
    if [ -n "$all_images" ]; then
        podman rmi -f $all_images
    else
        echo "No hay imágenes para eliminar."
    fi
}

# =============================================================================
# MENSAJE DE CARGA (Solo en sesiones interactivas)
# =============================================================================
[[ $- == *i* ]] && [ -t 1 ] && echo "✅ Funciones y utilidades de Podman cargadas" || true

