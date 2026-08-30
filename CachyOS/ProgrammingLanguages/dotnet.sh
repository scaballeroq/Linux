#!/bin/bash
# ==============================================================================
# dotnet.sh - Instalación de .NET SDK (Última LTS) vía Mise para CachyOS
# Optimizado para KDE Plasma 6 (Wayland) y Zsh / Bash (IDEs y CLI)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🟣 Instalando .NET SDK (Última versión LTS) para CachyOS"
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

# 2. Dependencias nativas del sistema para el runtime de .NET
echo "ℹ️ [1/3] Verificando dependencias nativas del sistema (icu, krb5, openssl, zlib)..."
MISSING_PKGS=$(pacman -T icu krb5 openssl zlib libunwind 2>/dev/null || true)
if [ -n "$MISSING_PKGS" ]; then
    echo "  ⬇️ Instalando librerías requeridas: $MISSING_PKGS..."
    $SUDO pacman -S --needed --noconfirm $MISSING_PKGS
else
    echo "  ✅ Dependencias nativas ya instaladas."
fi

# 3. Instalar la última versión LTS de .NET SDK con Mise
echo "ℹ️ [2/3] Descargando e instalando .NET SDK (LTS) vía Mise..."
run_as_user mise use --global dotnet@lts
run_as_user mise reshim 2>/dev/null || true

# 4. Integración con KDE Plasma 6 y Shells (environment.d, bash, zsh)
echo "ℹ️ [3/3] Configurando variables de entorno e integración de IDEs..."
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"

cat << 'EOF' | run_as_user tee "$ENV_DIR/10-dotnet.conf" > /dev/null
# Integración de .NET SDK para KDE Plasma 6, JetBrains Rider, VS Code y Antigravity
DOTNET_ROOT=${HOME}/.local/share/mise/installs/dotnet/lts
DOTNET_CLI_TELEMETRY_OPTOUT=1
DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
EOF

# Integración modular en Shells
BASHRC_D="$USER_HOME/.bashrc.d"
ZSHRC_D="$USER_HOME/.zshrc.d"
run_as_user mkdir -p "$BASHRC_D" "$ZSHRC_D"

cat << 'EOF' | run_as_user tee "$BASHRC_D/dotnet.sh" > /dev/null
# .NET Environment Variables
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
EOF

cat << 'EOF' | run_as_user tee "$ZSHRC_D/dotnet.zsh" > /dev/null
# .NET Environment Variables
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
EOF

# Autocompletado de .NET CLI
COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"
ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
ZFUNC_DIR="$USER_HOME/.zfunc"
run_as_user mkdir -p "$COMPLETIONS_DIR" "$ZSH_COMPLETIONS_DIR" "$ZFUNC_DIR"

if command -v mise &>/dev/null; then
    run_as_user mise exec dotnet@lts -- dotnet complete --position 1 --script bash > "$COMPLETIONS_DIR/dotnet" 2>/dev/null || true
    run_as_user mise exec dotnet@lts -- dotnet complete --position 1 --script zsh > "$ZSH_COMPLETIONS_DIR/_dotnet" 2>/dev/null || true
    run_as_user mise exec dotnet@lts -- dotnet complete --position 1 --script zsh > "$ZFUNC_DIR/_dotnet" 2>/dev/null || true
fi

# Obtener versiones instaladas
DOTNET_VER=$(run_as_user mise exec dotnet@lts -- dotnet --version 2>/dev/null || echo "LTS instalado")

echo "================================================================="
echo "✅ .NET SDK LTS configurado con éxito para CachyOS y KDE Plasma 6:"
echo "  • .NET SDK:    $DOTNET_VER (LTS)"
echo "  • IDEs/KDE:    ~/.config/environment.d/10-dotnet.conf (Rider, VS Code)"
echo "  • Telemetría:  Desactivada (DOTNET_CLI_TELEMETRY_OPTOUT=1)"
echo "  • Shells:      Bash & Zsh (~/.local/share/mise/shims)"
echo "================================================================="
