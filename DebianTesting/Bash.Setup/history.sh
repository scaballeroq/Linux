# =============================================================================
# CONFIGURACIÓN DEL HISTORIAL (history.sh)
# =============================================================================
# Controla cómo bash recuerda los comandos que escribes.

# Cantidad de comandos a recordar en la sesión actual (memoria)
export HISTSIZE=10000

# Cantidad de comandos a guardar en el archivo ~/.bash_history
export HISTFILESIZE=20000

# Opciones de control:
# ignoreboth: Combina 'ignorespace' y 'ignoredups'.
#   - ignorespace: No guardar líneas que empiezan con un espacio.
#   - ignoredups: No guardar el comando si es igual al anterior.
# erasedups: Elimina duplicados anteriores en todo el historial para ahorrar espacio.
export HISTCONTROL=ignoreboth:erasedups

# Formato de fecha para el comando 'history'.
# Muestra: Año-Mes-Día Hora:Minuto:Segundo
export HISTTIMEFORMAT="%F %T "

# Añadir al archivo de historial en lugar de sobrescribirlo al salir de la sesión.
# Esto es vital para no perder historial al usar múltiples terminales.
shopt -s histappend

# Guardar comandos multilínea como una sola entrada en el historial.
# Facilita la lectura y edición posterior.
shopt -s cmdhist

# Lista de comandos a IGNORAR.
# Estos comandos no se guardarán en el historial para mantenerlo limpio.
# Se ignoran: ls, cd, pwd, exit, clear, history, comandos de job (bg/fg), etc.
export HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:history:bg:fg:..:..."

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Historial configurado (10k/20k líneas, ignorar duplicados)"
