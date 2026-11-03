#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  zsh-setup.sh - Replicación y Configuración Integral de Zsh en Fedora 45 Workstation
#  Basado en la arquitectura modular de Bash.Setup + Plugins nativos + Starship
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

if [[ $EUID -eq 0 ]]; then
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
else
    REAL_USER="${USER:-$(whoami)}"
fi
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"

ZSHRC_FILE="$USER_HOME/.zshrc"
ZSHRC_D="$USER_HOME/.zshrc.d"
SET_DEFAULT_SHELL=false
ACTION="install"

show_help() {
    cat << EOF
${BOLD}🐚 Configurador Integral de Zsh - Fedora 45 Workstation (GNOME Wayland)${NC}

Instala Zsh, plugins nativos (autosuggestions, syntax-highlighting), integraciones
modernas (FZF, Zoxide, Mise, Starship) y genera la arquitectura modular en ${BOLD}~/.zshrc.d/${NC}
adaptada a Fedora 45 y DNF5.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)     Instala paquetes y despliega ~/.zshrc y ~/.zshrc.d/*.zsh
  -d, --default-shell  Establece /bin/zsh como shell por defecto del usuario ($REAL_USER)
  -s, --status         Muestra el estado actual de Zsh, plugins y módulos en ~/.zshrc.d
  -h, --help           Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🐚 ${BOLD}ESTADO DEL ENTORNO ZSH - FEDORA 45 WORKSTATION ($REAL_USER)${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if command -v zsh &>/dev/null; then
        echo -e "  • Binario Zsh:               ${GREEN}$(zsh --version)${NC}"
    else
        echo -e "  • Binario Zsh:               ${RED}No instalado${NC}"
    fi

    local current_shell
    current_shell=$(getent passwd "$REAL_USER" | cut -d: -f7)
    if [[ "$current_shell" == *"zsh"* ]]; then
        echo -e "  • Shell por defecto:         ${GREEN}${current_shell} (Zsh activo)${NC}"
    else
        echo -e "  • Shell por defecto:         ${CYAN}${current_shell}${NC} (usa --default-shell para cambiar a Zsh)"
    fi

    for pkg in zsh-autosuggestions zsh-syntax-highlighting fzf zoxide eza bat fd-find ripgrep util-linux-user; do
        if rpm -q "$pkg" &>/dev/null; then
            echo -e "  • Paquete $(printf '%-23s' "$pkg"): ${GREEN}Instalado${NC}"
        else
            echo -e "  • Paquete $(printf '%-23s' "$pkg"): ${YELLOW}No instalado${NC}"
        fi
    done

    if [[ -f "$ZSHRC_FILE" ]]; then
        echo -e "  • Archivo ~/.zshrc:          ${GREEN}Configurado${NC}"
    else
        echo -e "  • Archivo ~/.zshrc:          ${YELLOW}No existe${NC}"
    fi

    if [[ -d "$ZSHRC_D" ]]; then
        local count
        count=$(find "$ZSHRC_D" -maxdepth 1 -name "*.zsh" | wc -l)
        echo -e "  • Módulos en ~/.zshrc.d/:    ${GREEN}${count} módulos activos${NC}"
    else
        echo -e "  • Módulos en ~/.zshrc.d/:    ${YELLOW}Directorio no creado${NC}"
    fi
    echo -e "${BOLD}======================================================================${NC}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)        ACTION="status"; shift ;;
        -d|--default-shell) SET_DEFAULT_SHELL=true; shift ;;
        -h|--help)          show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
fi

log_info "Verificando e instalando paquetes Zsh y utilidades CLI en Fedora 45 ($DNF_BIN)..."
ZSH_PKGS=(
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    util-linux-user
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
    wl-clipboard
)

MISSING_PKGS=()
for p in "${ZSH_PKGS[@]}"; do
    rpm -q "$p" &>/dev/null || MISSING_PKGS+=("$p")
done

if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
    sudo "$DNF_BIN" install -y "${MISSING_PKGS[@]}"
else
    log_ok "Todos los paquetes base para Zsh ya están instalados."
fi

mkdir -p "$ZSHRC_D" "$USER_HOME/.cache/zsh"

if [[ -f "$ZSHRC_FILE" ]] && ! grep -q "Configuración Modular Zsh - Fedora 45 Workstation" "$ZSHRC_FILE" 2>/dev/null; then
    cp "$ZSHRC_FILE" "${ZSHRC_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    log_info "Backup de ~/.zshrc previo creado."
fi

log_info "Generando $ZSHRC_FILE para Fedora 45 Workstation..."
cat << 'EOF' > "$ZSHRC_FILE"
# ==============================================================================
#  ~/.zshrc - Configuración Modular Zsh - Fedora 45 Workstation (GNOME Wayland)
# ==============================================================================

# Si no es interactivo, salir inmediatamente
[[ -o interactive ]] || return

# Variables de entorno base y XDG
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$HOME/bin:$PATH"
export EDITOR="nano"
export VISUAL="nano"
export SYSTEMD_EDITOR="nano"

# Opciones avanzadas de navegación e historial en Zsh
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

mkdir -p "$HOME/.cache/zsh"
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

# Inicialización de sistema de autocompletado Zsh con caché
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Teclas estándar (Home, End, Delete, Ctrl+Flechas, búsqueda por prefijo)
bindkey -e
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# Cargar módulos personalizados desde ~/.zshrc.d/*.zsh
if [[ -d "$HOME/.zshrc.d" ]]; then
    for config_file in "$HOME/.zshrc.d"/*.zsh(N); do
        [[ -r "$config_file" ]] && source "$config_file"
    done
fi

# Plugins nativos de Fedora (zsh-autosuggestions y zsh-syntax-highlighting)
if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Integración con FZF
if command -v fzf &>/dev/null; then
    source <(fzf --zsh 2>/dev/null) || {
        [[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && source /usr/share/fzf/shell/key-bindings.zsh
    }
fi

# Integración con Zoxide
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# Integración con Mise (gestor polyglot de runtimes)
if [[ -x "$HOME/.local/bin/mise" ]]; then
    eval "$("$HOME/.local/bin/mise" activate zsh)"
elif command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi

# Prompt: Starship si está instalado, o prompt Powerline nativo con estado Git
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
else
    autoload -Uz vcs_info
    precmd() { vcs_info }
    zstyle ':vcs_info:git:*' formats ' (%b)'
    setopt PROMPT_SUBST
    PROMPT='%F{blue}%B%n@%m%b%f:%F{cyan}%~%f%F{yellow}${vcs_info_msg_0_}%f %# '
fi
EOF

log_info "Generando módulos en $ZSHRC_D/ adaptados a Fedora 45 y DNF5..."

cat << 'EOF' > "$ZSHRC_D/aliases.zsh"
# ==============================================================================
#  aliases.zsh - Aliases para Fedora 45 Workstation (DNF5, Git, Firewalld, CLI)
# ==============================================================================

# Navegación y listado moderno con eza
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lh --icons --group-directories-first --git'
    alias la='eza -lah --icons --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -lh --color=auto'
    alias la='ls -lah --color=auto'
fi

# Bat y fd en Fedora
command -v bat &>/dev/null && alias cat='bat --paging=never'
alias grep='grep --color=auto'
alias df='df -h'
alias free='free -h'
alias reload='source ~/.zshrc && echo "✅ Configuración Zsh recargada (Fedora 45)"'

# Portapapeles nativo Wayland
if command -v wl-copy &>/dev/null; then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste'
fi

# Gestión de paquetes DNF5 + Flatpak + Mise en Fedora 45
alias update='sudo dnf5 check-upgrade --refresh'
alias upgrade='sudo dnf5 upgrade --refresh -y && flatpak update -y'
alias install='sudo dnf5 install -y'
alias remove='sudo dnf5 remove -y'
alias search='dnf5 search'
alias pkginfo='dnf5 info'
alias clean='sudo dnf5 autoremove -y && sudo dnf5 clean all && flatpak uninstall --unused -y'
alias update-all='sudo dnf5 upgrade --refresh -y && flatpak update -y && (~/.local/bin/mise upgrade 2>/dev/null || true)'

# Firewalld obligatorio
alias fw-status='sudo firewall-cmd --state && sudo firewall-cmd --list-all'
alias fw-reload='sudo firewall-cmd --reload'
alias fw-ports='sudo firewall-cmd --list-ports && sudo firewall-cmd --list-services'

# Git
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull --rebase'
alias glog='git log --oneline --graph --decorate -n 20'
command -v lazygit &>/dev/null && alias lg='lazygit'
EOF

cat << 'EOF' > "$ZSHRC_D/environment.zsh"
# ==============================================================================
#  environment.zsh - Variables para GNOME Wayland, VA-API, Podman y Libvirt
# ==============================================================================

export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT="auto"
export QT_QPA_PLATFORM="wayland;xcb"
export QT_QPA_PLATFORMTHEME="gnome"
export LIBVA_DRIVER_NAME="radeonsi"
export UV_LINK_MODE="copy"
export LIBVIRT_DEFAULT_URI="qemu:///system"

# Socket de Podman Rootless
if [[ -n "${XDG_RUNTIME_DIR:-}" && -S "${XDG_RUNTIME_DIR}/podman/podman.sock" ]]; then
    export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/podman/podman.sock"
fi

# JAVA_HOME canónico en Fedora 45 (OpenJDK 21+)
if [[ -d "/usr/lib/jvm/java-21-openjdk" ]]; then
    export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"
elif [[ -d "/etc/alternatives/jre_openjdk" ]]; then
    export JAVA_HOME="/etc/alternatives/jre_openjdk"
fi
EOF

# Copiar módulos compatibles desde Bash.Setup si existen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
for mod in functions gnome_settings podman-functions rclone_aliases yt-dlp_aliases; do
    if [[ -f "$REPO_ROOT/Bash.Setup/${mod}.sh" ]]; then
        cp "$REPO_ROOT/Bash.Setup/${mod}.sh" "$ZSHRC_D/${mod}.zsh"
    fi
done

if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
    chown -R "$REAL_USER:$REAL_USER" "$ZSHRC_FILE" "$ZSHRC_D" "$USER_HOME/.cache/zsh"
fi

if [[ "$SET_DEFAULT_SHELL" == true ]]; then
    ZSH_PATH=$(command -v zsh)
    log_info "Configurando $ZSH_PATH como shell predeterminada para $REAL_USER..."
    sudo usermod -s "$ZSH_PATH" "$REAL_USER"
    log_ok "Shell predeterminada actualizada a $ZSH_PATH."
fi

log_ok "Entorno Zsh configurado correctamente para Fedora 45 Workstation."
show_status
