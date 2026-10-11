# =============================================================================
# OPCIONES DE LA SHELL (options.sh) - Soplos Linux Tyson
# =============================================================================
# Configura el comportamiento interno de la shell (Bash & Zsh compatible).

if [ -n "${BASH_VERSION:-}" ]; then
    # -----------------------------------------------------------------------------
    # 1. NAVEGACIÓN Y CORRECCIÓN DE ERRORES (BASH)
    # -----------------------------------------------------------------------------
    # cdspell: Corrige automáticamente pequeños errores tipográficos al hacer cd
    shopt -s cdspell 2>/dev/null || true

    # dirspell: Corrige errores tipográficos en nombres de carpetas al tabular
    shopt -s dirspell 2>/dev/null || true

    # autocd: Permite entrar en un directorio escribiendo únicamente su nombre
    shopt -s autocd 2>/dev/null || true

    # -----------------------------------------------------------------------------
    # 2. EXPANSIÓN DE ARCHIVOS (GLOBBING)
    # -----------------------------------------------------------------------------
    # globstar: Habilita el uso de '**' para búsqueda recursiva de archivos
    shopt -s globstar 2>/dev/null || true

    # -----------------------------------------------------------------------------
    # 3. INTERFAZ Y AJUSTE DE VENTANA
    # -----------------------------------------------------------------------------
    # checkwinsize: Actualiza las variables LINES y COLUMNS al cambiar el tamaño de ventana
    shopt -s checkwinsize 2>/dev/null || true

    # no_empty_cmd_completion: Evita autocompletar ejecutables si la línea está vacía
    shopt -s no_empty_cmd_completion 2>/dev/null || true

    # -----------------------------------------------------------------------------
    # 4. AUTOCOMPLETADO Y READLINE (BASH)
    # -----------------------------------------------------------------------------
    bind 'set completion-ignore-case on' 2>/dev/null || true
    bind 'set show-all-if-ambiguous on' 2>/dev/null || true
    bind 'set colored-stats on' 2>/dev/null || true
    bind 'set mark-symlinked-directories on' 2>/dev/null || true
elif [ -n "${ZSH_VERSION:-}" ]; then
    # Opciones equivalentes para Zsh
    setopt AUTO_CD 2>/dev/null || true
    setopt CORRECT 2>/dev/null || true
    setopt EXTENDED_GLOB 2>/dev/null || true
fi

# =============================================================================
# MENSAJE DE CARGA (Solo en sesiones interactivas)
# =============================================================================
[[ $- == *i* ]] && [ -t 1 ] && echo "✅ Opciones de Shell activadas (autocd, globstar, corrección de errores, tabuladores)" || true

