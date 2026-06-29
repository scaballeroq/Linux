# =============================================================================
# CONFIGURACIÓN DEL HISTORIAL (history.sh)
# =============================================================================

export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%F %T "
shopt -s histappend
shopt -s cmdhist
export HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:history:bg:fg:..:..."

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Historial configurado"
