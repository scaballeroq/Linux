#!/bin/bash
# ==============================================================================
# shell.sh - Instalación de herramientas modernas de terminal para CachyOS
# (eza, bat, fzf, zoxide, ripgrep, fd, duf, dust, procs, btop, jq)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🐚 Configurando utilidades modernas de terminal para CachyOS"
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no esta disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecucion con sudo
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

# 1. Instalación de utilidades modernas de terminal vía Pacman
echo "ℹ️ [1/3] Instalando utilidades CLI modernas..."
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
    jq 2>/dev/null || true

# 2. Integración de Zoxide (Smart cd) en Zsh
echo "⚙️ [2/3] Configurando integración de Zoxide en Zsh..."
ZSHRC="$USER_HOME/.zshrc"
run_as_user touch "$ZSHRC"

if ! grep -q "zoxide init zsh" "$ZSHRC" 2>/dev/null; then
    echo -e '\n# Zoxide (Smart cd)\nif command -v zoxide &>/dev/null; then eval "$(zoxide init zsh)"; fi' | run_as_user tee -a "$ZSHRC" > /dev/null
    echo "  ✅ Zoxide integrado en ~/.zshrc"
else
    echo "  ℹ️ Zoxide ya estaba presente en ~/.zshrc"
fi

# 3. Verificación de directorios de usuario
echo "🔗 [3/3] Verificando directorios de usuario..."
run_as_user mkdir -p "$USER_HOME/.local/bin"

echo "================================================================="
echo "✅ Utilidades modernas de terminal configuradas con éxito para CachyOS:"
echo "  • Herramientas: eza, bat, fzf, zoxide, ripgrep, fd, duf, dust, btop, jq"
echo "  • Shell activa: Zsh (CachyOS Powerlevel10k + Zoxide)"
echo "💡 Nota: Starship está disponible como opción en ./Setup/starship.sh"
echo "================================================================="
