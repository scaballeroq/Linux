#!/bin/bash
# ==============================================================================
# git.sh - Instalación y Optimización de Git, Git-Delta, Lazygit y GitHub CLI
# ==============================================================================
# Plataforma: openSUSE Tumbleweed (KDE Plasma 6)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🐙 Configurando entorno de Git, Delta, Lazygit y GitHub CLI..."
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

# 1. Instalación de paquetes mediante Zypper (Git, Delta, gh, Lazygit)
echo "ℹ️ [1/3] Instalando Git, Git-Delta y GitHub CLI vía Zypper..."
$SUDO zypper --non-interactive install -y git git-delta gh 2>/dev/null || $SUDO zypper --non-interactive install -y git gh 2>/dev/null || true

# Instalación de Lazygit
if ! command -v lazygit &> /dev/null; then
    echo "ℹ️ Instalando Lazygit..."
    if ! $SUDO zypper --non-interactive install -y lazygit 2>/dev/null; then
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64) LAZYGIT_ARCH="x86_64" ;;
            aarch64) LAZYGIT_ARCH="arm64" ;;
            *) echo "❌ Arquitectura no soportada para Lazygit: $ARCH"; exit 1 ;;
        esac
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "")
        if [ -n "$LAZYGIT_VERSION" ]; then
            curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
            tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
            $SUDO install /tmp/lazygit /usr/local/bin
            rm -f /tmp/lazygit /tmp/lazygit.tar.gz
            echo "  • Lazygit instalado manualmente en /usr/local/bin."
        fi
    fi
fi

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

# Editor preferido para Git (detección inteligente)
DEFAULT_EDITOR="nano"
if command -v nvim &>/dev/null; then
    DEFAULT_EDITOR="nvim"
elif command -v kate &>/dev/null; then
    DEFAULT_EDITOR="kate"
elif command -v micro &>/dev/null; then
    DEFAULT_EDITOR="micro"
elif command -v vim &>/dev/null; then
    DEFAULT_EDITOR="vim"
fi

run_as_user git config --global core.editor "$DEFAULT_EDITOR"

# Visualización y productividad en consola
run_as_user git config --global column.ui auto
run_as_user git config --global branch.sort -committerdate
run_as_user git config --global diff.colorMoved default
run_as_user git config --global merge.conflictstyle zdiff3

# Configuración de Git-Delta (Diferencias legibles y resaltado de sintaxis)
if command -v delta &>/dev/null; then
    run_as_user git config --global core.pager "delta"
    run_as_user git config --global interactive.diffFilter "delta --color-only"
    run_as_user git config --global delta.navigate true
    run_as_user git config --global delta.light false
    run_as_user git config --global delta.side-by-side true
    run_as_user git config --global delta.line-numbers true
    run_as_user git config --global delta.hyperlinks true
fi

# 3. Configuración de GitHub CLI (gh)
echo "ℹ️ [3/3] Configurando opciones predeterminadas de GitHub CLI (gh)..."
if command -v gh &>/dev/null; then
    run_as_user gh config set editor "$DEFAULT_EDITOR" 2>/dev/null || true
    run_as_user gh config set git_protocol "ssh" 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Entorno de Git configurado con éxito:"
echo "  • Git:        $(git --version 2>/dev/null || echo 'instalado')"
echo "  • Git-Delta:  $(delta --version 2>/dev/null || echo 'instalado')"
echo "  • Lazygit:    $(lazygit --version 2>/dev/null | head -n1 || echo 'instalado')"
echo "  • GitHub CLI: $(gh --version 2>/dev/null | head -n1 || echo 'instalado')"
echo "================================================================="
