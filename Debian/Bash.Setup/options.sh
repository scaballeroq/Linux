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

# -----------------------------------------------------------------------------
# AUTOCOMPLETADO
# -----------------------------------------------------------------------------

# completion-ignore-case: Ignorar mayúsculas/minúsculas al tabular.
# Ej: Escribir 'cd doc<TAB>' completará 'Documents'.
bind 'set completion-ignore-case on'

# show-all-if-ambiguous: Mostrar lista de opciones inmediatamente si hay varias,
# en lugar de esperar a una segunda pulsación de TAB.
bind 'set show-all-if-ambiguous on'

# colored-stats: Usar colores para mostrar lso tipos de archivos en las
# sugerencias de autocompletado.
bind 'set colored-stats on'
# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Opciones de Shell activadas (autocd, globstar, corrección errores...)"
