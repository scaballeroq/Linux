#!/bin/bash
# ==============================================================================
# dotnet.sh - Instalación de .NET SDK (Última LTS) vía Mise para Fedora Workstation
# Optimizado para GNOME (Wayland) y Zsh / Bash (IDEs y CLI)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🟣 Instalando .NET SDK (Última versión LTS) para Fedora Workstation"
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

export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
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

# 2. Dependencias nativas del sistema para el runtime de .NET en Fedora
echo "ℹ️ [1/3] Verificando dependencias nativas del sistema (libicu, krb5-devel, openssl-devel, zlib-devel, libunwind)..."
$SUDO dnf5 install -y libicu openssl-devel krb5-devel zlib-devel libunwind curl 2>/dev/null || true
echo "  ✅ Dependencias nativas CoreCLR preparadas."

# 3. Instalar la última versión LTS de .NET SDK con Mise
echo "ℹ️ [2/3] Descargando e instalando .NET SDK (LTS) vía Mise..."
run_as_user mise use --global dotnet@lts
run_as_user mise reshim 2>/dev/null || true

# 4. Integración con GNOME y Shells (environment.d, bash, zsh)
echo "ℹ️ [3/3] Configurando variables de entorno e integración de IDEs..."
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"

DOTNET_DIR="$(run_as_user mise where dotnet 2>/dev/null || echo "$USER_HOME/.local/share/mise/installs/dotnet/lts")"

cat << EOF | run_as_user tee "$ENV_DIR/10-dotnet.conf" > /dev/null
# Integración de .NET SDK para GNOME, JetBrains Rider, VS Code y Antigravity
DOTNET_ROOT=$DOTNET_DIR
DOTNET_CLI_TELEMETRY_OPTOUT=1
DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
EOF

# Integración modular en Shells (Bash predeterminado; Zsh si existe ~/.zshrc)
BASHRC_D="$USER_HOME/.bashrc.d"
run_as_user mkdir -p "$BASHRC_D"

cat << EOF | run_as_user tee "$BASHRC_D/dotnet.sh" > /dev/null
# .NET Environment Variables
if [ -d "$DOTNET_DIR" ]; then
    export DOTNET_ROOT="$DOTNET_DIR"
fi
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
EOF

# Autocompletado de .NET CLI para Bash
COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"
run_as_user mkdir -p "$COMPLETIONS_DIR"

if command -v mise &>/dev/null; then
    run_as_user mise exec dotnet@lts -- dotnet complete --position 1 --script bash > "$COMPLETIONS_DIR/dotnet" 2>/dev/null || true
fi

# Integración Zsh condicional
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"

    cat << 'EOF' | run_as_user tee "$ZSHRC_D/dotnet.zsh" > /dev/null
# .NET Environment Variables
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
EOF

    ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
    ZFUNC_DIR="$USER_HOME/.zfunc"
    run_as_user mkdir -p "$ZSH_COMPLETIONS_DIR" "$ZFUNC_DIR"

    if command -v mise &>/dev/null; then
        run_as_user mise exec dotnet@lts -- dotnet complete --position 1 --script zsh > "$ZSH_COMPLETIONS_DIR/_dotnet" 2>/dev/null || true
        run_as_user mise exec dotnet@lts -- dotnet complete --position 1 --script zsh > "$ZFUNC_DIR/_dotnet" 2>/dev/null || true
    fi
fi

# Obtener versiones instaladas
DOTNET_VER=$(run_as_user mise exec dotnet@lts -- dotnet --version 2>/dev/null || echo "LTS instalado")

echo "================================================================="
echo "✅ .NET SDK LTS configurado con éxito para Fedora Workstation y GNOME:"
echo "  • .NET SDK:    $DOTNET_VER (LTS)"
echo "  • IDEs/GNOME:  ~/.config/environment.d/10-dotnet.conf (Rider, VS Code)"
echo "  • Telemetría:  Desactivada (DOTNET_CLI_TELEMETRY_OPTOUT=1)"
echo "  • Shells:      Bash (predeterminada)$([ -f "$USER_HOME/.zshrc" ] && echo " & Zsh (compatible)") (~/.local/share/mise/shims)"
echo "================================================================="
