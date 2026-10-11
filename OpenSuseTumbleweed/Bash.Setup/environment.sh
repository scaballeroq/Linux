# =============================================================================
# VARIABLES DE ENTORNO (environment.sh) - OpenSUSE Tumbleweed (KDE Plasma)
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

# -----------------------------------------------------------------------------
# 3. PATH PERSONALIZADO
# -----------------------------------------------------------------------------
# Scripts personales del usuario
if [ -d "$HOME/bin" ] && [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    export PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# -----------------------------------------------------------------------------
# 4. LENGUAJES Y RUNTIMES
# -----------------------------------------------------------------------------
# Cargo / Rust
if [ -d "$HOME/.cargo/bin" ] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Go
if [ -d "$HOME/go/bin" ] && [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
    export PATH="$HOME/go/bin:$PATH"
fi

# Shims de Mise
if [ -d "$HOME/.local/share/mise/shims" ] && [[ ":$PATH:" != *":$HOME/.local/share/mise/shims:"* ]]; then
    export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

# -----------------------------------------------------------------------------
# 5. INTEGRACIÓN DE CONTENEDORES Y VIRTUALIZACIÓN
# -----------------------------------------------------------------------------
# Socket de Podman rootless compatible con Docker CLI y extensiones DevContainers
if [ -z "${DOCKER_HOST:-}" ] && [ -S "/run/user/$UID/podman/podman.sock" ]; then
    export DOCKER_HOST="unix:///run/user/$UID/podman/podman.sock"
fi

# Conexión por defecto de virsh / virt-manager al hipervisor KVM de sistema
export LIBVIRT_DEFAULT_URI="qemu:///system"

# -----------------------------------------------------------------------------
# 6. ACTIVACIÓN AUTOMÁTICA DE MISE
# -----------------------------------------------------------------------------
if command -v mise &> /dev/null; then
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(mise activate bash --shims)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(mise activate zsh --shims)"
    fi
fi

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Variables de entorno cargadas"
