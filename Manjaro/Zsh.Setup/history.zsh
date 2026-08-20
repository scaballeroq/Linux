# =============================================================================
# CONFIGURACIÓN DEL HISTORIAL ZSH (history.zsh) - Manjaro Linux
# =============================================================================
# Controla el almacenamiento, sincronización y formato del historial en ZSH.

# Archivo de historial
export HISTFILE="$HOME/.zsh_history"

# Cantidad de comandos en memoria y en disco (50.000 comandos)
export HISTSIZE=50000
export SAVEHIST=50000

# Opciones avanzadas de ZSH para el historial:
setopt EXTENDED_HISTORY          # Guarda timestamp de ejecución y duración
setopt HIST_EXPIRE_DUPS_FIRST   # Expira duplicados primero al llenar el límite
setopt HIST_IGNORE_DUPS         # No guarda comandos repetidos consecutivos
setopt HIST_IGNORE_ALL_DUPS     # Elimina instancias antiguas si se re-ejecuta
setopt HIST_FIND_NO_DUPS        # No muestra duplicados al buscar hacia atrás
setopt HIST_IGNORE_SPACE        # No guarda comandos que empiecen con espacio
setopt HIST_SAVE_NO_DUPS        # Omite comandos duplicados al escribir a disco
setopt HIST_VERIFY              # Muestra comando expandido antes de ejecutar (!)
setopt SHARE_HISTORY            # Comparte historial en tiempo real entre terminales

echo "✅ Historial ZSH configurado (50k líneas, timestamps, share_history)"
