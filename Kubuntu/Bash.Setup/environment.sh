#!/bin/bash
# =============================================================================
# VARIABLES DE ENTORNO (environment.sh) - Kubuntu
# =============================================================================

# 1. EDITOR PREDETERMINADO
if command -v nvim &> /dev/null; then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif command -v nano &> /dev/null; then
    export EDITOR="nano"
    export VISUAL="nano"
fi

# 2. EXTENSION DEL PATH
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi
if [ -d "$HOME/go/bin" ]; then
    export PATH="$HOME/go/bin:$PATH"
fi
if [ -d "$HOME/.local/share/mise/shims" ]; then
    export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

# 3. WAYLAND / QT / ELECTRON
export QT_QPA_PLATFORM="wayland;xcb"
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT="auto"

# 4. COLORES Y FORMATO PARA 'LESS' Y 'MAN'
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;36m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS="-R -F -X"
export PAGER="less"

# 5. IDIOMA Y LOCALIZACION
export LANG="${LANG:-es_ES.UTF-8}"
export LC_ALL="${LC_ALL:-es_ES.UTF-8}"

# =============================================================================
echo "Variables de entorno aplicadas"
