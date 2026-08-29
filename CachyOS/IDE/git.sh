#!/bin/bash
# ==============================================================================
# git.sh - Instalación y Optimización de Git, Git-Delta, Lazygit y GitHub CLI
# ==============================================================================
# Plataforma: CachyOS / Arch Linux (KDE Plasma)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🐙 Configurando entorno de Git, Delta, Lazygit y GitHub CLI..."
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

# 1. Instalación de paquetes mediante Pacman
echo "ℹ️ [1/3] Instalando Git, Git-Delta, Lazygit y GitHub CLI vía Pacman..."
$SUDO pacman -S --needed --noconfirm \
    git \
    git-delta \
    lazygit \
    github-cli 2>/dev/null || true

# 2. Configuración Global de Git y Delta (Ejecutada como usuario real)
echo "ℹ️ [2/3] Aplicando configuración global y mejores prácticas modernas de Git..."
GIT_USER_NAME="${GIT_USER_NAME:-Sergio Caballero}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-scaballeroq@gmail.com}"

# Identidad del desarrollador
run_as_user git config --global user.name "$GIT_USER_NAME"
run_as_user git config --global user.email "$GIT_USER_EMAIL"

# Flujo de trabajo y ramas
run_as_user git config --global init.defaultBranch main
run_as_user git config --global pull.rebase true
run_as_user git config --global rebase.autoStash true
run_as_user git config --global push.autoSetupRemote true
run_as_user git config --global fetch.prune true
run_as_user git config --global core.editor "nvim"

# Visualización y productividad en consola
run_as_user git config --global column.ui auto
run_as_user git config --global branch.sort -committerdate
run_as_user git config --global diff.colorMoved default
run_as_user git config --global merge.conflictstyle zdiff3

# Configuración de Git-Delta (Diferencias legibles y resaltado de sintaxis)
run_as_user git config --global core.pager "delta"
run_as_user git config --global interactive.diffFilter "delta --color-only"
run_as_user git config --global delta.navigate true
run_as_user git config --global delta.light false
run_as_user git config --global delta.side-by-side true
run_as_user git config --global delta.line-numbers true
run_as_user git config --global delta.hyperlinks true

# 3. Configuración de GitHub CLI (gh)
echo "ℹ️ [3/3] Configurando opciones predeterminadas de GitHub CLI (gh)..."
if command -v gh &>/dev/null; then
    run_as_user gh config set editor "nvim" 2>/dev/null || true
    run_as_user gh config set git_protocol "ssh" 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Entorno de Git configurado con éxito:"
echo "  • Git:        $(git --version 2>/dev/null || echo 'instalado')"
echo "  • Git-Delta:  $(delta --version 2>/dev/null || echo 'instalado')"
echo "  • Lazygit:    $(lazygit --version 2>/dev/null | head -n1 || echo 'instalado')"
echo "  • GitHub CLI: $(gh --version 2>/dev/null | head -n1 || echo 'instalado')"
echo "================================================================="
