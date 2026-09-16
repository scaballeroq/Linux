#!/bin/bash
# ==============================================================================
# shell.sh - Instalación de herramientas modernas de terminal para CachyOS
# (eza, bat, fzf, zoxide, ripgrep, fd, duf, dust, procs, btop, jq, zsh, starship)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🐚 Configurando utilidades modernas de terminal para CachyOS"
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# 1. Instalación de utilidades modernas de terminal y shells vía Pacman
echo "ℹ️ [1/5] Instalando utilidades CLI modernas, Zsh, plugins y Starship..."
$SUDO pacman -S --needed --noconfirm \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd \
    duf \
    dust \
    procs \
    btop \
    curl \
    git \
    jq \
    zsh \
    zsh-completions \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    starship 2>/dev/null || true

# 2. Integración en Zsh (~/.zshrc y ~/.zshrc.d)
echo "⚙️ [2/5] Configurando integración en Zsh (~/.zshrc y ~/.zshrc.d)..."
ZSHRC="$USER_HOME/.zshrc"
ZSHRC_D="$USER_HOME/.zshrc.d"

run_as_user touch "$ZSHRC"
run_as_user mkdir -p "$ZSHRC_D"

# 2.1. Zoxide en Zsh
if ! grep -q "zoxide init zsh" "$ZSHRC" 2>/dev/null; then
    echo -e '\n# Zoxide (Smart cd)\nif command -v zoxide &>/dev/null; then eval "$(zoxide init zsh)"; fi' | run_as_user tee -a "$ZSHRC" > /dev/null
    echo "  ✅ Zoxide integrado en ~/.zshrc"
fi

# 2.2. Starship en Zsh
if ! grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
    echo -e '\n# Starship Prompt\nif command -v starship &>/dev/null; then eval "$(starship init zsh)"; fi' | run_as_user tee -a "$ZSHRC" > /dev/null
    echo "  ✅ Starship prompt integrado en ~/.zshrc"
fi

# 2.3. Plugins de Zsh (Autosuggestions & Syntax Highlighting)
if ! grep -q "zsh-autosuggestions" "$ZSHRC" 2>/dev/null; then
    cat << 'INNER_EOF' | run_as_user tee -a "$ZSHRC" > /dev/null

# Plugins oficiales de Zsh
[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
INNER_EOF
    echo "  ✅ Plugins zsh-autosuggestions y syntax-highlighting añadidos a ~/.zshrc"
fi

# 2.4. Cargador modular en ~/.zshrc
if ! grep -q "\.zshrc\.d" "$ZSHRC" 2>/dev/null; then
    cat << 'INNER_EOF' | run_as_user tee -a "$ZSHRC" > /dev/null

# Carga modular de configuraciones y aliases (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script" > /dev/null
    done
    unset script
fi
INNER_EOF
    echo "  ✅ Cargador modular añadido a ~/.zshrc"
fi

# 3. Integración en Bash (Compatibilidad / Fallback)
echo "⚙️ [3/5] Configurando integración en Bash (~/.bashrc y ~/.bashrc.d)..."
BASHRC="$USER_HOME/.bashrc"
BASHRC_D="$USER_HOME/.bashrc.d"

run_as_user touch "$BASHRC"
run_as_user mkdir -p "$BASHRC_D"

# 3.1. Zoxide en Bash
if ! grep -q "zoxide init bash" "$BASHRC" 2>/dev/null; then
    echo -e '\n# Zoxide (Smart cd)\nif command -v zoxide &>/dev/null; then eval "$(zoxide init bash)"; fi' | run_as_user tee -a "$BASHRC" > /dev/null
    echo "  ✅ Zoxide integrado en ~/.bashrc"
fi

# 3.2. Starship en Bash
if ! grep -q "starship init bash" "$BASHRC" 2>/dev/null; then
    echo -e '\n# Starship Prompt\nif command -v starship &>/dev/null; then eval "$(starship init bash)"; fi' | run_as_user tee -a "$BASHRC" > /dev/null
    echo "  ✅ Starship prompt integrado en ~/.bashrc"
fi

# 3.3. Cargador modular en ~/.bashrc
if ! grep -q "\.bashrc\.d" "$BASHRC" 2>/dev/null; then
    cat << 'INNER_EOF' | run_as_user tee -a "$BASHRC" > /dev/null

# Carga modular de configuraciones y aliases (~/.bashrc.d)
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script" > /dev/null
    done
    unset script
fi
INNER_EOF
    echo "  ✅ Cargador modular añadido a ~/.bashrc"
fi

# 4. Enlazar scripts de Bash.Setup a ~/.zshrc.d y ~/.bashrc.d
echo "🔗 [4/5] Enlazando scripts modulares de Bash.Setup..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BASH_SETUP_DIR="$WORKSPACE_ROOT/Bash.Setup"

if [ -d "$BASH_SETUP_DIR" ]; then
    for sh_file in "$BASH_SETUP_DIR"/*.sh; do
        if [ -f "$sh_file" ]; then
            base_name="$(basename "$sh_file")"
            run_as_user ln -sf "$sh_file" "$ZSHRC_D/$base_name"
            run_as_user ln -sf "$sh_file" "$BASHRC_D/$base_name"
        fi
    done
    echo "  ✅ Scripts de Bash.Setup enlazados en ~/.zshrc.d/ y ~/.bashrc.d/"
fi

# 5. Directorios de binarios de usuario
run_as_user mkdir -p "$USER_HOME/.local/bin"

echo "================================================================="
echo "✅ Utilidades modernas de terminal y configuraciones listas para CachyOS:"
echo "  • Herramientas: eza, bat, fzf, zoxide, ripgrep, fd, duf, dust, btop, jq"
echo "  • Shells: Zsh & Bash con cargador modular (~/.zshrc.d/ y ~/.bashrc.d/)"
echo "  • Prompt: Starship con iconos Nerd Fonts y contexto git/lenguajes"
echo "  • Autocompletado y sintaxis: zsh-autosuggestions y zsh-syntax-highlighting"
echo "💡 Ejecuta 'source ~/.zshrc' o abre una nueva pestaña para disfrutar de tu entorno."
echo "================================================================="
