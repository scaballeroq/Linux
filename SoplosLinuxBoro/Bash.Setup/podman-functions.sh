# =============================================================================
# FUNCIONES PARA PODMAN Y QUADLETS (podman-functions.sh)
# =============================================================================
# Utilidades interactivas para gestionar contenedores y Quadlets de systemd.

# Evitar ejecución en subshells y sesiones no interactivas
[[ $- != *i* ]] && return 0 2>/dev/null || true

# -----------------------------------------------------------------------------
# pexec: Ejecutar comandos en un contenedor
# Uso: pexec <contenedor> [comando]
# -----------------------------------------------------------------------------
pexec() {
    if [ -z "${1:-}" ]; then
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
    if [ -z "${1:-}" ]; then
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
    if [ -z "${1:-}" ]; then
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
pclean-all() {
    echo "⚠️  ADVERTENCIA: Se eliminarán TODOS los contenedores parados, redes no usadas e imágenes sin contenedor."
    printf "¿Continuar? (s/N): "
    read -r confirm
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        podman system prune -af --volumes
    fi
}

# Eliminar contenedores parados
prm-stopped() {
    local -a stopped_containers=()
    if [ -n "${BASH_VERSION:-}" ]; then
        mapfile -t stopped_containers < <(podman ps -aq -f status=exited 2>/dev/null)
    else
        stopped_containers=($(podman ps -aq -f status=exited 2>/dev/null))
    fi
    if [ ${#stopped_containers[@]} -gt 0 ] && [ -n "${stopped_containers[0]}" ]; then
        podman rm "${stopped_containers[@]}"
    else
        echo "ℹ️ No hay contenedores parados para eliminar."
    fi
}

# Eliminar imágenes huérfanas
prmi-dangling() {
    local -a dangling_images=()
    if [ -n "${BASH_VERSION:-}" ]; then
        mapfile -t dangling_images < <(podman images -f "dangling=true" -q 2>/dev/null)
    else
        dangling_images=($(podman images -f "dangling=true" -q 2>/dev/null))
    fi
    if [ ${#dangling_images[@]} -gt 0 ] && [ -n "${dangling_images[0]}" ]; then
        podman rmi "${dangling_images[@]}"
    else
        echo "ℹ️ No hay imágenes huérfanas para eliminar."
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
    local -a running=()
    if [ -n "${BASH_VERSION:-}" ]; then
        mapfile -t running < <(podman ps -q 2>/dev/null)
    else
        running=($(podman ps -q 2>/dev/null))
    fi
    if [ ${#running[@]} -gt 0 ] && [ -n "${running[0]}" ]; then
        podman stop "${running[@]}"
    else
        echo "ℹ️ No hay contenedores en ejecución para detener."
    fi
}

prm-all() {
    local -a all_containers=()
    if [ -n "${BASH_VERSION:-}" ]; then
        mapfile -t all_containers < <(podman ps -aq 2>/dev/null)
    else
        all_containers=($(podman ps -aq 2>/dev/null))
    fi
    if [ ${#all_containers[@]} -gt 0 ] && [ -n "${all_containers[0]}" ]; then
        podman rm -f "${all_containers[@]}"
    else
        echo "ℹ️ No hay contenedores para eliminar."
    fi
}

prmi-all() {
    local -a all_images=()
    if [ -n "${BASH_VERSION:-}" ]; then
        mapfile -t all_images < <(podman images -q 2>/dev/null)
    else
        all_images=($(podman images -q 2>/dev/null))
    fi
    if [ ${#all_images[@]} -gt 0 ] && [ -n "${all_images[0]}" ]; then
        podman rmi -f "${all_images[@]}"
    else
        echo "ℹ️ No hay imágenes para eliminar."
    fi
}

# Quadlets de Podman (Systemd User Units)
alias quadlet-reload='systemctl --user daemon-reload'
alias quadlet-dir='cd ~/.config/containers/systemd'

quadlet-list() {
    local dir="$HOME/.config/containers/systemd"
    echo "📦 Quadlets configurados en $dir:"
    if [ -d "$dir" ]; then
        find "$dir" -maxdepth 2 \( -name "*.container" -o -name "*.network" -o -name "*.volume" \) 2>/dev/null | sed 's|^'"$dir"'\/|   • |'
    else
        echo "   (El directorio no existe aún)"
    fi
}

quadlet-restart() {
    if [ -z "${1:-}" ]; then
        echo "Uso: quadlet-restart <nombre_servicio_sin_.service>"
        return 1
    fi
    local svc="$1"
    [[ "$svc" != *.service ]] && svc="${svc}.service"
    systemctl --user restart "$svc" && echo "✅ Servicio Quadlet $svc reiniciado."
}

quadlet-status() {
    local -a units=()
    if [ -d "$HOME/.config/containers/systemd" ]; then
        while IFS= read -r -d '' f; do
            local base
            base="$(basename "$f" .container).service"
            units+=("$base")
        done < <(find "$HOME/.config/containers/systemd" -name "*.container" -print0 2>/dev/null)
    fi
    if [ ${#units[@]} -gt 0 ]; then
        systemctl --user status "${units[@]}"
    else
        systemctl --user list-units "*podman*" 2>/dev/null || echo "ℹ️ No hay servicios Quadlets configurados."
    fi
}
quadlet-logs() {
    local service="${1:-container}"
    journalctl --user -u "$service" -f -n 50
}

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
[[ $- == *i* ]] && echo "✅ Funciones y atajos de Podman cargados (pps, pexec, Quadlets)"
