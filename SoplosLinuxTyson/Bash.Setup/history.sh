# =============================================================================
# CONFIGURACIÓN DEL HISTORIAL (history.sh) - Soplos Linux Tyson
# =============================================================================
# Controla cómo bash recuerda y sincroniza los comandos que escribes.

# Cantidad de comandos a recordar en la sesión actual (memoria)
export HISTSIZE=10000

# Cantidad de comandos a guardar en el archivo ~/.bash_history
export HISTFILESIZE=20000

# Opciones de control:
# ignoreboth: Combina 'ignorespace' y 'ignoredups'.
#   - ignorespace: No guardar líneas que empiezan con un espacio.
#   - ignoredups: No guardar el comando si es igual al anterior.
# erasedups: Elimina duplicados anteriores en todo el historial para mantenerlo limpio.
export HISTCONTROL=ignoreboth:erasedups

# Formato de fecha y hora para el comando 'history' (Año-Mes-Día Hora:Minuto:Segundo)
export HISTTIMEFORMAT="%F %T "

# Añadir al archivo de historial en lugar de sobrescribirlo al salir de la sesión.
# Vital para no perder historial al usar múltiples pestañas o terminales.
shopt -s histappend

# Guardar comandos multilínea como una sola entrada en el historial.
shopt -s cmdhist

# Sincronización inmediata: guarda cada comando en el archivo al ejecutarlo
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }history -a"

# Lista de comandos a IGNORAR para mantener el historial limpio y relevante
export HISTIGNORE="ls:ll:la:lt:tree:cd:pwd:exit:clear:c:history:bg:fg:..:...:....:reload:ff:sysinfo"

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Historial configurado (10k/20k líneas, sincro inmediata, sin duplicados)"

