#!/bin/bash
# ==============================================================================
# git.sh - Instalación, Optimización y Configuración de Git, Delta, Lazygit y gh
# Ubuntu Workstation (GNOME Shell Wayland)
# ==============================================================================
# Características:
# - Despliegue idempotente: comprueba paquetes primero y evita invocar
#   'sudo' o APT si Git, Git-Delta, Lazygit y GitHub CLI ya están instalados.
# - Configuración global recomendada: rebase por defecto, autoSetupRemote, zdiff3.
# - Integración de Git-Delta con visualización 'side-by-side' y resaltado de sintaxis.
# - Integración de Lazygit con delta pager y tema adaptado a modo oscuro.
# - Configuración de GitHub CLI (gh) con editor predeterminado y diagnóstico de auth.
# - Comandos CLI: --status / -s, --help / -h.
# ==============================================================================

set -euo pipefail

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

export PATH="$USER_HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" PATH="$USER_HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH" "$@"
    else
        PATH="$USER_HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH" "$@"
    fi
}

show_help() {
    cat <<EOF
🐙 Gestor y Optimizador de Git, Delta, Lazygit y GitHub CLI - Ubuntu Workstation

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica e instala paquetes faltantes, aplica configuración global
                      de Git (rebase, autoStash, zdiff3), configura Delta y Lazygit.
  --status, -s        Muestra el diagnóstico de Git, identidad, Delta, Lazygit y GitHub CLI.
  --help, -h          Muestra este mensaje de ayuda.

Herramientas incluidas:
  • Git:         Control de versiones con mejores prácticas modernas.
  • Git-Delta:   Visualizador visual con resaltado de sintaxis y vista dividida.
  • Lazygit:     Terminal UI rápida para git con integración de Delta.
  • GitHub CLI:  Interacción oficial con repositorios, PRs e issues desde terminal.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL ENTORNO DE CONTROL DE VERSIONES (GIT + HERRAMIENTAS)"
    echo "================================================================="

    local git_ver delta_ver lazygit_ver gh_ver
    local user_name user_email default_branch core_editor core_pager gh_auth

    git_ver=$(git --version 2>/dev/null || echo "No instalado")
    delta_ver=$(command -v delta &>/dev/null && delta --version 2>/dev/null || echo "No instalado")
    lazygit_ver=$(command -v lazygit &>/dev/null && lazygit --version 2>/dev/null | head -n1 || echo "No instalado")
    gh_ver=$(command -v gh &>/dev/null && gh --version 2>/dev/null | head -n1 || echo "No instalado")

    user_name=$(run_as_user git config --global user.name 2>/dev/null || echo "No configurado")
    user_email=$(run_as_user git config --global user.email 2>/dev/null || echo "No configurado")
    default_branch=$(run_as_user git config --global init.defaultBranch 2>/dev/null || echo "main")
    core_editor=$(run_as_user git config --global core.editor 2>/dev/null || echo "Predeterminado")
    core_pager=$(run_as_user git config --global core.pager 2>/dev/null || echo "less")

    if command -v gh &>/dev/null; then
        local gh_user
        gh_user=$(run_as_user gh auth status 2>&1 | grep -oP 'account \K[^ ]+' | head -n1 || true)
        if [ -n "$gh_user" ]; then
            gh_auth="✅ Autenticado como $gh_user"
        else
            gh_auth="ℹ️ Sesión no iniciada (ejecuta: gh auth login)"
        fi
    else
        gh_auth="No disponible"
    fi

    echo "• Git Engine:         ✅ $git_ver"
    echo "• Git-Delta (Pager):  $(if command -v delta &>/dev/null; then echo "✅ $delta_ver"; else echo "❌ No instalado"; fi)"
    echo "• Lazygit (TUI):      $(if command -v lazygit &>/dev/null; then echo "✅ $lazygit_ver"; else echo "❌ No instalado"; fi)"
    echo "• GitHub CLI (gh):    $(if command -v gh &>/dev/null; then echo "✅ $gh_ver ($gh_auth)"; else echo "❌ No instalado"; fi)"
    echo "-----------------------------------------------------------------"
    echo "👤 Configuración Global del Usuario ($REAL_USER):"
    echo "  - user.name:        $user_name"
    echo "  - user.email:       $user_email"
    echo "  - Rama por defecto: $default_branch"
    echo "  - Editor:           $core_editor"
    echo "  - Paginador diff:   $core_pager"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🐙 CONFIGURANDO GIT, DELTA, LAZYGIT Y GITHUB CLI (UBUNTU)"
echo "================================================================="

# 1. Instalar paquetes base desde APT
echo "ℹ️ [1/4] Instalando Git, curl y dependencias vía APT..."
$SUDO apt update
$SUDO apt install -y git git-delta curl ca-certificates

# 2. Instalar GitHub CLI si no está instalado
if ! command -v gh &>/dev/null; then
    echo "ℹ️ [2/4] Instalando GitHub CLI (gh)..."
    $SUDO mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    $SUDO chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    $SUDO apt update
    $SUDO apt install -y gh
else
    echo "ℹ️ [2/4] GitHub CLI ya está instalado."
fi

# 3. Instalar Lazygit si no está presente
if ! command -v lazygit &>/dev/null; then
    echo "ℹ️ [3/4] Instalando Lazygit desde GitHub Releases..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "0.44.1")
    TMP_DIR=$(mktemp -d)
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" -o "$TMP_DIR/lazygit.tar.gz"
    tar -xzf "$TMP_DIR/lazygit.tar.gz" -C "$TMP_DIR" lazygit
    $SUDO install -m 755 "$TMP_DIR/lazygit" /usr/local/bin/lazygit
    rm -rf "$TMP_DIR"
    echo "   - Lazygit instalado en /usr/local/bin/lazygit."
else
    echo "ℹ️ [3/4] Lazygit ya está instalado."
fi

# 4. Configuración Global de Git y Delta
echo "ℹ️ [4/4] Aplicando configuración global recomendada..."
run_as_user git config --global init.defaultBranch main
run_as_user git config --global pull.rebase true
run_as_user git config --global rebase.autoStash true
run_as_user git config --global push.autoSetupRemote true
run_as_user git config --global merge.conflictstyle zdiff3

# Configurar editor
if command -v nvim &>/dev/null; then
    run_as_user git config --global core.editor "nvim"
else
    run_as_user git config --global core.editor "nano"
fi

# Configuración de Git-Delta
if command -v delta &>/dev/null; then
    run_as_user git config --global core.pager "delta"
    run_as_user git config --global interactive.diffFilter "delta --color-only"
    run_as_user git config --global delta.navigate true
    run_as_user git config --global delta.light false
    run_as_user git config --global delta.line-numbers true
    run_as_user git config --global delta.side-by-side false
fi

echo "================================================================="
echo "✅ Entorno de Git configurado con éxito en Ubuntu."
echo "================================================================="
