#!/usr/bin/env bash
# ==============================================================================
# dotnet.sh - Instalación de .NET SDK (Última LTS) vía Mise para Fedora 44
# Optimizado para KDE Plasma 6 y Bash / Zsh (IDEs y CLI)
# ==============================================================================

set -euo pipefail

# Colores ANSI para terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

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

export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_NOLOGO=1

# Exportar PATH para este proceso
export PATH="$USER_HOME/.dotnet/tools:$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/bin:$PATH"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" \
            DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 DOTNET_NOLOGO=1 \
            PATH="$USER_HOME/.dotnet/tools:$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 DOTNET_NOLOGO=1 \
        PATH="$USER_HOME/.dotnet/tools:$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    fi
}

check_pkg() {
    rpm -q "$1" &>/dev/null
}

show_help() {
    cat <<EOF
🟣 Gestor e Instalador de .NET SDK (LTS) - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala librerías nativas CoreCLR, .NET SDK LTS vía Mise,
                      desactiva telemetría y configura variables de sesión KDE.
  --status, -s        Muestra el diagnóstico de .NET SDK, runtimes y herramientas globales.
  --update, -u        Actualiza .NET SDK a la versión LTS más reciente.
  --list, -l          Lista las versiones de SDK instaladas y disponibles en remoto.
  --help, -h          Muestra este mensaje de ayuda.

Características configuradas:
  • Versión LTS Oficial: Instala y fija 'dotnet@lts' vía Mise de Microsoft.
  • Privacidad:          DOTNET_CLI_TELEMETRY_OPTOUT=1 para agilizar la compilación.
  • Integración KDE/IDE: Variables en ~/.config/environment.d/10-dotnet.conf para Rider y VS Code.
  • Tools:               ~/.dotnet/tools disponible en PATH en todas las sesiones.
EOF
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 ESTADO DE .NET SDK - FEDORA 44 (KDE PLASMA 6)${NC}"
    echo -e "${CYAN}=================================================================${NC}"
    if command -v dotnet &>/dev/null || run_as_user mise which dotnet &>/dev/null; then
        local sdk_ver
        sdk_ver=$(run_as_user dotnet --version 2>/dev/null || echo "Instalado")
        echo -e "• ${BOLD}.NET SDK:${NC}            ${GREEN}✅ v$sdk_ver${NC}"
        echo -e "• ${BOLD}Ruta dotnet:${NC}         $(run_as_user which dotnet 2>/dev/null || echo 'vía mise shims')"
        echo -e "• ${BOLD}Telemetría:${NC}          Desactivada (TELEMETRY_OPTOUT=1)"
        echo -e "• ${BOLD}Herramientas tools:${NC}  $USER_HOME/.dotnet/tools"
        echo -e "• ${BOLD}Entorno KDE Plasma:${NC}  $([ -f "$USER_HOME/.config/environment.d/10-dotnet.conf" ] && echo -e "${GREEN}✅ Configurado${NC}" || echo -e "${YELLOW}ℹ️ Pendiente${NC}")"
        echo ""
        echo "📦 Runtimes instalados:"
        run_as_user dotnet --list-runtimes 2>/dev/null | sed 's/^/  • /' || echo "  (Ninguno detectado)"
        echo ""
        echo "📦 SDKs instalados:"
        run_as_user dotnet --list-sdks 2>/dev/null | sed 's/^/  • /' || echo "  (Ninguno detectado)"
    else
        echo -e "• ${BOLD}.NET SDK:${NC}            ${RED}❌ No instalado en el sistema${NC}"
    fi
    echo -e "${CYAN}=================================================================${NC}"
}

list_versions() {
    ensure_mise
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}📋 VERSIONES DE .NET SDK EN MISE${NC}"
    echo -e "${CYAN}=================================================================${NC}"
    run_as_user mise ls dotnet 2>/dev/null || echo "Ninguna versión instalada."
    echo ""
    echo "📋 Versiones LTS disponibles en remoto:"
    run_as_user mise ls-remote dotnet 2>/dev/null | grep -E '^8\.' | tail -n 8 || true
    echo -e "${CYAN}=================================================================${NC}"
}

ensure_mise() {
    if ! command -v mise &> /dev/null && [ ! -x "$USER_HOME/.local/bin/mise" ]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -f "$script_dir/../mise.sh" ]; then
            echo -e "${BLUE}ℹ️ Mise no encontrado. Ejecutando $script_dir/../mise.sh...${NC}"
            bash "$script_dir/../mise.sh"
        else
            echo -e "${RED}❌ Error: 'mise' no está instalado. Ejecuta ./mise.sh primero.${NC}"
            exit 1
        fi
    fi
}

install_dependencies() {
    echo -e "${BLUE}ℹ️ [1/4] Verificando dependencias de sistema para CoreCLR en Fedora...${NC}"
    local missing=()
    for pkg in libicu openssl-devel krb5-devel curl; do
        if ! check_pkg "$pkg"; then missing+=("$pkg"); fi
    done
    if ! check_pkg zlib-devel && ! check_pkg zlib-ng-compat-devel; then
        missing+=("zlib-devel")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${BLUE}  📦 Instalando librerías (${missing[*]}) vía DNF5...${NC}"
        if ! command -v sudo &>/dev/null && [ "$EUID" -ne 0 ]; then
            echo -e "${RED}❌ Error: Se requieren privilegios de sudo para instalar dependencias.${NC}"
            exit 1
        fi
        $SUDO dnf5 install -y "${missing[@]}"
        echo -e "${GREEN}  ✅ Dependencias de sistema instaladas.${NC}"
    else
        echo -e "${GREEN}  ✅ Dependencias nativas de CoreCLR ya satisfechas.${NC}"
    fi
}

install_dotnet() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🟣 INSTALANDO .NET SDK (LTS) - FEDORA 44 (KDE PLASMA 6)${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    ensure_mise
    install_dependencies

    # 1. Instalar la última versión LTS de .NET SDK con Mise
    echo -e "${BLUE}ℹ️ [2/4] Descargando e instalando .NET SDK (LTS) vía Mise...${NC}"
    run_as_user mise use --global dotnet@lts
    run_as_user mise reshim 2>/dev/null || true

    # 2. Configurar variables de entorno y sesión KDE Plasma 6
    echo -e "${BLUE}ℹ️ [3/4] Configurando variables de entorno e integración de IDEs...${NC}"
    local env_dir="$USER_HOME/.config/environment.d"
    local tools_dir="$USER_HOME/.dotnet/tools"
    run_as_user mkdir -p "$env_dir" "$tools_dir"

    local dotnet_dir
    dotnet_dir="$(run_as_user mise where dotnet 2>/dev/null || echo "$USER_HOME/.local/share/mise/installs/dotnet/lts")"

    cat << EOF | run_as_user tee "$env_dir/10-dotnet.conf" > /dev/null
# Integración de .NET SDK para sesión gráfica (KDE Plasma 6 + Wayland)
DOTNET_ROOT=$dotnet_dir
DOTNET_CLI_TELEMETRY_OPTOUT=1
DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
DOTNET_NOLOGO=1
PATH=\${HOME}/.dotnet/tools:\${PATH}
EOF

    # Shell Bash
    local bashrc_d="$USER_HOME/.bashrc.d"
    run_as_user mkdir -p "$bashrc_d"
    cat << 'EOF' | run_as_user tee "$bashrc_d/dotnet.sh" > /dev/null
# .NET SDK Environment Settings
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_NOLOGO=1
if [ -d "$HOME/.dotnet/tools" ] && [[ ":$PATH:" != *":$HOME/.dotnet/tools:"* ]]; then
    export PATH="$HOME/.dotnet/tools:$PATH"
fi
EOF

    # Shell Zsh (si existe ~/.zshrc)
    if [ -f "$USER_HOME/.zshrc" ]; then
        local zshrc_d="$USER_HOME/.zshrc.d"
        run_as_user mkdir -p "$zshrc_d"
        cat << 'EOF' | run_as_user tee "$zshrc_d/dotnet.zsh" > /dev/null
# .NET SDK Environment Settings
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_NOLOGO=1
if [ -d "$HOME/.dotnet/tools" ] && [[ ":$PATH:" != *":$HOME/.dotnet/tools:"* ]]; then
    export PATH="$HOME/.dotnet/tools:$PATH"
fi
EOF
    fi

    # 3. Autocompletado nativo para dotnet CLI
    echo -e "${BLUE}ℹ️ [4/4] Configurando autocompletado para dotnet CLI...${NC}"
    local comp_dir="$USER_HOME/.local/share/bash-completion/completions"
    run_as_user mkdir -p "$comp_dir"
    cat << 'EOF' | run_as_user tee "$comp_dir/dotnet" > /dev/null
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

    local dotnet_ver
    dotnet_ver=$(run_as_user mise exec dotnet@lts -- dotnet --version 2>/dev/null || echo "instalado")

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${GREEN}✅ .NET SDK LTS configurado con éxito para Fedora 44 y KDE Plasma 6:${NC}"
    echo -e "  • SDK Versión: v$dotnet_ver (LTS)"
    echo -e "  • Telemetría:  Desactivada (TELEMETRY_OPTOUT=1)"
    echo -e "  • Tools:       ~/.dotnet/tools registrado en PATH"
    echo -e "  • Entorno KDE: ~/.config/environment.d/10-dotnet.conf"
    echo -e "${CYAN}=================================================================${NC}"
}

update_dotnet() {
    echo -e "${BLUE}🔄 Actualizando .NET SDK a la última versión LTS...${NC}"
    ensure_mise
    run_as_user mise install dotnet@lts
    run_as_user mise use --global dotnet@lts
    run_as_user mise reshim 2>/dev/null || true
    echo -e "${GREEN}✅ .NET SDK LTS actualizado con éxito.${NC}"
    show_status
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --list|-l|list)
        list_versions
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    --update|-u|update)
        update_dotnet
        exit 0
        ;;
    "")
        install_dotnet
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida:${NC} ${1}"
        show_help
        exit 1
        ;;
esac
