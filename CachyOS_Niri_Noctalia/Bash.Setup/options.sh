# =============================================================================
# OPCIONES DE LA SHELL (options.sh) - Adaptado para Zsh y Bash en CachyOS
# =============================================================================
# Configura el comportamiento interno de la shell (navegación, globbing y completado).

if [ -n "${ZSH_VERSION:-}" ]; then
    # -------------------------------------------------------------------------
    # CONFIGURACIÓN PARA ZSH
    # -------------------------------------------------------------------------
    # Navegación y directorios
    setopt AUTO_CD              # Entrar a un directorio escribiendo solo su nombre
    setopt CORRECT              # Sugerir corrección de pequeños errores tipográficos
    setopt AUTO_PUSHD           # Mantener stack de directorios con cada cd
    setopt PUSHD_IGNORE_DUPS    # Evitar duplicados en el stack de directorios
    setopt NO_CASE_GLOB         # Globbing insensible a mayúsculas/minúsculas
    setopt EXTENDED_GLOB        # Habilitar globbing avanzado (recursividad con **)
    setopt INTERACTIVE_COMMENTS # Permitir comentarios '#' en la terminal interactiva

    # Autocompletado inteligente en Zsh (solo si la sesión es interactiva)
    if [[ -o interactive ]]; then
        # Ignorar mayúsculas/minúsculas y permitir coincidencias parciales
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
        # Menú de autocompletado interactivo navegable con flechas
        zstyle ':completion:*' menu select
        # Colorear listas de completado usando variables LS_COLORS
        zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
        # Agrupar coincidencias por categoría
        zstyle ':completion:*' group-name ''
        zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
    fi

elif [ -n "${BASH_VERSION:-}" ]; then
    # -------------------------------------------------------------------------
    # CONFIGURACIÓN PARA BASH
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
fi

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Opciones de Shell activadas"

