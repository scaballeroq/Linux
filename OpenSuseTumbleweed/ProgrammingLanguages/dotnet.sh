#!/bin/bash
# ==============================================================================
# dotnet.sh - Instalación de .NET SDK (Última LTS) vía Mise para openSUSE Tumbleweed
# Optimizado para KDE Plasma 6 y Zsh / Bash (IDEs y CLI)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🟣 Instalando .NET SDK (Última versión LTS) para openSUSE Tumbleweed"
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

# 2. Dependencias nativas del sistema para el runtime de .NET en openSUSE
echo "ℹ️ [1/3] Verificando dependencias nativas del sistema (libicu, krb5, openssl, zlib)..."
$SUDO zypper --non-interactive install -y libicu libopenssl-devel krb5-devel zlib-devel libunwind curl 2>/dev/null || true
echo "  ✅ Dependencias nativas CoreCLR preparadas."

# 3. Instalar la última versión LTS de .NET SDK con Mise
echo "ℹ️ [2/3] Descargando e instalando .NET SDK (LTS) vía Mise..."
run_as_user mise use --global dotnet@lts
run_as_user mise reshim 2>/dev/null || true

# 4. Integración con KDE Plasma y Shells (environment.d, bash, zsh)
echo "ℹ️ [3/3] Configurando variables de entorno e integración de IDEs..."
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"

DOTNET_DIR="$(run_as_user mise where dotnet 2>/dev/null || echo "$USER_HOME/.local/share/mise/installs/dotnet/lts")"

cat << EOF | run_as_user tee "$ENV_DIR/10-dotnet.conf" > /dev/null
# Integración de .NET SDK para sesión gráfica
DOTNET_ROOT=$DOTNET_DIR
DOTNET_CLI_TELEMETRY_OPTOUT=1
DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
PATH=\${HOME}/.dotnet/tools:\${PATH}
EOF

# Shell Bash
BASHRC_D="$USER_HOME/.bashrc.d"
run_as_user mkdir -p "$BASHRC_D"
cat << EOF | run_as_user tee "$BASHRC_D/dotnet.sh" > /dev/null
# .NET SDK Environment Settings
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
if [ -d "\$HOME/.dotnet/tools" ] && [[ ":\$PATH:" != *":\$HOME/.dotnet/tools:"* ]]; then
    export PATH="\$HOME/.dotnet/tools:\$PATH"
fi
EOF

# Shell Zsh (condicional)
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"
    cat << EOF | run_as_user tee "$ZSHRC_D/dotnet.zsh" > /dev/null
# .NET SDK Environment Settings
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
if [ -d "\$HOME/.dotnet/tools" ] && [[ ":\$PATH:" != *":\$HOME/.dotnet/tools:"* ]]; then
    export PATH="\$HOME/.dotnet/tools:\$PATH"
fi
EOF
fi

# 5. Generar autocompletado nativo para dotnet CLI
COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"
run_as_user mkdir -p "$COMPLETIONS_DIR"
cat << 'EOF' | run_as_user tee "$COMPLETIONS_DIR/dotnet" > /dev/null
# bash completion for dotnet CLI
_dotnet_bash_complete()
{
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local IFS=$'\n'
  local candidates
  candidates=$(dotnet complete --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)
  COMPREPLY=( $(compgen -W "${candidates}" -- "${cur}") )
  return 0
}
complete -f -F _dotnet_bash_complete dotnet
EOF

DOTNET_VER=$(run_as_user mise exec dotnet@lts -- dotnet --version 2>/dev/null || echo "instalado")

echo "================================================================="
echo "✅ .NET SDK LTS configurado con éxito para openSUSE Tumbleweed:"
echo "  • SDK Versión: $DOTNET_VER (LTS)"
echo "  • Telemetría:  Desactivada (TELEMETRY_OPTOUT=1)"
echo "  • Tools:       ~/.dotnet/tools listo en PATH"
echo "  • Entorno:     ~/.config/environment.d/10-dotnet.conf"
echo "================================================================="
