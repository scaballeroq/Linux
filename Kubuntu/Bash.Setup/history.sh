# =============================================================================
# CONFIGURACIÓN DEL HISTORIAL (history.sh) - Kubuntu
# =============================================================================
# Optimiza el almacenamiento del historial de comandos, sincronización
# en tiempo real entre terminales y marcas de tiempo.
# =============================================================================

# Tamaño de historial
export HISTSIZE=10000
export HISTFILESIZE=50000

# Control de duplicados y espacios
export HISTCONTROL="ignoreboth:erasedups"

# Formato de fecha y hora (AAAA-MM-DD HH:MM:SS)
export HISTTIMEFORMAT="%F %T  "

# Comandos que no se registran
export HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:c:h:history"

# Opciones de Bash para el historial
shopt -s histappend 2>/dev/null
shopt -s cmdhist 2>/dev/null

# Sincronización inmediata al ejecutar comandos (para múltiples pestañas/ventanas)
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }history -a"
