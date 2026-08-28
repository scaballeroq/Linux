#!/bin/bash
# dotnet.sh - Instalación y configuración de .NET SDK (Última versión LTS) vía Mise en Fedora 44 + KDE Plasma
#
# Uso:
#   ./dotnet.sh                      -> Instala dependencias de Fedora, .NET SDK LTS, desactiva telemetría y configura sesión KDE
#   ./dotnet.sh --status             -> Muestra la versión activa del SDK de .NET, runtimes y herramientas globales
#   ./dotnet.sh --update             -> Actualiza .NET SDK a la última versión LTS disponible
#   ./dotnet.sh --list               -> Lista los SDKs y runtimes instalados y disponibles en remoto
#   ./dotnet.sh --help               -> Muestra la ayuda interactiva

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    REAL_USER="$SUDO_USER"
else
    USER_HOME="${HOME}"
    REAL_USER="${USER:-$(id -un)}"
fi

show_help() {
    cat <<EOF
🟣 Gestor e Instalador de .NET SDK (LTS) - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala librerías nativas CoreCLR, .NET SDK LTS vía Mise, configura DOTNET_ROOT y variables de sesión KDE.
  --status, -s           Muestra las versiones del SDK de .NET, runtimes activos y herramientas globales.
  --update, -u           Actualiza .NET SDK a la última versión LTS disponible.
  --list, -l             Lista las versiones de SDK instaladas y disponibles en remoto.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Versión LTS Oficial: Instala dinámicamente 'dotnet@lts' (Long Term Support oficial de Microsoft).
  • Dependencias DNF5:   Instala libicu, openssl-devel, krb5-devel y zlib-devel para ejecución fluida de CoreCLR.
  • Privacidad:          Fija DOTNET_CLI_TELEMETRY_OPTOUT=1 para eliminar recolección de telemetría y mejorar velocidad.
  • Integración KDE/IDE: Variables en ~/.config/environment.d/10-dotnet.conf para Rider, VS Code (C# Dev Kit) y KRunner.
  • Herramientas:        Añade ~/.dotnet/tools al PATH para herramientas globales de dotnet (dotnet-ef, etc.).
EOF
}

# Verificar e instalar Mise si no está presente
ensure_mise() {
    if ! command -v mise &> /dev/null; then
        echo "⚠️ Mise no está instalado. Ejecutando ./mise.sh automáticamente..."
        if [ -f "$SCRIPT_DIR/mise.sh" ]; then
            "$SCRIPT_DIR/mise.sh"
            export PATH="$HOME/.local/share/mise/shims:$PATH"
            eval "$(mise activate bash 2>/dev/null || true)"
        else
            echo "❌ Error: No se encontró $SCRIPT_DIR/mise.sh. Instala Mise primero."
            exit 1
        fi
    fi
}

# 1. Mostrar estado de .NET
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE .NET SDK - FEDORA 44"
    echo "================================================================="
    if command -v dotnet &>/dev/null; then
        echo "• .NET SDK:            $(dotnet --version 2>/dev/null || echo 'No disponible')"
        echo "• Ruta binario dotnet: $(which dotnet 2>/dev/null || echo 'n/a')"
        echo ""
        echo "📦 Runtimes instalados:"
        dotnet --list-runtimes 2>/dev/null || echo "  (Ningún runtime detectado)"
        echo ""
        echo "📦 SDKs instalados:"
        dotnet --list-sdks 2>/dev/null || echo "  (Ningún SDK detectado)"
    else
        echo "• .NET SDK:            No instalado"
    fi
    echo "================================================================="
}

# 2. Listar versiones
list_versions() {
    ensure_mise
    echo "================================================================="
    echo "📋 VERSIONES DE .NET SDK INSTALADAS EN MISE"
    echo "================================================================="
    mise ls dotnet 2>/dev/null || echo "Ninguna versión instalada."
    echo ""
    echo "📋 VERSIONES LTS DISPONIBLES EN REMOTO:"
    mise ls-remote dotnet | grep -E '^8\.' | tail -n 8 || mise ls-remote dotnet | tail -n 10
    echo "================================================================="
}

# 3. Instalar librerías nativas requeridas por CoreCLR en Fedora
install_dependencies() {
    echo "📦 [1/4] Instalando dependencias de sistema para .NET CoreCLR en Fedora..."
    $SUDO dnf5 install -y \
        libicu \
        openssl-devel \
        zlib-devel \
        krb5-devel \
        curl 2>/dev/null || true
    echo "✅ Dependencias CoreCLR listas."
}

# 4. Instalar .NET SDK LTS vía Mise
install_dotnet_lts() {
    ensure_mise
    echo "🚀 [2/4] Instalando .NET SDK LTS vía Mise..."
    mise install dotnet@lts || mise install dotnet@8
    mise use --global dotnet@lts || mise use --global dotnet@8
    echo "✅ .NET SDK LTS fijado como versión global."
}

# 5. Configurar variables de entorno y sesión KDE Plasma
configure_environment() {
    echo "🔗 [3/4] Configurando variables de entorno (DOTNET_ROOT, telemetría) y sesión KDE..."
    
    # 5.1. Variables de sesión KDE Plasma / Wayland (environment.d)
    mkdir -p "$USER_HOME/.config/environment.d" "$USER_HOME/.dotnet/tools"
    cat <<'EOF' > "$USER_HOME/.config/environment.d/10-dotnet.conf"
DOTNET_CLI_TELEMETRY_OPTOUT=1
DOTNET_NOLOGO=1
PATH=$HOME/.dotnet/tools:$PATH
EOF

    # 5.2. Configuración modular en ~/.bashrc.d/dotnet.sh
    mkdir -p "$USER_HOME/.bashrc.d"
    cat <<'EOF' > "$USER_HOME/.bashrc.d/dotnet.sh"
# .NET SDK Environment
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export PATH="$HOME/.dotnet/tools:$PATH"
EOF

    # 5.3. Fallback en ~/.bashrc
    if ! grep -q "DOTNET_CLI_TELEMETRY_OPTOUT" "$USER_HOME/.bashrc" 2>/dev/null; then
        cat <<'EOF' >> "$USER_HOME/.bashrc"

# .NET SDK Environment
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export PATH="$HOME/.dotnet/tools:$PATH"
EOF
    fi

    echo "🔗 [4/4] Regenerando shims de Mise..."
    mise reshim
    chown -R "$REAL_USER:" "$USER_HOME/.config/environment.d" "$USER_HOME/.bashrc.d" "$USER_HOME/.dotnet" 2>/dev/null || true
    echo "✅ Variables de entorno y sesión configuradas."
}

# Procesar argumentos
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --list|-l|list)
        list_versions
        exit 0
        ;;
    --update|-u|update)
        echo "🔄 Actualizando .NET SDK a la última versión LTS..."
        ensure_mise
        mise install dotnet@lts || mise install dotnet@8
        mise use --global dotnet@lts || mise use --global dotnet@8
        configure_environment
        echo ""
        show_status
        ;;
    "")
        echo "================================================================="
        echo "🟣 INSTALADOR DE .NET SDK (LTS) - FEDORA 44 (KDE PLASMA 6)"
        echo "================================================================="
        ensure_mise
        install_dependencies
        install_dotnet_lts
        configure_environment
        echo ""
        show_status
        echo "================================================================="
        echo "✅ .NET SDK LTS configurado correctamente."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
