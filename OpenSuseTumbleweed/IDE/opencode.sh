#!/bin/bash
# ==============================================================================
# opencode.sh - Gestor e Instalador de OpenCode AI CLI
# Optimizado para openSUSE Tumbleweed (KDE Plasma 6 Wayland)
# ==============================================================================
# Características:
#  - Detección dinámica y sin bloqueo por rate-limit de la última versión oficial.
#  - Instalación 100% rootless sin solicitar sudo si curl y tar están presentes.
#  - Enlace simbólico automático a ~/.local/bin/opencode.
#  - Integración modular de shell en ~/.bashrc.d/opencode.sh y ~/.zshrc.d/
#  - Integración de sesión gráfica Wayland en ~/.config/environment.d/10-opencode.conf.
#  - Opciones de estado (--status), versión específica (--version), y desinstalación (--uninstall).
# ==============================================================================

set -euo pipefail

# Colores para salida formateada
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

# Detección de usuario real si se ejecuta con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

OPENCODE_DIR="$USER_HOME/.opencode"
OPENCODE_BIN="$OPENCODE_DIR/bin/opencode"
LOCAL_BIN="$USER_HOME/.local/bin"
LOCAL_BIN_LINK="$LOCAL_BIN/opencode"
BASHRC_D="$USER_HOME/.bashrc.d"
BASHRC_FILE="$BASHRC_D/opencode.sh"
ZSHRC_D="$USER_HOME/.zshrc.d"
ZSHRC_FILE="$ZSHRC_D/opencode.zsh"
ENV_D="$USER_HOME/.config/environment.d"
ENV_FILE="$ENV_D/10-opencode.conf"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# Obtiene la última versión publicada en GitHub sin consumir cuota de la API REST
get_latest_version() {
    local redirect_url version
    redirect_url=$(curl -sSI "https://github.com/anomalyco/opencode/releases/latest" 2>/dev/null | grep -i "^location:" | head -n1 || true)
    version=$(echo "$redirect_url" | grep -oP 'tag/v?\K[0-9.]+' | head -n1 || true)
    
    if [ -n "$version" ]; then
        echo "$version"
    else
        # Fallback si no hay conexión o cambió el formato
        echo "1.18.32"
    fi
}

show_help() {
    echo -e "${BOLD}Uso:${NC} $0 [opción]"
    echo ""
    echo -e "${BOLD}Opciones:${NC}"
    echo -e "  ${CYAN}-s, --status${NC}             Muestra el estado de instalación, rutas e integración"
    echo -e "  ${CYAN}-l, --latest${NC}             Instala o actualiza a la última versión disponible (predeterminado)"
    echo -e "  ${CYAN}-v, --version <versión>${NC}  Instala una versión específica (ej: 1.18.32)"
    echo -e "  ${CYAN}--uninstall${NC}              Desinstala OpenCode y limpia archivos de entorno"
    echo -e "  ${CYAN}-h, --help${NC}               Muestra este mensaje de ayuda"
    echo ""
    echo -e "${BOLD}Ejemplos:${NC}"
    echo -e "  $0                       # Instala/actualiza a la versión más reciente"
    echo -e "  $0 --status              # Comprueba versiones y estado del sistema"
    echo -e "  $0 -v 1.18.32            # Instala versión específica"
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🤖 ${BOLD}Estado de OpenCode AI CLI en openSUSE Tumbleweed${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    
    local installed_version="No detectada"
    local is_installed=false
    
    if [ -x "$OPENCODE_BIN" ]; then
        installed_version=$("$OPENCODE_BIN" --version 2>/dev/null || echo "Desconocida")
        is_installed=true
    elif command -v opencode &>/dev/null; then
        installed_version=$(opencode --version 2>/dev/null || echo "Desconocida")
        is_installed=true
    fi
    
    echo -e "👤 ${BOLD}Usuario objetivo:${NC} $REAL_USER ($USER_HOME)"
    
    if [ "$is_installed" = true ]; then
        echo -e "📦 ${BOLD}Estado OpenCode:${NC}  ${GREEN}Instalado${NC}"
        echo -e "🏷️  ${BOLD}Versión actual:${NC}   ${CYAN}$installed_version${NC}"
    else
        echo -e "📦 ${BOLD}Estado OpenCode:${NC}  ${RED}No instalado${NC}"
    fi
    
    echo -ne "🌐 ${BOLD}Última versión:${NC}   "
    local latest_version
    latest_version=$(get_latest_version)
    echo -e "${CYAN}$latest_version${NC}"
    
    if [ "$is_installed" = true ]; then
        if [ "$installed_version" = "$latest_version" ]; then
            echo -e "✨ ${BOLD}Actualización:${NC}    ${GREEN}Al día con la versión más reciente${NC}"
        else
            echo -e "⚡ ${BOLD}Actualización:${NC}    ${YELLOW}Actualización disponible ($installed_version -> $latest_version)${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BOLD}📁 Rutas y Binarios:${NC}"
    if [ -f "$OPENCODE_BIN" ]; then
        echo -e "  • Binario nativo:     ${GREEN}$OPENCODE_BIN${NC} ($(du -h "$OPENCODE_BIN" | cut -f1))"
    else
        echo -e "  • Binario nativo:     ${YELLOW}No existe ($OPENCODE_BIN)${NC}"
    fi
    
    if [ -L "$LOCAL_BIN_LINK" ]; then
        local link_target
        link_target=$(readlink "$LOCAL_BIN_LINK")
        echo -e "  • Enlace ~/.local/bin: ${GREEN}$LOCAL_BIN_LINK -> $link_target${NC}"
    elif [ -f "$LOCAL_BIN_LINK" ]; then
        echo -e "  • Enlace ~/.local/bin: ${YELLOW}$LOCAL_BIN_LINK (archivo binario directo)${NC}"
    else
        echo -e "  • Enlace ~/.local/bin: ${RED}No presente ($LOCAL_BIN_LINK)${NC}"
    fi
    
    echo ""
    echo -e "${BOLD}⚙️  Integración de Entorno y Shells:${NC}"
    if [ -f "$BASHRC_FILE" ]; then
        echo -e "  • Bash (~/.bashrc.d):     ${GREEN}Configurado ($BASHRC_FILE)${NC}"
    else
        echo -e "  • Bash (~/.bashrc.d):     ${YELLOW}No configurado${NC}"
    fi
    
    if [ -f "$ENV_FILE" ]; then
        echo -e "  • KDE Plasma / Wayland:   ${GREEN}Configurado ($ENV_FILE)${NC}"
    else
        echo -e "  • KDE Plasma / Wayland:   ${YELLOW}No configurado${NC}"
    fi
    
    if [ -d "$USER_HOME/.zshrc.d" ] || [ -f "$USER_HOME/.zshrc" ]; then
        if [ -f "$ZSHRC_FILE" ]; then
            echo -e "  • Zsh (~/.zshrc.d):      ${GREEN}Configurado ($ZSHRC_FILE)${NC}"
        else
            echo -e "  • Zsh (~/.zshrc.d):      ${YELLOW}No configurado${NC}"
        fi
    fi
    
    echo ""
    if command -v opencode &>/dev/null; then
        echo -e "🔍 ${BOLD}Resolución PATH:${NC}     ${GREEN}$(command -v opencode)${NC}"
    else
        echo -e "🔍 ${BOLD}Resolución PATH:${NC}     ${YELLOW}No visible en el PATH de la sesión actual${NC}"
    fi
    echo -e "${BOLD}=================================================================${NC}"
}

check_dependencies() {
    local missing=()
    command -v curl &>/dev/null || missing+=("curl")
    command -v tar &>/dev/null || missing+=("tar")
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "ℹ️  ${YELLOW}Instalando dependencias requeridas del sistema (${missing[*]})...${NC}"
        if [ "$EUID" -ne 0 ]; then
            if ! command -v sudo &>/dev/null; then
                echo -e "${RED}❌ Error: 'sudo' no está disponible para instalar ${missing[*]}.${NC}"
                exit 1
            fi
            sudo zypper --non-interactive install -y "${missing[@]}"
        else
            zypper --non-interactive install -y "${missing[@]}"
        fi
    fi
}

install_opencode() {
    local target_version="$1"
    
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🤖 ${BOLD}Instalando OpenCode AI CLI (${CYAN}v$target_version${NC}${BOLD})...${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    
    # 1. Asegurar dependencias de forma idempotente
    check_dependencies
    
    # 2. Descargar instalador oficial e invocarlo en modo rootless sin alterar bashrc directamente
    local tmp_installer
    tmp_installer=$(mktemp /tmp/opencode_install_XXXXXX.sh)
    
    echo -e "⬇️  [1/4] Descargando instalador oficial de OpenCode..."
    curl -fsSL "https://opencode.ai/install" -o "$tmp_installer"
    
    echo -e "⚙️  [2/4] Ejecutando instalación de OpenCode $target_version..."
    run_as_user bash "$tmp_installer" --version "$target_version" --no-modify-path
    rm -f "$tmp_installer"
    
    # 3. Crear enlace en ~/.local/bin para disponibilidad directa en terminal
    echo -e "🔗 [3/4] Configurando enlace en ~/.local/bin..."
    run_as_user mkdir -p "$LOCAL_BIN"
    if [ -x "$OPENCODE_BIN" ]; then
        run_as_user ln -sfn "$OPENCODE_BIN" "$LOCAL_BIN_LINK"
    fi
    
    # 4. Integración modular en shells y KDE Plasma 6 Wayland
    echo -e "🐚 [4/4] Configurando integración en shells y KDE Plasma 6..."
    
    # Bash modular (~/.bashrc.d)
    if [ -d "$BASHRC_D" ]; then
        run_as_user tee "$BASHRC_FILE" > /dev/null << 'EOF'
# OpenCode AI CLI Environment
if [ -d "$HOME/.opencode/bin" ] && [[ ":$PATH:" != *":$HOME/.opencode/bin:"* ]]; then
    export PATH="$HOME/.opencode/bin:$PATH"
fi
EOF
    fi
    
    # Limpiar posibles entradas duplicadas añadidas directamente a ~/.bashrc
    if [ -f "$USER_HOME/.bashrc" ]; then
        sed -i '/# OpenCode AI CLI/,+1d' "$USER_HOME/.bashrc" 2>/dev/null || true
    fi
    
    # KDE Plasma 6 Wayland Session Environment
    run_as_user mkdir -p "$ENV_D"
    run_as_user tee "$ENV_FILE" > /dev/null << 'EOF'
# OpenCode AI CLI (KDE Plasma 6 + Wayland Session)
PATH=$HOME/.opencode/bin:$HOME/.local/bin:$PATH
EOF
    
    # Zsh modular (~/.zshrc.d) si el usuario utiliza Zsh
    if [ -d "$ZSHRC_D" ] || [ -f "$USER_HOME/.zshrc" ]; then
        run_as_user mkdir -p "$ZSHRC_D"
        run_as_user tee "$ZSHRC_FILE" > /dev/null << 'EOF'
# OpenCode AI CLI Environment
if [ -d "$HOME/.opencode/bin" ] && [[ ":$PATH:" != *":$HOME/.opencode/bin:"* ]]; then
    export PATH="$HOME/.opencode/bin:$PATH"
fi
EOF
        if [ -f "$USER_HOME/.zshrc" ]; then
            sed -i '/# OpenCode AI CLI/,+1d' "$USER_HOME/.zshrc" 2>/dev/null || true
        fi
    fi
    
    echo -e "${BOLD}=================================================================${NC}"
    if [ -x "$LOCAL_BIN_LINK" ] || [ -x "$OPENCODE_BIN" ]; then
        local installed_v
        installed_v=$("$OPENCODE_BIN" --version 2>/dev/null || "$LOCAL_BIN_LINK" --version 2>/dev/null || echo "$target_version")
        echo -e "${GREEN}✅ OpenCode AI CLI $installed_v instalado y configurado correctamente.${NC}"
    else
        echo -e "${GREEN}✅ Instalación finalizada.${NC}"
    fi
    echo -e "💡 El comando ${BOLD}opencode${NC} ya está disponible en ${CYAN}~/.local/bin${NC}."
    echo -e "💡 Para recargar variables en la terminal actual: ${BOLD}source ~/.bashrc${NC}"
    echo -e "${BOLD}=================================================================${NC}"
}

uninstall_opencode() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🗑️  ${YELLOW}Desinstalando OpenCode AI CLI...${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    
    if [ -d "$OPENCODE_DIR" ]; then
        run_as_user rm -rf "$OPENCODE_DIR"
        echo -e "  • Eliminado directorio: $OPENCODE_DIR"
    fi
    
    if [ -L "$LOCAL_BIN_LINK" ] || [ -f "$LOCAL_BIN_LINK" ]; then
        run_as_user rm -f "$LOCAL_BIN_LINK"
        echo -e "  • Eliminado enlace: $LOCAL_BIN_LINK"
    fi
    
    if [ -f "$BASHRC_FILE" ]; then
        run_as_user rm -f "$BASHRC_FILE"
        echo -e "  • Eliminada configuración Bash: $BASHRC_FILE"
    fi
    
    if [ -f "$ENV_FILE" ]; then
        run_as_user rm -f "$ENV_FILE"
        echo -e "  • Eliminada configuración Wayland: $ENV_FILE"
    fi
    
    if [ -f "$ZSHRC_FILE" ]; then
        run_as_user rm -f "$ZSHRC_FILE"
        echo -e "  • Eliminada configuración Zsh: $ZSHRC_FILE"
    fi
    
    if [ -f "$USER_HOME/.bashrc" ]; then
        sed -i '/# OpenCode AI CLI/,+1d' "$USER_HOME/.bashrc" 2>/dev/null || true
    fi
    if [ -f "$USER_HOME/.zshrc" ]; then
        sed -i '/# OpenCode AI CLI/,+1d' "$USER_HOME/.zshrc" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ OpenCode AI CLI ha sido desinstalado correctamente.${NC}"
    echo -e "ℹ️  Nota: Las configuraciones personales en ~/.config/opencode no se han eliminado."
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# Procesamiento de Parámetros
# ------------------------------------------------------------------------------
ACTION="install"
TARGET_VERSION=""

while [ $# -gt 0 ]; do
    case "$1" in
        -s|--status)
            ACTION="status"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--latest)
            ACTION="install"
            TARGET_VERSION=""
            shift
            ;;
        -v|--version)
            if [ -n "${2:-}" ] && [[ "$2" != -* ]]; then
                ACTION="install"
                TARGET_VERSION="$2"
                shift 2
            else
                echo -e "${RED}❌ Error: Se debe especificar un número de versión tras $1${NC}"
                exit 1
            fi
            ;;
        --uninstall)
            ACTION="uninstall"
            shift
            ;;
        *)
            # Si el argumento no empieza con guion, tratarlo como versión específica
            if [[ "$1" != -* ]]; then
                ACTION="install"
                TARGET_VERSION="$1"
                shift
            else
                echo -e "${RED}❌ Opción desconocida: $1${NC}"
                show_help
                exit 1
            fi
            ;;
    esac
done

case "$ACTION" in
    status)
        show_status
        ;;
    uninstall)
        uninstall_opencode
        ;;
    install)
        if [ -z "$TARGET_VERSION" ]; then
            echo -e "🔍 Consultando la última versión oficial de OpenCode..."
            TARGET_VERSION=$(get_latest_version)
        fi
        install_opencode "$TARGET_VERSION"
        ;;
esac
