# =============================================================================
# CONFIGURACIÓN DEL HISTORIAL (history.sh) - Soplos Linux Tyson
# =============================================================================
# Controla cómo la shell recuerda y sincroniza los comandos que escribes.

# Cantidad de comandos a recordar en la sesión actual (memoria)
export HISTSIZE=10000

# Cantidad de comandos a guardar en el archivo de historial
export HISTFILESIZE=20000
export SAVEHIST=20000

# Opciones de control:
# ignoreboth: Combina 'ignorespace' y 'ignoredups'.
export HISTCONTROL=ignoreboth:erasedups

# Formato de fecha y hora para el comando 'history' (Año-Mes-Día Hora:Minuto:Segundo)
export HISTTIMEFORMAT="%F %T "

# Lista de comandos a IGNORAR para mantener el historial limpio y relevante
export HISTIGNORE="ls:ll:la:lt:tree:cd:pwd:exit:clear:c:history:bg:fg:..:...:....:reload:ff:sysinfo"

if [ -n "${BASH_VERSION:-}" ]; then
    # Añadir al archivo de historial en lugar de sobrescribirlo al salir de la sesión.
    shopt -s histappend 2>/dev/null || true
    # Guardar comandos multilínea como una sola entrada en el historial.
    shopt -s cmdhist 2>/dev/null || true
    # Sincronización inmediata: guarda cada comando en el archivo al ejecutarlo
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }history -a"
elif [ -n "${ZSH_VERSION:-}" ]; then
    setopt APPEND_HISTORY 2>/dev/null || true
    setopt HIST_IGNORE_ALL_DUPS 2>/dev/null || true
    setopt HIST_IGNORE_SPACE 2>/dev/null || true
fi

# =============================================================================
# MENSAJE DE CARGA (Solo en sesiones interactivas)
# =============================================================================
[[ $- == *i* ]] && [ -t 1 ] && echo "✅ Historial configurado (10k/20k líneas, sincro inmediata, sin duplicados)" || true

