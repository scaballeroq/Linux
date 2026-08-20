# =============================================================================
# VARIABLES DE ENTORNO (environment.zsh) - Adaptado para Manjaro Linux (ZSH)
# =============================================================================
# Este archivo define variables globales que afectan al comportamiento de
# la shell y de los programas que se ejecutan desde ella.

# -----------------------------------------------------------------------------
# 1. EDITORES DE TEXTO
# -----------------------------------------------------------------------------
export EDITOR='nano'
export VISUAL='nano'

# -----------------------------------------------------------------------------
# 2. PAGINADOR (LESS) Y PÁGINAS MAN EN COLOR
# -----------------------------------------------------------------------------
export LESS='-R'

# Códigos de color ANSI para 'man':
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
# Scripts personales en ~/.local/bin
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Scripts personales en ~/bin
if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH"
fi

# Binarios de Go
if [ -d "$HOME/go/bin" ]; then
    export PATH="$HOME/go/bin:$PATH"
fi

# Binarios de Rust (Cargo)
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Activación de MISE (Gestor de versiones y runtimes para ZSH)
if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
fi

# Soporte para GPG en la terminal
export GPG_TTY=$(tty 2>/dev/null || echo "")

# -----------------------------------------------------------------------------
# 4. RUTAS Y UTILIDADES
# -----------------------------------------------------------------------------
export UPDATE_ANTIGRAVITY_PATH="/usr/local/bin/update-antigravity"
export UPDATE_ANTIGRAVITY_IDE_PATH="/usr/local/bin/update-antigravity-ide"

echo "✅ Variables de entorno para ZSH aplicadas (PATH, EDITOR, LESS, Mise...)"
