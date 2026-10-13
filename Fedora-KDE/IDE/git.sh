#!/bin/bash
# ==============================================================================
# git.sh - Instalación, Optimización y Configuración de Git, Delta, Lazygit y gh
# Fedora 44 (KDE Plasma 6 + Wayland / Kitty Terminal)
# ==============================================================================
# Características:
# - Despliegue idempotente: comprueba paquetes primero (rpm -q / command -v) y
#   evita invocar 'sudo' o DNF5 si Git, Git-Delta, Lazygit y GitHub CLI ya están instalados.
# - Configuración global recomendada: rebase por defecto, autoSetupRemote, zdiff3.
# - Integración de Git-Delta con visualización 'side-by-side' y resaltado de sintaxis.
# - Integración de Lazygit con delta pager y tema adaptado a KDE Breeze Dark.
# - Configuración de GitHub CLI (gh) con editor predeterminado y diagnóstico de auth.
# - Comandos CLI: --status / -s, --help / -h.
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

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🐙 Gestor y Optimizador de Git, Delta, Lazygit y GitHub CLI - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica e instala paquetes faltantes vía DNF5, aplica configuración global
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

    echo "• Git Engine:         $([ "$git_ver" != "No instalado" ] && echo "✅ $git_ver" || echo "❌ $git_ver")"
    echo "• Identidad Git:      $user_name <$user_email>"
    echo "• Rama por defecto:   $default_branch"
    echo "• Editor Git:         $core_editor"
    echo "• Pager / Diff:       $core_pager $([ "$core_pager" = "delta" ] && echo "✅ (Git-Delta activo)")"
    echo "• Git-Delta:          $([ "$delta_ver" != "No instalado" ] && echo "✅ $delta_ver" || echo "❌ $delta_ver")"
    echo "• Lazygit TUI:        $([ "$lazygit_ver" != "No instalado" ] && echo "✅ $lazygit_ver" || echo "❌ $lazygit_ver")"
    echo "• Config Lazygit:     $(if [ -f "$USER_HOME/.config/lazygit/config.yml" ]; then echo "✅ Integrado con Delta"; else echo "ℹ️ No configurado"; fi)"
    echo "• GitHub CLI (gh):    $([ "$gh_ver" != "No instalado" ] && echo "✅ $gh_ver" || echo "❌ $gh_ver")"
    echo "• Estado Auth GitHub: $gh_auth"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. CONTROL DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
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
echo "🐙 Configurando entorno de Git, Delta, Lazygit y GitHub CLI (Fedora 44)"
echo "================================================================="

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN DE PAQUETES (IDEMPOTENTE Y SIN SUDO INNECESARIO)
# ------------------------------------------------------------------------------
echo "ℹ️ [1/4] Verificando paquetes de Git en el sistema..."
MISSING_PKGS=()

if ! rpm -q git &>/dev/null && ! command -v git &>/dev/null; then MISSING_PKGS+=("git"); fi
if ! rpm -q git-delta &>/dev/null && ! command -v delta &>/dev/null; then MISSING_PKGS+=("git-delta"); fi
if ! rpm -q gh &>/dev/null && ! command -v gh &>/dev/null; then MISSING_PKGS+=("gh"); fi
if ! rpm -q lazygit &>/dev/null && ! command -v lazygit &>/dev/null; then MISSING_PKGS+=("lazygit"); fi

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "  📦 Paquetes faltantes detectados: (${MISSING_PKGS[*]}). Instalando..."
    if ! command -v sudo &>/dev/null && [ "$EUID" -ne 0 ]; then
        echo "❌ Error: Se requieren permisos administrativos (sudo) para instalar: ${MISSING_PKGS[*]}"
        exit 1
    fi

    DNF_PKGS=()
    NEED_LAZYGIT=false
    for pkg in "${MISSING_PKGS[@]}"; do
        if [ "$pkg" = "lazygit" ]; then
            NEED_LAZYGIT=true
        else
            DNF_PKGS+=("$pkg")
        fi
    done

    if [ ${#DNF_PKGS[@]} -gt 0 ]; then
        if ! $SUDO dnf5 install -y "${DNF_PKGS[@]}"; then
            echo "  ⚠️ Falló instalación grupal con DNF5, intentando paquete a paquete..."
            for pkg in "${DNF_PKGS[@]}"; do
                $SUDO dnf5 install -y "$pkg" || echo "  ⚠️ No se pudo instalar $pkg vía DNF5"
            done
        else
            echo "  ✅ Paquetes (${DNF_PKGS[*]}) instalados vía DNF5."
        fi
    fi

    if [ "$NEED_LAZYGIT" = true ]; then
        if ! $SUDO dnf5 install -y lazygit 2>/dev/null; then
            if $SUDO dnf5 copr enable -y dejan/lazygit 2>/dev/null && $SUDO dnf5 install -y lazygit 2>/dev/null; then
                echo "  ✅ Lazygit instalado vía DNF5 Copr."
            else
                echo "  ℹ️ Lazygit no disponible en repositorios oficiales/copr; aplicando fallback oficial..."
            fi
        else
            echo "  ✅ Lazygit instalado vía DNF5."
        fi
    fi
else
    echo "  ✅ Paquetes de Git (git, git-delta, gh, lazygit) ya satisfechos en el sistema."
fi

# Lazygit fallback: binario oficial de GitHub si no se pudo instalar por DNF5/COPR
if ! command -v lazygit &>/dev/null; then
    echo "  ⬇️ Instalando Lazygit desde binario oficial de GitHub (fallback)..."
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) LAZYGIT_ARCH="x86_64" ;;
        aarch64) LAZYGIT_ARCH="arm64" ;;
        *) echo "❌ Arquitectura no soportada para Lazygit: $ARCH"; exit 1 ;;
    esac
    LAZYGIT_TAG=$(basename "$(curl -fsSLI -o /dev/null -w "%{url_effective}" https://github.com/jesseduffield/lazygit/releases/latest 2>/dev/null)" || true)
    LAZYGIT_VERSION="${LAZYGIT_TAG#v}"
    if [ -n "$LAZYGIT_VERSION" ] && [ "$LAZYGIT_VERSION" != "latest" ]; then
        run_as_user mkdir -p "$USER_HOME/.local/bin"
        local_tar="/tmp/lazygit.tar.gz"
        if curl -fsSLo "$local_tar" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"; then
            tar xf "$local_tar" -C "/tmp" lazygit
            run_as_user install "/tmp/lazygit" "$USER_HOME/.local/bin/lazygit"
            rm -f "/tmp/lazygit" "$local_tar"
            echo "  ✅ Lazygit instalado en $USER_HOME/.local/bin/lazygit"
        else
            echo "  ❌ Error al descargar el binario de Lazygit desde GitHub."
        fi
    else
        echo "  ❌ No se pudo determinar la última versión de Lazygit en GitHub."
    fi
fi

# ------------------------------------------------------------------------------
# 5. CONFIGURACIÓN GLOBAL DE GIT Y DELTA
# ------------------------------------------------------------------------------
echo "ℹ️ [2/4] Aplicando configuración global y mejores prácticas modernas de Git..."

CURRENT_NAME=$(run_as_user git config --global user.name 2>/dev/null || true)
CURRENT_EMAIL=$(run_as_user git config --global user.email 2>/dev/null || true)

GIT_USER_NAME="${CURRENT_NAME:-${GIT_USER_NAME:-Tu Nombre}}"
GIT_USER_EMAIL="${CURRENT_EMAIL:-${GIT_USER_EMAIL:-tu_email@ejemplo.com}}"

run_as_user git config --global user.name "$GIT_USER_NAME"
run_as_user git config --global user.email "$GIT_USER_EMAIL"

# Flujo de trabajo y ramas
run_as_user git config --global init.defaultBranch main
run_as_user git config --global pull.rebase true
run_as_user git config --global rebase.autoStash true
run_as_user git config --global push.autoSetupRemote true
run_as_user git config --global fetch.prune true

# Detección inteligente del editor preferido en Fedora KDE
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

# Configuración de Git-Delta (resaltado de sintaxis y diffs limpios)
if command -v delta &>/dev/null; then
    run_as_user git config --global core.pager "delta"
    run_as_user git config --global interactive.diffFilter "delta --color-only"
    run_as_user git config --global delta.navigate true
    run_as_user git config --global delta.light false
    run_as_user git config --global delta.side-by-side true
    run_as_user git config --global delta.line-numbers true
    run_as_user git config --global delta.hyperlinks true
fi

# ------------------------------------------------------------------------------
# 6. CONFIGURACIÓN DE LAZYGIT (INTEGRACIÓN CON DELTA Y TEMA KDE BREEZE DARK)
# ------------------------------------------------------------------------------
echo "ℹ️ [3/4] Configurando Lazygit con soporte para Git-Delta y tema KDE..."
LAZYGIT_CONFIG_DIR="$USER_HOME/.config/lazygit"
run_as_user mkdir -p "$LAZYGIT_CONFIG_DIR"

if [ ! -f "$LAZYGIT_CONFIG_DIR/config.yml" ]; then
    cat << 'EOF' | run_as_user tee "$LAZYGIT_CONFIG_DIR/config.yml" > /dev/null
# Lazygit Configuration - Fedora 44 (KDE Plasma 6)
gui:
  theme:
    activeBorderColor:
      - '#3daee9'
      - bold
    inactiveBorderColor:
      - '#4d4d4d'
    selectedLineBgColor:
      - '#232629'
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
EOF
    echo "  ✅ Archivo de configuración de Lazygit creado (~/.config/lazygit/config.yml)."
else
    echo "  ℹ️ Configuración existente de Lazygit conservada."
fi

# ------------------------------------------------------------------------------
# 7. CONFIGURACIÓN DE GITHUB CLI (gh)
# ------------------------------------------------------------------------------
echo "ℹ️ [4/4] Configurando GitHub CLI (gh)..."
if command -v gh &>/dev/null; then
    run_as_user gh config set editor "$DEFAULT_EDITOR" 2>/dev/null || true
    echo "  ✅ Editor predeterminado de GitHub CLI configurado a '$DEFAULT_EDITOR'."
fi

# ------------------------------------------------------------------------------
# 8. RESUMEN FINAL
# ------------------------------------------------------------------------------
echo ""
show_status
echo "================================================================="
echo "✅ Entorno Git optimizado con éxito para Fedora 44 (KDE Plasma 6)."
echo "💡 Tip: Lanza 'lazygit' en cualquier repositorio para una TUI interactiva."
echo "================================================================="
