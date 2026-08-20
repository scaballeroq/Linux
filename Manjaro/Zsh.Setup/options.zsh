# =============================================================================
# OPCIONES DE LA SHELL ZSH (options.zsh) - Manjaro Linux
# =============================================================================
# Configura el comportamiento interno de ZSH mediante 'setopt' y 'zstyle'.

# -----------------------------------------------------------------------------
# 1. NAVEGACIÓN Y DIRECTORIOS
# -----------------------------------------------------------------------------
setopt AUTO_CD              # Escribir solo el nombre de un directorio entra en él
setopt AUTO_PUSHD           # Mantiene el stack de directorios al hacer cd
setopt PUSHD_IGNORE_DUPS    # No duplica directorios en el stack
setopt PUSHD_SILENT         # No imprime el stack en cada cd

# -----------------------------------------------------------------------------
# 2. EXPANSIÓN Y GLOBBING (PATRONES)
# -----------------------------------------------------------------------------
setopt EXTENDED_GLOB        # Habilita operadores avanzados como ^, ~, #
setopt NO_CASE_GLOB         # Globbing insensible a mayúsculas/minúsculas
setopt NUMERIC_GLOB_SORT    # Ordena numéricamente (1, 2, 10 en lugar de 1, 10, 2)
setopt NO_CLOBBER           # Evita sobreescribir archivos con > accidentalmente (usar >!)

# -----------------------------------------------------------------------------
# 3. INTERACCIÓN Y ENTORNO
# -----------------------------------------------------------------------------
setopt INTERACTIVE_COMMENTS # Permite usar # para comentarios en modo interactivo
setopt PROMPT_SUBST         # Expande variables y funciones dentro del prompt
setopt NO_BEEP              # Desactiva el pitido molesto de la terminal

# -----------------------------------------------------------------------------
# 4. AUTOCOMPLETADO INTELIGENTE (ZSTYLE)
# -----------------------------------------------------------------------------
if [ -n "$ZSH_VERSION" ]; then
    autoload -Uz compinit && compinit -C 2>/dev/null || true
    
    # Autocompletado insensible a mayúsculas y flexible
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
    
    # Menú de selección interactivo con flechas
    zstyle ':completion:*' menu select
    
    # Colores en las sugerencias de archivos
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    
    # Agrupación y formato de descripciones
    zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
    zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
    zstyle ':completion:*:warnings' format '%F{red}-- Sin coincidencias --%f'
fi

echo "✅ Opciones de Shell ZSH activadas (autocd, extended globbing, zstyle...)"
