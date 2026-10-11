# =============================================================================
# OPCIONES DE LA SHELL (options.sh)
# =============================================================================
# Configura el comportamiento interno de Bash mediante 'shopt' y 'bind'.

# -----------------------------------------------------------------------------
# NAVEGACIÓN Y ERRORES
# -----------------------------------------------------------------------------

# cdspell: Intenta corregir pequeños errores tipográficos en los comandos cd.
# Ej: 'cd Dcouments' -> te lleva a 'Documents'.
shopt -s cdspell

# dirspell: Intenta corregir errores tipográficos en nombres de directorio al autocompletar.
shopt -s dirspell 2>/dev/null || true

# autocd: Permite entrar en un directorio escribiendo solo su nombre.
# Ej: Escribir 'Downloads' hace 'cd Downloads'.
shopt -s autocd

# -----------------------------------------------------------------------------
# EXPANSIÓN DE ARCHIVOS (GLOBBING)
# -----------------------------------------------------------------------------

# globstar: Habilita el uso de '**' para buscar de forma recursiva.
# Ej: 'ls **/*.txt' busca archivos .txt en el directorio actual y subdirectorios.
shopt -s globstar

# -----------------------------------------------------------------------------
# INTERFAZ Y VENTANA
# -----------------------------------------------------------------------------

# checkwinsize: Verifica el tamaño de la ventana después de cada comando.
# Útil si redimensionas la terminal a menudo, para que el texto se ajuste bien.
shopt -s checkwinsize

# no_empty_cmd_completion: No intentar autocompletar en una línea vacía.
shopt -s no_empty_cmd_completion 2>/dev/null || true

# -----------------------------------------------------------------------------
# AUTOCOMPLETADO (Solo en sesiones interactivas)
# -----------------------------------------------------------------------------
if [[ $- == *i* ]] && [ -t 0 ]; then
    # completion-ignore-case: Ignorar mayúsculas/minúsculas al tabular.
    bind 'set completion-ignore-case on' 2>/dev/null || true

    # show-all-if-ambiguous: Mostrar lista de opciones inmediatamente si hay varias.
    bind 'set show-all-if-ambiguous on' 2>/dev/null || true

    # colored-stats: Usar colores para mostrar los tipos de archivos en las sugerencias.
    bind 'set colored-stats on' 2>/dev/null || true
fi

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Opciones de Shell activadas (autocd, globstar, corrección errores...)"
