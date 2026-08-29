# =============================================================================
# VARIABLES DE ENTORNO (environment.sh) - Adaptado para CachyOS (KDE Plasma 6)
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
# 2. INTEGRACIÓN WAYLAND, QT Y APLICACIONES ELECTRON
# -----------------------------------------------------------------------------
# Compatibilidad Qt/Wayland con fallback automático a Xwayland
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

# Activación de MISE (Gestor de lenguajes)
if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi

# Soporte para GPG en la terminal (seguro para subshells y no-TTY)
export GPG_TTY="$(tty 2>/dev/null || true)"

# Podman Rootless Docker Host compatibility
if [ -S "$XDG_RUNTIME_DIR/podman/podman.sock" ]; then
    export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
fi

# -----------------------------------------------------------------------------
# 5. VARIOS
# -----------------------------------------------------------------------------
# Rutas para actualización de Antigravity
export UPDATE_ANTIGRAVITY_PATH="/usr/local/bin/update-antigravity"
export UPDATE_ANTIGRAVITY_IDE_PATH="/usr/local/bin/update-antigravity-ide"

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Variables de entorno aplicadas (PATH, EDITOR, LESS, Wayland/Qt...)"
