# =============================================================================
# VARIABLES DE ENTORNO (environment.sh) - Soplos Linux Tyson
# =============================================================================
# Este archivo define variables globales que afectan al comportamiento de
# la shell y de los programas que se ejecutan desde ella.

# -----------------------------------------------------------------------------
# 1. EDITORES DE TEXTO
# -----------------------------------------------------------------------------
# Define qué editor se abrirá por defecto (ej. al hacer git commit).
export EDITOR='nano'  # Editor principal en terminal
export VISUAL='nano'  # Editor visual

# -----------------------------------------------------------------------------
# 2. PAGINADOR (LESS Y MAN)
# -----------------------------------------------------------------------------
# Configuración visual para 'less' y páginas del manual ('man').
export LESS='-R' # Interpretar secuencias de escape de color

# Códigos de color ANSI para 'man':
export LESS_TERMCAP_mb=$'\e[1;32m'   # Parpadeo (verde)
export LESS_TERMCAP_md=$'\e[1;32m'   # Negrita (verde)
export LESS_TERMCAP_me=$'\e[0m'      # Fin de modo
export LESS_TERMCAP_se=$'\e[0m'      # Fin de standout
export LESS_TERMCAP_so=$'\e[01;33m'  # Standout (amarillo, barra de estado)
export LESS_TERMCAP_ue=$'\e[0m'      # Fin de subrayado
export LESS_TERMCAP_us=$'\e[1;4;31m' # Subrayado (rojo)

# Colores y opciones extra para páginas de manual
export MANPAGER="less -R --use-color -Dd+r -Du+b"

# -----------------------------------------------------------------------------
# 3. PATH (Rutas de ejecutables)
# -----------------------------------------------------------------------------
# Función auxiliar para agregar rutas al PATH de forma limpia y sin duplicados
_add_to_path() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="$1:$PATH"
    fi
}

_add_to_path "$HOME/.local/bin" # Estándar moderno de binarios de usuario
_add_to_path "$HOME/bin"        # Estándar clásico de binarios de usuario
_add_to_path "$HOME/go/bin"     # Binarios de Go
_add_to_path "$HOME/.cargo/bin" # Binarios de Rust (Cargo)

unset -f _add_to_path

# -----------------------------------------------------------------------------
# 4. GESTORES DE RUNTIMES Y SEGURIDAD
# -----------------------------------------------------------------------------

# Activación de MISE (Gestor universal de lenguajes y runtimes)
if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi

# Soporte para GPG en terminal (solo si hay TTY interactiva asignada)
if [ -t 0 ]; then
    export GPG_TTY=$(tty 2>/dev/null || true)
fi

# -----------------------------------------------------------------------------
# 5. VARIABLES DE HERRAMIENTAS Y APLICACIONES
# -----------------------------------------------------------------------------
# Rutas para scripts de actualización de Google Antigravity
export UPDATE_ANTIGRAVITY_PATH="${UPDATE_ANTIGRAVITY_PATH:-/usr/local/bin/update-antigravity}"
export UPDATE_ANTIGRAVITY_IDE_PATH="${UPDATE_ANTIGRAVITY_IDE_PATH:-/usr/local/bin/update-antigravity-ide}"

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Variables de entorno aplicadas (PATH, EDITOR, LESS, MISE...)"
