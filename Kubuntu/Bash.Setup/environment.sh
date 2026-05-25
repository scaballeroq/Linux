# =============================================================================
# VARIABLES DE ENTORNO (environment.sh)
# =============================================================================
# Este archivo define variables globales que afectan al comportamiento de
# la shell y de los programas que se ejecutan desde ella.

# -----------------------------------------------------------------------------
# 1. EDITORES DE TEXTO
# -----------------------------------------------------------------------------
# Define qué editor se abrirá por defecto (ej. al hacer git commit).
export EDITOR='nano'  # Editor principal en terminal
export VISUAL='nano'  # Editor visual (suele ser el mismo)

# -----------------------------------------------------------------------------
# 2. PAGINADOR (LESS)
# -----------------------------------------------------------------------------
# Configuración visual para 'less', el programa que te deja leer archivos largos.
# Se configuran colores para que las páginas de manual ('man') se vean bonitas.

export LESS='-R' # Interpretar secuencias de escape de color

# Códigos de color ANSI para 'man':
export LESS_TERMCAP_mb=$'\e[1;32m' # Parpadeo (verde)
export LESS_TERMCAP_md=$'\e[1;32m' # Negrita (verde)
export LESS_TERMCAP_me=$'\e[0m'    # Fin de modo
export LESS_TERMCAP_se=$'\e[0m'    # Fin de standout
export LESS_TERMCAP_so=$'\e[01;33m' # Standout (amarillo, barra de estado)
export LESS_TERMCAP_ue=$'\e[0m'    # Fin de subrayado
export LESS_TERMCAP_us=$'\e[1;4;31m' # Subrayado (rojo)

# Colores y opciones extra para páginas de manual
export MANPAGER="less -R --use-color -Dd+r -Du+b"

# -----------------------------------------------------------------------------
# 3. PATH (Rutas de ejecutables)
# -----------------------------------------------------------------------------
# Se añaden directorios personales al PATH para poder ejecutar scripts y
# programas instalados por el usuario sin escribir la ruta completa.

# Scripts personales en ~/.local/bin (estándar moderno)
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Scripts personales en ~/bin (estándar antiguo)
if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH"
fi

# Binarios de Go (Lenguaje Go)
if [ -d "$HOME/go/bin" ]; then
    export PATH="$HOME/go/bin:$PATH"
fi

# Binarios de Rust (Cargo)
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Activación de MISE (Gestor de lenguajes)
if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi

# Soporte para GPG en la terminal
export GPG_TTY=$(tty)

# -----------------------------------------------------------------------------
# 4. VARIOS
# -----------------------------------------------------------------------------
# Zona horaria (descomentar si es necesario forzarla)
# export TZ='Europe/Madrid'
# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Variables de entorno aplicadas (PATH, EDITOR, LESS...)"
