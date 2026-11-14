# =============================================================================
# VARIABLES DE ENTORNO (environment.sh) - Omarchy Workstation (Hyprland Wayland)
# =============================================================================
# Este archivo define variables de entorno globales para la sesión de usuario.

# -----------------------------------------------------------------------------
# 1. EDITORES Y VISUALIZADORES (Respeta omarchy-launch-editor si existe)
# -----------------------------------------------------------------------------
if command -v omarchy-launch-editor &> /dev/null; then
    export EDITOR="${EDITOR:-omarchy-launch-editor --inline}"
    export VISUAL="${VISUAL:-$EDITOR}"
elif command -v nvim &> /dev/null; then
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
# 2. INTEGRACIÓN WAYLAND, HYPRLAND, QT Y APLICACIONES ELECTRON
# -----------------------------------------------------------------------------
# Compatibilidad Qt/Wayland con integración Wayland nativa
export QT_QPA_PLATFORM="wayland;xcb"
export QT_AUTO_SCREEN_SCALE_FACTOR=1

# Firefox en modo Wayland nativo
export MOZ_ENABLE_WAYLAND=1

# Aceleración por hardware AMD Radeon (VA-API Mesa)
export LIBVA_DRIVER_NAME="radeonsi"

# uv (Python) en sistemas Linux
export UV_LINK_MODE="copy"

# JAVA_HOME canónico en Arch/Omarchy (archlinux-java / OpenJDK LTS)
if [ -d "/usr/lib/jvm/default" ]; then
    export JAVA_HOME="/usr/lib/jvm/default"
elif [ -d "/usr/lib/jvm/java-21-openjdk" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"
elif [ -d "/etc/alternatives/jre_openjdk" ]; then
    export JAVA_HOME="/etc/alternatives/jre_openjdk"
fi

# Forzar Wayland nativo en aplicaciones Electron (VS Code, Antigravity, Discord, Obsidian)
export ELECTRON_OZONE_PLATFORM_HINT="auto"

# -----------------------------------------------------------------------------
# 3. PATH PERSONALIZADO (Sin duplicados)
# -----------------------------------------------------------------------------
for p in "$HOME/.local/bin" "$HOME/bin" "$HOME/go/bin" "$HOME/.cargo/bin"; do
    if [ -d "$p" ]; then
        case ":$PATH:" in
            *":$p:"*) ;;
            *) export PATH="$p:$PATH" ;;
        esac
    fi
done

# -----------------------------------------------------------------------------
# 4. RUNTIMES Y CONTENEDORES
# -----------------------------------------------------------------------------
# Activación de MISE (Gestor de versiones de lenguajes)
if command -v mise &> /dev/null; then
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(mise activate bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(mise activate zsh)"
    fi
fi

# Soporte para GPG en la terminal (seguro para subshells y no-TTY)
export GPG_TTY="$(tty 2>/dev/null || true)"

# Podman Rootless Docker Host compatibility
if [ -S "$XDG_RUNTIME_DIR/podman/podman.sock" ]; then
    export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
fi

# -----------------------------------------------------------------------------
# 5. VIRTUALIZACIÓN Y VARIOS
# -----------------------------------------------------------------------------
# KVM / QEMU con conexión directa a sesión de sistema (virt-manager)
export LIBVIRT_DEFAULT_URI="qemu:///system"

# Rutas para actualización de Antigravity
export UPDATE_ANTIGRAVITY_PATH="/usr/local/bin/update-antigravity"
export UPDATE_ANTIGRAVITY_IDE_PATH="/usr/local/bin/update-antigravity-ide"
export UPDATE_ANTIGRAVITY_CLI_PATH="$HOME/.local/bin/update-antigravity-cli"
