#!/usr/bin/env bash
# ==============================================================================
# zsh-setup.sh - Instalación y Replicación del Entorno Zsh en Debian
# Sistema: Debian GNU/Linux 13 (Trixie) | Escritorio: GNOME Shell (Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM)
# ==============================================================================
# Características:
#   - Instalación de Zsh, zsh-autosuggestions y zsh-syntax-highlighting vía APT.
#   - Recreación fiel de la configuración de ~/.zshrc de Soplos Linux Boro:
#       * Prompt estético Powerline con glifos (, ), colores 256 y bloque Git interactivo.
#       * Esquema de colores para resaltado de sintaxis (comandos naranja, strings amarillo).
#       * Sugerencias automáticas en gris tenue (#555555).
#       * Historial deduplicado y sincronizado (10.000 comandos).
#       * Integración de FZF (Ctrl+R, Ctrl+T, Alt+C) y Zoxide (smart cd).
#       * Integración con socket de Podman Rootless y shims de Mise.
#   - Estructura modular en ~/.zshrc.d/:
#       * Enlaces simbólicos a los módulos de Debian/Bash.Setup/*.sh.
#       * Módulos dedicados: java.zsh, mise.zsh, nodejs.zsh, podman.zsh, python.zsh, virtualization.zsh.
#   - Opciones CLI: --status / -s, --default-shell / -d, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PRIVILEGIOS
# ------------------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" USER="$REAL_USER" "$@"
    else
        "$@"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BASH_SETUP_DIR="$WORKSPACE_ROOT/Bash.Setup"

ZSHRC="$USER_HOME/.zshrc"
ZSHRC_D="$USER_HOME/.zshrc.d"

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🐚 Replicador y Configurador del Entorno Zsh - Debian Workstation
(Recrea la experiencia de terminal moderna de Soplos Linux Boro)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala paquetes APT requeridos, genera ~/.zshrc completo,
                         configura ~/.zshrc.d/ con symlinks y módulos de entorno.
  --status, -s           Muestra el diagnóstico de Zsh, plugins instalados,
                         estado de ~/.zshrc y módulos activos en ~/.zshrc.d/.
  --default-shell, -d    Configura Zsh como el intérprete de comandos predeterminado del usuario.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Prompt:              Powerline con glifo de energía (), flechas () e información Git.
  • Resaltado y Suger:   zsh-syntax-highlighting y zsh-autosuggestions nativos de Debian.
  • Búsqueda y Naveg:    FZF (Ctrl+R para historial, Ctrl+T para archivos) y Zoxide (comando 'z').
  • Arquitectura:        Carga modular en ~/.zshrc.d/ vinculada a Bash.Setup/.
  • Runtimes:            Integración con Mise, Python ('uv'), Node.js, OpenJDK y Podman rootless.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL ENTORNO ZSH - DEBIAN WORKSTATION"
    echo "================================================================="
    local cur_shell
    cur_shell=$(getent passwd "$REAL_USER" | cut -d: -f7 2>/dev/null || echo "$SHELL")
    echo "• Usuario:                      $REAL_USER (UID $REAL_UID)"
    echo "• Shell predeterminada:         $cur_shell $([ "$cur_shell" = "$(command -v zsh 2>/dev/null)" ] && echo "✅ (Zsh)" || echo "ℹ️ (No es Zsh)")"
    echo "-----------------------------------------------------------------"
    echo "📦 Paquetes oficiales APT:"
    for pkg in zsh zsh-autosuggestions zsh-syntax-highlighting fzf zoxide eza bat; do
        if dpkg -s "$pkg" &>/dev/null; then
            local ver
            ver=$(dpkg -s "$pkg" 2>/dev/null | grep -i "^Version:" | awk '{print $2}' || echo "instalado")
            printf "  • %-26s ✅ Instalado (v%s)\n" "$pkg" "$ver"
        else
            printf "  • %-26s ❌ No instalado\n" "$pkg"
        fi
    done
    echo "-----------------------------------------------------------------"
    echo "📄 Archivos de configuración:"
    echo "  • ~/.zshrc:                   $([ -f "$ZSHRC" ] && echo "✅ Presente ($(wc -l < "$ZSHRC") líneas)" || echo "❌ Ausente")"
    echo "  • Directorio ~/.zshrc.d/:     $([ -d "$ZSHRC_D" ] && echo "✅ Presente" || echo "❌ Ausente")"
    if [ -d "$ZSHRC_D" ]; then
        local count_links count_zsh
        count_links=$(find "$ZSHRC_D" -maxdepth 1 -type l 2>/dev/null | wc -l)
        count_zsh=$(find "$ZSHRC_D" -maxdepth 1 -type f -name "*.zsh" 2>/dev/null | wc -l)
        echo "    - Enlaces simbólicos (Bash.Setup): $count_links archivos"
        echo "    - Módulos específicos (.zsh):      $count_zsh archivos"
    fi
    echo "-----------------------------------------------------------------"
    echo "🔌 Plugins del sistema:"
    echo "  • Syntax Highlighting:        $([ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && echo "✅ Disponible" || echo "❌ No encontrado")"
    echo "  • Autosuggestions:            $([ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && echo "✅ Disponible" || echo "❌ No encontrado")"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. CAMBIAR SHELL PREDETERMINADA
# ------------------------------------------------------------------------------
set_default_shell() {
    local zsh_bin
    zsh_bin=$(command -v zsh 2>/dev/null || echo "/usr/bin/zsh")

    if [ ! -x "$zsh_bin" ]; then
        echo "❌ Error: Zsh no está instalado en el sistema. Ejecuta primero la instalación."
        exit 1
    fi

    local current_shell
    current_shell=$(getent passwd "$REAL_USER" | cut -d: -f7 2>/dev/null || echo "$SHELL")

    if [ "$current_shell" = "$zsh_bin" ]; then
        echo "✅ Zsh ya es el shell predeterminado para el usuario '$REAL_USER'."
        return 0
    fi

    echo "⚙️ Configurando '$zsh_bin' como shell predeterminado para '$REAL_USER'..."
    if ! grep -Fxq "$zsh_bin" /etc/shells; then
        echo "$zsh_bin" | $SUDO tee -a /etc/shells > /dev/null
    fi

    $SUDO chsh -s "$zsh_bin" "$REAL_USER"
    echo "✅ Shell predeterminado actualizado a Zsh. Se aplicará en el próximo inicio de sesión."
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN Y REPLICACIÓN DE CONFIGURACIÓN
# ------------------------------------------------------------------------------
deploy_zsh() {
    echo "================================================================="
    echo "🐚 CONFIGURANDO ENTORNO ZSH ESTILO SOPLOS LINUX EN DEBIAN"
    echo "================================================================="

    # 1. Instalar paquetes de Zsh y utilidades modernas
    echo "ℹ️ [1/5] Instalando paquetes de Zsh y herramientas CLI..."
    local required_pkgs=(
        zsh
        zsh-autosuggestions
        zsh-syntax-highlighting
        fzf
        zoxide
        eza
        bat
        fd-find
        ripgrep
        btop
        curl
        git
        jq
    )

    local to_install=()
    for pkg in "${required_pkgs[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo "  ⬇️ Instalando dependencias vía APT: ${to_install[*]}..."
        $SUDO apt-get update -qq
        $SUDO apt-get install -y "${to_install[@]}" 2>/dev/null || true
        echo "  ✅ Paquetes instalados."
    else
        echo "  ✅ Todos los paquetes requeridos ya están instalados."
    fi

    # 2. Symlinks para bat y fd en ~/.local/bin
    echo "ℹ️ [2/5] Asegurando symlinks en ~/.local/bin (bat y fd)..."
    run_as_user mkdir -p "$USER_HOME/.local/bin"
    if command -v batcat &>/dev/null && [ ! -e "$USER_HOME/.local/bin/bat" ]; then
        run_as_user ln -sf "$(command -v batcat)" "$USER_HOME/.local/bin/bat"
    fi
    if command -v fdfind &>/dev/null && [ ! -e "$USER_HOME/.local/bin/fd" ]; then
        run_as_user ln -sf "$(command -v fdfind)" "$USER_HOME/.local/bin/fd"
    fi

    # 3. Respaldo de ~/.zshrc previo si existe y es diferente
    if [ -f "$ZSHRC" ] && ! grep -q "ZSH_HIGHLIGHT_STYLES" "$ZSHRC" 2>/dev/null; then
        local backup_path="${ZSHRC}.bak.$(date +%Y%m%d_%H%M%S)"
        echo "ℹ️ [3/5] Respaldando archivo .zshrc existente en: $backup_path"
        run_as_user cp "$ZSHRC" "$backup_path"
    else
        echo "ℹ️ [3/5] Generando configuración de ~/.zshrc..."
    fi

    # Escribir el ~/.zshrc idéntico al de Soplos Linux Boro (con resolución dinámica de UID)
    cat << 'EOF' | run_as_user tee "$ZSHRC" > /dev/null
# =============================================================================
# ZSH CONFIGURATION (.zshrc) - Debian Workstation (GNOME Shell Wayland)
# Replicado del perfil estético de Soplos Linux Boro
# =============================================================================

# Desactivar pitidos auditivos
unsetopt BEEP

# Aliases base
alias ls='ls --color=auto'

# Historial optimizado
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS SHARE_HISTORY

# Autocompletado nativo
autoload -Uz compinit && compinit

# Resaltado de sintaxis (zsh-syntax-highlighting)
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ZSH_HIGHLIGHT_STYLES[command]='fg=#ff7d2e'
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=#ff7d2e'
    ZSH_HIGHLIGHT_STYLES[function]='fg=#ff7d2e'
    ZSH_HIGHLIGHT_STYLES[keyword]='fg=#ef5a33'
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#fec431'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#fec431'
    ZSH_HIGHLIGHT_STYLES[comment]='fg=#555555'
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ee5a6f'
fi

# Sugerencias automáticas en segundo plano (zsh-autosuggestions)
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#555555'
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Prompt interactivo Powerline con Git Status
autoload -U colors && colors

_SEP=$''
_BOLT=$''

_git_info() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        echo -n " %K{yellow}%F{black}${_SEP} ${branch} %f%k%F{yellow}${_SEP}%f"
    else
        echo -n " %K{green}%F{black}${_SEP} ${branch} %f%k%F{green}${_SEP}%f"
    fi
}

setopt PROMPT_SUBST
PROMPT='%K{202}%F{yellow} ${_BOLT}%F{black} %n@%m %f%k%F{202}%K{238}${_SEP}%F{white} %~ %f%k%F{238}${_SEP}%f$(_git_info) '

# Zoxide (Smart cd)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# FZF (Fuzzy Finder: Ctrl+R, Ctrl+T, Alt+C y completion)
if command -v fzf &>/dev/null; then
    eval "$(fzf --zsh 2>/dev/null || true)"
fi

# Carga modular de configuraciones y aliases (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi

# Podman Docker API Integration (Socket rootless dinámico)
export DOCKER_HOST="unix:///run/user/${UID:-$(id -u)}/podman/podman.sock"

# Rutas de autocompletado fpath
fpath=($HOME/.local/share/zsh/site-functions $HOME/.zfunc $fpath)
EOF
    echo "  ✅ ~/.zshrc generado con éxito."

    # 4. Crear ~/.zshrc.d y enlazar scripts de Bash.Setup
    echo "ℹ️ [4/5] Configurando directorio modular ~/.zshrc.d/..."
    run_as_user mkdir -p "$ZSHRC_D" "$USER_HOME/.local/share/zsh/site-functions" "$USER_HOME/.zfunc"

    # Limpiar symlinks rotos
    run_as_user find -L "$ZSHRC_D" -maxdepth 1 -type l -exec rm -f {} + 2>/dev/null || true

    if [ -d "$BASH_SETUP_DIR" ]; then
        for sh_file in "$BASH_SETUP_DIR"/*.sh; do
            if [ -f "$sh_file" ]; then
                local base_name
                base_name="$(basename "$sh_file")"
                run_as_user ln -sf "$sh_file" "$ZSHRC_D/$base_name"
            fi
        done
        echo "  ✅ Scripts de Bash.Setup enlazados en ~/.zshrc.d/ ($(find "$ZSHRC_D" -maxdepth 1 -type l | wc -l) enlaces)."
    fi

    # 5. Generar módulos específicos (.zsh) en ~/.zshrc.d/
    echo "ℹ️ [5/5] Creando módulos de entorno para lenguajes y servicios..."

    # 5.1. Java
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/java.zsh" > /dev/null
# OpenJDK Environment & Optimizations
if [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
elif [ -d "/usr/lib/jvm/default-java" ]; then
    export JAVA_HOME="/usr/lib/jvm/default-java"
fi

if [ -n "${JAVA_HOME:-}" ] && [ -d "${JAVA_HOME}/bin" ]; then
    [[ ":$PATH:" != *":${JAVA_HOME}/bin:"* ]] && export PATH="${JAVA_HOME}/bin:$PATH"
fi

export _JAVA_AWT_WM_NONREPARENTING=1
export JDK_JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"
export MAVEN_ARGS="-T 1C"
export MAVEN_OPTS="-Xms512m -Xmx4096m -XX:+UseG1GC"
EOF

    # 5.2. Mise
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/mise.zsh" > /dev/null
# =============================================================================
# MISE VERSION MANAGER (Zsh Shell Activation)
# =============================================================================
if [ -x "$HOME/.local/bin/mise" ] || command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi
EOF

    # 5.3. Node.js
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/nodejs.zsh" > /dev/null
# Node.js & Corepack Environment Settings
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export JOBS=16
export npm_config_jobs=16
EOF

    # 5.4. Podman
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/podman.zsh" > /dev/null
# Podman Docker API Integration
export DOCKER_HOST="unix:///run/user/${UID:-$(id -u)}/podman/podman.sock"

# PATH para utilidades de usuario
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
EOF

    # 5.5. Python
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/python.zsh" > /dev/null
# Python & uv Environment Settings (Debian Workstation)
export PYTHONUNBUFFERED=1
export UV_LINK_MODE="copy"
EOF

    # 5.6. Virtualización KVM
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/virtualization.zsh" > /dev/null
# Configuración KVM/QEMU conectando al daemon de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF

    echo "  ✅ Módulos .zsh creados (java, mise, nodejs, podman, python, virtualization)."

    echo ""
    show_status
    echo "================================================================="
    echo "✅ Entorno Zsh replicado con éxito en Debian."
    echo "💡 Para probarlo de inmediato, ejecuta:  zsh"
    echo "💡 Para fijarlo como shell por defecto:  $0 --default-shell"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 5. ENTRADA PRINCIPAL
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --default-shell|-d)
        set_default_shell
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        deploy_zsh
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
