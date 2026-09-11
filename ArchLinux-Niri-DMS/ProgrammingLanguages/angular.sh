#!/bin/bash
# ==============================================================================
# angular.sh - Instalación de Angular CLI vía Mise para Arch Linux
# Optimizado para Niri / Wayland y Zsh (Node.js LTS)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🅰️  Instalando Angular CLI para Arch Linux"
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

export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export NG_CLI_ANALYTICS=false

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" COREPACK_ENABLE_DOWNLOAD_PROMPT=0 NG_CLI_ANALYTICS=false PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        COREPACK_ENABLE_DOWNLOAD_PROMPT=0 NG_CLI_ANALYTICS=false PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    fi
}

# Exportar PATH para este proceso
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/bin:$PATH"

# 1. Asegurar que Mise está presente
if ! command -v mise &> /dev/null && [ ! -x "$USER_HOME/.local/bin/mise" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/mise.sh" ]; then
        echo "ℹ️ Mise no encontrado. Ejecutando instalador $SCRIPT_DIR/mise.sh..."
        bash "$SCRIPT_DIR/mise.sh"
    else
        echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
        exit 1
    fi
fi

# 2. Asegurar que Node.js LTS está instalado en Mise
if ! run_as_user mise list node 2>/dev/null | grep -q "node" && ! command -v node &> /dev/null; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/nodejs.sh" ]; then
        echo "ℹ️ Node.js LTS no encontrado. Ejecutando instalador $SCRIPT_DIR/nodejs.sh..."
        bash "$SCRIPT_DIR/nodejs.sh"
    else
        echo "ℹ️ Instalando Node.js LTS vía Mise..."
        run_as_user mise use --global node@lts
    fi
fi

# 3. Instalación de Angular CLI global (Última versión estable)
echo "ℹ️ [1/3] Instalando última versión estable de Angular CLI vía Mise..."
run_as_user mise use --global npm:@angular/cli@latest
run_as_user mise reshim 2>/dev/null || true

# 4. Desactivar telemetría interactiva de Angular CLI para evitar bloqueos
echo "ℹ️ [2/3] Configurando entorno y desactivando analíticas interactivas..."
run_as_user mise exec -- ng config -g cli.analytics false 2>/dev/null || run_as_user ng config -g cli.analytics false 2>/dev/null || true

ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"
cat << 'EOF' | run_as_user tee "$ENV_DIR/10-angular.conf" > /dev/null
# Desactivar telemetría interactiva de Angular CLI para Niri / Wayland e IDEs
NG_CLI_ANALYTICS=false
EOF

# 5. Autocompletado de Angular CLI (Zsh y Bash) y regeneración de shims
echo "ℹ️ [3/3] Generando autocompletados (Bash y Zsh) y shims..."
COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"
ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
ZFUNC_DIR="$USER_HOME/.zfunc"
run_as_user mkdir -p "$COMPLETIONS_DIR" "$ZSH_COMPLETIONS_DIR" "$ZFUNC_DIR"

if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
    run_as_user mise exec -- ng completion script bash > "$COMPLETIONS_DIR/ng" 2>/dev/null || true
    run_as_user mise exec -- ng completion script zsh > "$ZSH_COMPLETIONS_DIR/_ng" 2>/dev/null || true
    run_as_user mise exec -- ng completion script zsh > "$ZFUNC_DIR/_ng" 2>/dev/null || true
    run_as_user mise reshim 2>/dev/null || true
fi

# Obtener versión instalada
NG_VER=$(run_as_user mise exec -- ng version 2>/dev/null | grep -E "Angular CLI:" | awk '{print $3}' || run_as_user ng version 2>/dev/null | grep -E "Angular CLI:" | awk '{print $3}' || echo "instalado")

echo "================================================================="
echo "✅ Angular CLI configurado con éxito para Arch Linux y Niri / Wayland:"
echo "  • Angular CLI:  v$NG_VER (Última versión estable)"
echo "  • Node Runtime: Node.js LTS (~/.local/share/mise/shims)"
echo "  • Telemetría:   Desactivada (~/.config/environment.d/10-angular.conf)"
echo "  • Shells:       Autocompletado habilitado para Bash y Zsh (_ng)"
echo "================================================================="
