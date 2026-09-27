# =============================================================================
# VARIABLES DE ENTORNO (environment.sh) - NixOS (KDE Plasma 6 Wayland)
# =============================================================================
# Este archivo define variables de entorno globales para la sesión de usuario.

# -----------------------------------------------------------------------------
# 1. EDITORES Y VISUALIZADORES
# -----------------------------------------------------------------------------
if command -v nvim &> /dev/null; then
    export EDITOR='nvim'
    export VISUAL='nvim'
else
    export EDITOR='nano'
    export VISUAL='nano'
fi

export PAGER='less'

# Opciones para 'less' (colores, búsqueda insensible a mayúsculas si todo es minúscula)
export LESS='-R -i'

# Colores para 'man' usando less (estilo moderno)
export LESS_TERMCAP_mb=$'\E[1;31m'
export LESS_TERMCAP_md=$'\E[1;36m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_us=$'\E[1;32m'
export LESS_TERMCAP_ue=$'\E[0m'

# -----------------------------------------------------------------------------
# 2. INTEGRACIÓN WAYLAND, KDE PLASMA, QT Y APLICACIONES ELECTRON
# -----------------------------------------------------------------------------
# Backend gráfico Wayland prioritario
export GDK_BACKEND="wayland,x11,*"

# Compatibilidad Qt/Wayland nativo en KDE Plasma 6
export QT_QPA_PLATFORM="wayland;xcb"
export QT_AUTO_SCREEN_SCALE_FACTOR=1

# Firefox en modo Wayland nativo
export MOZ_ENABLE_WAYLAND=1

# Forzar Wayland nativo en aplicaciones Electron (VS Code, Antigravity, Discord, Obsidian)
export ELECTRON_OZONE_PLATFORM_HINT="auto"
export NIXOS_OZONE_WL=1

# -----------------------------------------------------------------------------
# 3. PATH PERSONALIZADO Y NIX ENTORNO
# -----------------------------------------------------------------------------
# Rutas prioritarias de usuario y Nix
paths_to_add=(
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.nix-profile/bin"
    "/run/current-system/sw/bin"
    "$HOME/.cargo/bin"
)

for p in "${paths_to_add[@]}"; do
    if [ -d "$p" ] && [[ ":$PATH:" != *":$p:"* ]]; then
        export PATH="$p:$PATH"
    fi
done

# -----------------------------------------------------------------------------
# 4. LENGUAJES Y RUNTIMES
# -----------------------------------------------------------------------------
# Gestor de versiones Mise (si está disponible)
if command -v mise &> /dev/null; then
    if [ -n "$BASH_VERSION" ]; then
        eval "$(mise activate bash 2>/dev/null || true)"
    elif [ -n "$ZSH_VERSION" ]; then
        eval "$(mise activate zsh 2>/dev/null || true)"
    fi
elif [ -x "$HOME/.local/bin/mise" ]; then
    if [ -n "$BASH_VERSION" ]; then
        eval "$("$HOME/.local/bin/mise" activate bash 2>/dev/null || true)"
    elif [ -n "$ZSH_VERSION" ]; then
        eval "$("$HOME/.local/bin/mise" activate zsh 2>/dev/null || true)"
    fi
fi

# Python UV
export UV_PYTHON_PREFERENCE="managed"

# Rust / Cargo
export CARGO_HOME="$HOME/.cargo"

# -----------------------------------------------------------------------------
# 5. CONTENEDORES Y VIRTUALIZACIÓN
# -----------------------------------------------------------------------------
# Compatibilidad Docker API con Podman rootless
if [ -z "${DOCKER_HOST:-}" ]; then
    if [ -S "/run/user/$UID/podman/podman.sock" ]; then
        export DOCKER_HOST="unix:///run/user/$UID/podman/podman.sock"
    fi
fi

# Conexión por defecto de Libvirt/KVM para usuarios en el grupo libvirtd
export LIBVIRT_DEFAULT_URI="qemu:///system"
