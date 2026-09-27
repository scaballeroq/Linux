#!/usr/bin/env bash
# ==============================================================================
# git.sh - Configuración y Diagnóstico de Git, Delta, Lazygit y gh en NixOS
# ==============================================================================

set -euo pipefail

# Detección de usuario
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

show_help() {
    cat <<EOF
🐙 Gestor y Optimizador de Git, Delta, Lazygit y GitHub CLI - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica configuración global recomendada de Git, Delta y Lazygit.
  --status, -s        Comprueba el estado de Git, identidad, Delta, Lazygit y GitHub CLI.
  --help, -h          Muestra este mensaje de ayuda.

Nota para NixOS:
  Las herramientas Git, Delta, Lazygit y gh están declaradas en:
    modules/development.nix
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE GIT, DELTA, LAZYGIT Y GITHUB CLI - NIXOS"
    echo "================================================================="
    echo -n "• Git: "
    if command -v git &>/dev/null; then
        echo "✅ $(git --version)"
    else
        echo "❌ No instalado"
    fi

    echo -n "• Identidad Git: "
    local gname gemail
    gname=$(git config --global user.name 2>/dev/null || echo "")
    gemail=$(git config --global user.email 2>/dev/null || echo "")
    if [ -n "$gname" ] && [ -n "$gemail" ]; then
        echo "✅ $gname <$gemail>"
    else
        echo "⚠️ Incompleta ($gname | $gemail)"
    fi

    echo -n "• Git-Delta (side-by-side): "
    if command -v delta &>/dev/null; then
        echo "✅ $(delta --version 2>/dev/null || echo 'instalado')"
    else
        echo "ℹ️ No disponible en PATH"
    fi

    echo -n "• Lazygit (TUI): "
    if command -v lazygit &>/dev/null; then
        echo "✅ $(lazygit --version | head -n1)"
    else
        echo "ℹ️ No disponible en PATH"
    fi

    echo -n "• GitHub CLI (gh): "
    if command -v gh &>/dev/null; then
        echo "✅ $(gh --version | head -n1)"
    else
        echo "ℹ️ No disponible en PATH"
    fi
    echo "================================================================="
}

configure_git() {
    echo "⚙️ Configurando opciones globales de Git..."

    run_as_user git config --global init.defaultBranch "develop"
    run_as_user git config --global pull.rebase false
    run_as_user git config --global push.autoSetupRemote true
    run_as_user git config --global merge.conflictstyle "zdiff3"

    # Identidad predeterminada si no existe
    if [ -z "$(git config --global user.name 2>/dev/null || true)" ]; then
        run_as_user git config --global user.name "Sergio Caballero"
        run_as_user git config --global user.email "scaballeroq@gmail.com"
        echo "✅ Identidad Git asignada: Sergio Caballero <scaballeroq@gmail.com>"
    fi

    # Configuración de Git Delta si está disponible
    if command -v delta &>/dev/null; then
        echo "🎨 Configurando Git-Delta como visualizador por defecto..."
        run_as_user git config --global core.pager "delta"
        run_as_user git config --global interactive.diffFilter "delta --color-only"
        run_as_user git config --global delta.navigate true
        run_as_user git config --global delta.light false
        run_as_user git config --global delta.side-by-side true
        run_as_user git config --global delta.line-numbers true
    fi

    # Configurar Lazygit config si no existe
    local lazygit_dir="$USER_HOME/.config/lazygit"
    local lazygit_conf="$lazygit_dir/config.yml"
    mkdir -p "$lazygit_dir"
    if [ ! -f "$lazygit_conf" ]; then
        cat << 'EOF' > "$lazygit_conf"
gui:
  theme:
    activeBorderColor:
      - '#89b4fa'
      - bold
    inactiveBorderColor:
      - '#a6adc8'
    searchingActiveBorderColor:
      - '#f9e2af'
git:
  pagers:
    colorArg: always
    pager: delta --dark --paging=never
EOF
        chown -R "$REAL_USER:" "$lazygit_dir" 2>/dev/null || true
    fi

    echo "✅ Configuración global de Git aplicada con éxito."
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        configure_git
        check_status
        ;;
esac
