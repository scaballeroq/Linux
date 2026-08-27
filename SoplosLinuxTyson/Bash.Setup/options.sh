# =============================================================================
# OPCIONES DE LA SHELL (options.sh) - Soplos Linux Tyson
# =============================================================================
# Configura el comportamiento interno de Bash mediante 'shopt' y 'bind'.

# -----------------------------------------------------------------------------
# 1. NAVEGACIÓN Y CORRECCIÓN DE ERRORES
# -----------------------------------------------------------------------------

# cdspell: Corrige automáticamente pequeños errores tipográficos al hacer cd
# Ej: 'cd Dcouments' -> te lleva a 'Documents'.
shopt -s cdspell

# dirspell: Corrige errores tipográficos en nombres de carpetas al tabular
shopt -s dirspell 2>/dev/null || true

# autocd: Permite entrar en un directorio escribiendo únicamente su nombre
# Ej: Escribir 'Downloads' ejecuta 'cd Downloads'.
shopt -s autocd

# -----------------------------------------------------------------------------
# 2. EXPANSIÓN DE ARCHIVOS (GLOBBING)
# -----------------------------------------------------------------------------

# globstar: Habilita el uso de '**' para búsqueda recursiva de archivos
# Ej: 'ls **/*.txt' busca archivos .txt en el directorio actual y subdirectorios.
shopt -s globstar

# -----------------------------------------------------------------------------
# 3. INTERFAZ Y AJUSTE DE VENTANA
# -----------------------------------------------------------------------------

# checkwinsize: Actualiza las variables LINES y COLUMNS al cambiar el tamaño de ventana
shopt -s checkwinsize

# no_empty_cmd_completion: Evita autocompletar ejecutables si la línea está vacía
shopt -s no_empty_cmd_completion 2>/dev/null || true

# -----------------------------------------------------------------------------
# 4. AUTOCOMPLETADO Y READLINE
# -----------------------------------------------------------------------------

# completion-ignore-case: Ignora diferencias entre mayúsculas y minúsculas al tabular
bind 'set completion-ignore-case on' 2>/dev/null || true

# show-all-if-ambiguous: Muestra coincidencias de inmediato sin esperar un segundo TAB
bind 'set show-all-if-ambiguous on' 2>/dev/null || true

# colored-stats: Colorea los tipos de archivo en las sugerencias de autocompletado
bind 'set colored-stats on' 2>/dev/null || true

# mark-symlinked-directories: Añade '/' a los enlaces simbólicos hacia carpetas al autocompletar
bind 'set mark-symlinked-directories on' 2>/dev/null || true

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Opciones de Shell activadas (autocd, globstar, corrección de errores, tabuladores)"

