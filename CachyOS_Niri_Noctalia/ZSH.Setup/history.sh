# =============================================================================
# CONFIGURACIÓN DEL HISTORIAL (history.sh) - Adaptado para Zsh en CachyOS
# =============================================================================
# Controla el guardado, deduplicación y sincronización de comandos en Zsh.

if [ -n "${ZSH_VERSION:-}" ]; then
    # -------------------------------------------------------------------------
    # CONFIGURACIÓN PARA ZSH
    # -------------------------------------------------------------------------
    export HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
    export HISTSIZE=50000
    export SAVEHIST=50000

    # Comportamiento avanzado del historial en Zsh
    setopt EXTENDED_HISTORY        # Guarda marca de tiempo y duración de ejecución
    setopt APPEND_HISTORY          # Añadir al historial en vez de sobrescribir
    setopt INC_APPEND_HISTORY      # Guardar cada comando inmediatamente al ejecutarse
    setopt SHARE_HISTORY           # Compartir historial en tiempo real entre múltiples terminales
    setopt HIST_IGNORE_DUPS        # No registrar comandos consecutivos repetidos
    setopt HIST_IGNORE_ALL_DUPS    # Si se repite un comando, eliminar la ocurrencia anterior
    setopt HIST_IGNORE_SPACE       # Ignorar comandos que comiencen con espacio
    setopt HIST_SAVE_NO_DUPS       # No guardar duplicados en el archivo en disco
    setopt HIST_EXPIRE_DUPS_FIRST  # Eliminar duplicados primero si el historial se llena
    setopt HIST_FIND_NO_DUPS       # No mostrar duplicados al buscar en el historial
    setopt HIST_REDUCE_BLANKS      # Eliminar espacios en blanco sobrantes antes de guardar
    setopt HIST_VERIFY             # Permitir revisar el comando antes de ejecutarlo con '!'

    # Comandos a ignorar en el historial
    export HISTORY_IGNORE="(ls|ll|la|lt|tree|cd|cd ..|pwd|exit|clear|c|h|history|bg|fg|..|...|....|~)"

elif [ -n "${BASH_VERSION:-}" ]; then
    # -------------------------------------------------------------------------
    # CONFIGURACIÓN PARA BASH
    # -------------------------------------------------------------------------
    export HISTFILE="${HISTFILE:-$HOME/.bash_history}"
    export HISTSIZE=10000
    export HISTFILESIZE=20000
    export HISTCONTROL=ignoreboth:erasedups
    export HISTTIMEFORMAT="%F %T "

    shopt -s histappend 2>/dev/null || true
    shopt -s cmdhist 2>/dev/null || true

    export HISTIGNORE="ls:ll:la:lt:tree:cd:pwd:exit:clear:c:h:history:bg:fg:..:...:....:~"
fi

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Historial configurado"

