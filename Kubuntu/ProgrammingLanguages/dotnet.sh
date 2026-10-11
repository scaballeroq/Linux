#!/bin/bash
# =============================================================================
# dotnet.sh - Instalador de .NET SDK vía Mise para Kubuntu
# =============================================================================
# - Instala la última versión recomendada/LTS de .NET SDK (dotnet@latest)
# - Desactiva telemetría pesada de Microsoft (DOTNET_CLI_TELEMETRY_OPTOUT=1)
# - Añade el directorio de herramientas globales (~/.dotnet/tools) al PATH
# - Integra con KDE Plasma y Bash modular (~/.bashrc.d)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

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
Instalador de .NET SDK (Mise) - Kubuntu

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala .NET SDK estable/LTS, herramientas globales y variables de entorno.
  --status, -s           Muestra la versión de .NET SDK instalada y estado en Mise.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE .NET SDK - KUBUNTU"
    echo "================================================================="
    echo "dotnet (Mise):                 $(run_as_user mise which dotnet 2>/dev/null || echo 'No instalado')"
    echo "Versión de .NET SDK:           $(run_as_user dotnet --version 2>/dev/null || echo 'n/a')"
    echo "Ruta de herramientas (.NET):   $USER_HOME/.dotnet/tools"
    echo "================================================================="
    if command -v mise &>/dev/null; then
        echo ""
        echo "Versiones de dotnet en Mise:"
        run_as_user mise ls dotnet 2>/dev/null || true
    fi
}

install_dotnet() {
    echo "================================================================="
    echo "INSTALANDO .NET SDK VÍA MISE - KUBUNTU"
    echo "================================================================="

    # 1. Asegurar que Mise está instalado
    if ! command -v mise &> /dev/null && [ ! -x "$USER_HOME/.local/bin/mise" ]; then
        echo "ℹ️ Mise no detectado. Instalando Mise primero..."
        if [ -f "$SCRIPT_DIR/mise.sh" ]; then
            bash "$SCRIPT_DIR/mise.sh"
        else
            echo "❌ Error: No se encontró mise.sh en $SCRIPT_DIR"
            exit 1
        fi
    fi

    # 2. Dependencias del sistema (ICU, libssl, zlib)
    echo "ℹ️ [1/3] Instalando dependencias base del sistema..."
    $SUDO apt update
    $SUDO apt install -y libicu-dev libssl-dev zlib1g curl 2>/dev/null || true

    # 3. Instalar .NET SDK vía Mise
    echo "ℹ️ [2/3] Instalando .NET SDK vía Mise (dotnet@latest)..."
    run_as_user mise use --global dotnet@latest

    # 4. Configurar variables de entorno y optimizaciones
    echo "ℹ️ [3/3] Configurando variables de entorno (.bashrc.d y environment.d)..."
    run_as_user mkdir -p "$USER_HOME/.bashrc.d" "$USER_HOME/.config/environment.d" "$USER_HOME/.dotnet/tools"

    cat <<'EOF' > "$USER_HOME/.bashrc.d/dotnet.sh"
# .NET Core / .NET SDK Environment
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
if [ -d "$HOME/.dotnet/tools" ] && [[ ":$PATH:" != *":$HOME/.dotnet/tools:"* ]]; then
    export PATH="$HOME/.dotnet/tools:$PATH"
fi
EOF
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.bashrc.d/dotnet.sh" 2>/dev/null || true

    cat <<'EOF' > "$USER_HOME/.config/environment.d/50-dotnet.conf"
DOTNET_CLI_TELEMETRY_OPTOUT=1
DOTNET_NOLOGO=1
PATH=$HOME/.dotnet/tools:$PATH
EOF
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/environment.d/50-dotnet.conf" 2>/dev/null || true

    echo ""
    echo "================================================================="
    echo "✅ .NET SDK instalado y configurado correctamente para '$REAL_USER'."
    echo "   - Versión SDK: $(run_as_user dotnet --version 2>/dev/null || echo 'Instalado')"
    echo "================================================================="
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    "")
        install_dotnet
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
