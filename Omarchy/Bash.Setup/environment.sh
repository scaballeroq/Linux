# =============================================================================
# VARIABLES DE ENTORNO (environment.sh)
# =============================================================================
# Este archivo define variables globales que afectan al comportamiento de
# la shell y de los programas que se ejecutan desde ella.

# -----------------------------------------------------------------------------
# 1. EDITORES DE TEXTO
# -----------------------------------------------------------------------------
export EDITOR='nano'
export VISUAL='nano'

# -----------------------------------------------------------------------------
# 2. PAGINADOR (LESS)
# -----------------------------------------------------------------------------
export LESS='-R'

export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

export MANPAGER="less -R --use-color -Dd+r -Du+b"

# -----------------------------------------------------------------------------
# 3. PATH (Rutas de ejecutables)
# -----------------------------------------------------------------------------
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/go/bin" ]; then
    export PATH="$HOME/go/bin:$PATH"
fi

if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# -----------------------------------------------------------------------------
# 4. VARIOS
# -----------------------------------------------------------------------------
# export TZ='Europe/Madrid'
# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Variables de entorno"
