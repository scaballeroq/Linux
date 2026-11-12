# =============================================================================
# OPCIONES DE LA SHELL (options.sh) - Adaptado para Bash y Zsh en Omarchy Workstation
# =============================================================================
# Configura el comportamiento interno de la shell (navegación, globbing y completado).

if [ -n "${BASH_VERSION:-}" ]; then
    # -------------------------------------------------------------------------
    # CONFIGURACIÓN PARA BASH (Predeterminada)
    # -------------------------------------------------------------------------
    # cdspell: Intenta corregir pequeños errores tipográficos en los comandos cd.
    shopt -s cdspell 2>/dev/null || true

    # autocd: Permite entrar en un directorio escribiendo solo su nombre.
    shopt -s autocd 2>/dev/null || true

    # globstar: Habilita el uso de '**' para buscar de forma recursiva.
    shopt -s globstar 2>/dev/null || true

    # checkwinsize: Verifica el tamaño de la ventana después de cada comando.
    shopt -s checkwinsize 2>/dev/null || true

    # Autocompletado Readline (solo interactivo)
    if [[ $- == *i* ]]; then
        bind 'set completion-ignore-case on' 2>/dev/null || true
        bind 'set show-all-if-ambiguous on' 2>/dev/null || true
        bind 'set colored-stats on' 2>/dev/null || true
    fi

elif [ -n "${ZSH_VERSION:-}" ]; then
    # -------------------------------------------------------------------------
    # CONFIGURACIÓN PARA ZSH (Compatibilidad)
    # -------------------------------------------------------------------------
    # Navegación y directorios
    setopt AUTO_CD              2>/dev/null || true # Entrar a un directorio escribiendo solo su nombre
    setopt CORRECT              2>/dev/null || true # Sugerir corrección de pequeños errores tipográficos
    setopt AUTO_PUSHD           2>/dev/null || true # Mantener stack de directorios con cada cd
    setopt PUSHD_IGNORE_DUPS    2>/dev/null || true # Evitar duplicados en el stack de directorios
    setopt NO_CASE_GLOB         2>/dev/null || true # Globbing insensible a mayúsculas/minúsculas
    setopt EXTENDED_GLOB        2>/dev/null || true # Habilitar globbing avanzado (recursividad con **)
    setopt INTERACTIVE_COMMENTS 2>/dev/null || true # Permitir comentarios '#' en la terminal interactiva

    # Autocompletado inteligente en Zsh (solo si la sesión es interactiva)
    if [[ -o interactive ]] 2>/dev/null; then
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 2>/dev/null || true
        zstyle ':completion:*' menu select 2>/dev/null || true
        zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" 2>/dev/null || true
        zstyle ':completion:*' group-name '' 2>/dev/null || true
        zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f' 2>/dev/null || true
    fi
fi
