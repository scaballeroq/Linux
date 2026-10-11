# =============================================================================
# CONFIGURACIÓN DEL HISTORIAL BASH (history.sh) - Manjaro Linux
# =============================================================================

export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%F %T "

shopt -s histappend
shopt -s cmdhist

export HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:history:bg:fg:..:..."

echo "✅ Historial Bash configurado (10k/20k líneas, ignorar duplicados)"
