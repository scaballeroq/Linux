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

# 2. EXTENSION DEL PATH (De forma no duplicada)
for p in "$HOME/.local/bin" "$HOME/bin" "$HOME/.cargo/bin" "$HOME/go/bin" "$HOME/.local/share/mise/shims"; do
    if [ -d "$p" ] && [[ ":$PATH:" != *":$p:"* ]]; then
        export PATH="$p:$PATH"
    fi
done

# 3. WAYLAND / QT / ELECTRON EN KUBUNTU
export QT_QPA_PLATFORM="wayland;xcb"
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT="auto"

# 4. NODEJS COREPACK (Evitar prompts interactivos de descarga en terminal)
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# 5. PODMAN DOCKER HOST INTEGRATION
if [ -S "/run/user/$(id -u)/podman/podman.sock" ]; then
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
fi

# 6. COLORES Y FORMATO PARA 'LESS' Y 'MAN'
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;36m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS="-R -F -X"
export PAGER="less"

# 7. IDIOMA Y LOCALIZACION
export LANG="${LANG:-es_ES.UTF-8}"
export LC_ALL="${LC_ALL:-es_ES.UTF-8}"
