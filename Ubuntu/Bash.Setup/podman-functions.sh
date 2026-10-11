# =============================================================================
# FUNCIONES DE PODMAN (podman-functions.sh)
# =============================================================================
# Colección de funciones para facilitar el trabajo con contenedores Podman.
# Podman es un motor de contenedores compatible con OCI (como Docker).

# -----------------------------------------------------------------------------
# psh: Shell interactiva en contenedor
# Uso: psh <contenedor> [shell]
# -----------------------------------------------------------------------------
# Entra dentro de un contenedor en ejecución. Por defecto usa /bin/bash.
psh() {
    if [ -z "$1" ]; then
        echo "Uso: psh <nombre_o_id_contenedor> [shell]"
        return 1
    fi
    local shell="${2:-/bin/bash}"
    podman exec -it "$1" "$shell"
}

# -----------------------------------------------------------------------------
# plogs: Ver logs
# Uso: plogs <contenedor>
# -----------------------------------------------------------------------------
# Muestra los logs de un contenedor y se queda esperando nuevos (follow -f).
plogs() {
    if [ -z "$1" ]; then
        echo "Uso: plogs <nombre_o_id_contenedor>"
        return 1
    fi
    podman logs -f "$1"
}

# -----------------------------------------------------------------------------
# prmf: Borrado forzoso
# Uso: prmf <contenedor>
# -----------------------------------------------------------------------------
# Detiene (stop) y elimina (rm) un contenedor en un solo paso.
prmf() {
    if [ -z "$1" ]; then
        echo "Uso: prmf <nombre_o_id_contenedor>"
        return 1
    fi
    podman stop "$1" && podman rm "$1"
}

# -----------------------------------------------------------------------------
# ppsf / ppsaf: Listados con formato limpio
# -----------------------------------------------------------------------------
# Muestran la lista de contenedores formateada en una tabla limpia,
# evitando que se rompan las líneas en terminales pequeñas.

# Solo corriendo
ppsf() {
    podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Todos (incluyendo parados)
ppsaf() {
    podman ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# -----------------------------------------------------------------------------
# pstats: Estadísticas
# -----------------------------------------------------------------------------
# Muestra uso de CPU, Memoria y Red de los contenedores en vivo.
pstats() {
    podman stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# -----------------------------------------------------------------------------
# Limpieza Profunda
# -----------------------------------------------------------------------------

# Limpieza total del sistema (imágenes, contenedores parados, redes y caché)
pclean-total() {
    echo "⚠️ Realizando limpieza total de Podman..."
    podman system prune -af --volumes
}

# -----------------------------------------------------------------------------
# ALIASES DE PODMAN
# -----------------------------------------------------------------------------
alias p='podman'
alias pc='podman-compose'
alias pps='podman ps'                    # Contenedores en ejecución
alias ppsa='podman ps -a'                # Todos los contenedores
alias pimg='podman images'               # Imágenes locales
alias pstop-all='podman stop $(podman ps -q)' # Parar todo lo que corre
alias prm-all='podman rm $(podman ps -aq)'    # Borrar todo contenedor parado
alias prmi-all='podman rmi $(podman images -q)' # Borrar todas las imágenes
alias pexec='podman exec -it'            # Ejecutar comando en contenedor
alias pinspect='podman inspect'          # Inspeccionar contenedor
alias ppull='podman pull'                # Descargar imagen
alias pbuild='podman build'              # Construir imagen
alias prun='podman run'                  # Correr contenedor

# Gestión de Pods (grupos de contenedores)
alias pods='podman pod ps'
alias podsa='podman pod ps -a'
alias podstop='podman pod stop'
alias podstart='podman pod start'
alias podrm='podman pod rm'

# Limpieza de sistema Podman
alias pclean='podman system prune -af'
alias pclean-volumes='podman volume prune -f'
alias pclean-all='podman system prune -af --volumes'
# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
#echo "✅ Funciones Podman cargadas (p, plogs, pstats, gestión contenedores...)"
echo "✅ Funciones Podman cargadas"
