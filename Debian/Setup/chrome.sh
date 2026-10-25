#!/usr/bin/env bash
# ==============================================================================
# chrome.sh - Instalación, Optimización y Diagnóstico de Google Chrome
# Sistema: Debian GNU/Linux | Escritorio: GNOME Shell (Wayland)
# Hardware: AMD Ryzen 7 7730U / Radeon Graphics (Vega 8) (VA-API)
# ==============================================================================
# Características:
# - Gestión idempotente del repositorio APT oficial firmado por Google.
# - Comprobación inteligente de clave GPG moderna (/etc/apt/keyrings/google-chrome.gpg).
# - Optimización nativa para Wayland y aceleración por GPU (Ozone + VA-API AMD).
# - Diagnóstico integral del estado del navegador, repositorio y aceleración gráfica.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
GPG_KEY_URL="https://dl.google.com/linux/linux_signing_key.pub"
KEYRING_FILE="/etc/apt/keyrings/google-chrome.gpg"
SOURCES_FILE="/etc/apt/sources.list.d/google-chrome.list"
PACKAGE_NAME="google-chrome-stable"
SYSTEM_DESKTOP="/usr/share/applications/google-chrome.desktop"

# Colores ANSI para terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# 2. DETECCIÓN DE USUARIO Y ELEVACIÓN DE PRIVILEGIOS
# ------------------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

USER_DESKTOP_DIR="$USER_HOME/.local/share/applications"
USER_DESKTOP_FILE="$USER_DESKTOP_DIR/google-chrome.desktop"

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

require_root() {
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo &>/dev/null; then
            echo -e "${RED}❌ Error:${NC} Esta operación requiere privilegios de administrador ('sudo')." >&2
            exit 1
        fi
    fi
}

show_help() {
    echo -e "${BOLD}🌐 Instalador y Optimizador de Google Chrome - Debian GNU/Linux${NC}

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)        Instala Google Chrome y activa el repositorio oficial de forma idempotente.
  -i, --install           Fuerza la configuración del repositorio e instalación del paquete.
  -u, --update            Busca e instala actualizaciones de Google Chrome desde el repositorio oficial.
  -w, --wayland           Optimiza el lanzador de escritorio para GNOME Shell Wayland y aceleración VA-API (AMD Vega).
      --restore-desktop   Restaura el lanzador de escritorio original del sistema.
  -s, --status            Muestra diagnóstico detallado del repositorio, paquete, Wayland y aceleración GPU.
  -r, --uninstall         Desinstala Google Chrome del sistema.
  -h, --help              Muestra este mensaje de ayuda."
}

is_chrome_installed() {
    dpkg -s "$PACKAGE_NAME" &>/dev/null
}

get_chrome_version() {
    if is_chrome_installed; then
        dpkg -s "$PACKAGE_NAME" 2>/dev/null | grep -i "^Version:" | awk '{print $2}'
    elif command -v google-chrome-stable &>/dev/null; then
        google-chrome-stable --version 2>/dev/null || echo "Desconocida"
    elif command -v google-chrome &>/dev/null; then
        google-chrome --version 2>/dev/null || echo "Desconocida"
    else
        echo "No instalado"
    fi
}

is_wayland_optimized() {
    if [ -f "$USER_DESKTOP_FILE" ]; then
        grep -q -- "--ozone-platform-hint=auto" "$USER_DESKTOP_FILE" 2>/dev/null
    else
        return 1
    fi
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE GOOGLE CHROME - DEBIAN GNU/LINUX (GNOME WAYLAND)${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    if [ -f "$SOURCES_FILE" ]; then
        echo -e "• ${BOLD}Repositorio APT:${NC}        ${GREEN}✅ Configurado ($SOURCES_FILE)${NC}"
    else
        echo -e "• ${BOLD}Repositorio APT:${NC}        ${RED}❌ No configurado${NC}"
    fi

    if [ -f "$KEYRING_FILE" ]; then
        echo -e "• ${BOLD}Clave GPG de Google:${NC}   ${GREEN}✅ Presente en $KEYRING_FILE${NC}"
    else
        echo -e "• ${BOLD}Clave GPG de Google:${NC}   ${YELLOW}⚠️ No encontrada${NC}"
    fi

    local chrome_ver
    chrome_ver=$(get_chrome_version)
    if is_chrome_installed; then
        echo -e "• ${BOLD}Paquete Chrome:${NC}        ${GREEN}✅ Instalado (v${chrome_ver})${NC}"
    else
        echo -e "• ${BOLD}Paquete Chrome:${NC}        ${RED}❌ No instalado${NC}"
    fi

    if is_wayland_optimized; then
        echo -e "• ${BOLD}Optimización Wayland:${NC}  ${GREEN}✅ Activa (--ozone-platform-hint=auto + VA-API)${NC}"
    else
        echo -e "• ${BOLD}Optimización Wayland:${NC}  ${YELLOW}ℹ️ Predeterminada del sistema (ejecuta '$0 --wayland')${NC}"
    fi

    echo -e "${CYAN}=================================================================${NC}"
}

setup_repo() {
    require_root
    echo -e "${BLUE}ℹ️ Configurando repositorio oficial y clave de Google Chrome...${NC}"
    $SUDO mkdir -p /etc/apt/keyrings
    if [ ! -f "$KEYRING_FILE" ]; then
        curl -fsSL "$GPG_KEY_URL" | gpg --dearmor | $SUDO tee "$KEYRING_FILE" > /dev/null
        $SUDO chmod 644 "$KEYRING_FILE"
    fi

    echo "deb [arch=amd64 signed-by=$KEYRING_FILE] http://dl.google.com/linux/chrome/deb/ stable main" | $SUDO tee "$SOURCES_FILE" > /dev/null
    $SUDO chmod 644 "$SOURCES_FILE"
    echo -e "${GREEN}✅ Repositorio oficial configurado correctamente.${NC}"
}

install_chrome() {
    if is_chrome_installed; then
        echo -e "${GREEN}✅ Google Chrome ya está instalado ($(get_chrome_version)).${NC}"
        return 0
    fi

    setup_repo
    require_root
    echo -e "${BLUE}⬇️ Instalando Google Chrome vía APT...${NC}"
    $SUDO apt-get update -qq
    $SUDO apt-get install -y "$PACKAGE_NAME"
    echo -e "${GREEN}✅ Google Chrome instalado exitosamente.${NC}"
}

update_chrome() {
    require_root
    setup_repo
    echo -e "${BLUE}🔄 Actualizando Google Chrome vía APT...${NC}"
    $SUDO apt-get update -qq
    $SUDO apt-get install --only-upgrade -y "$PACKAGE_NAME"
    echo -e "${GREEN}✅ Google Chrome actualizado.${NC}"
}

optimize_wayland() {
    echo -e "${BLUE}🚀 Optimizando lanzador para GNOME Shell Wayland y aceleración GPU (AMD Vega)...${NC}"
    if [ ! -f "$SYSTEM_DESKTOP" ]; then
        echo -e "${RED}❌ Error: No se encontró $SYSTEM_DESKTOP. Instala Chrome primero.${NC}"
        return 1
    fi

    mkdir -p "$USER_DESKTOP_DIR"
    cp "$SYSTEM_DESKTOP" "$USER_DESKTOP_FILE"

    local wayland_flags="--ozone-platform-hint=auto --enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy"
    
    sed -i "s|^Exec=/usr/bin/google-chrome-stable %U|Exec=/usr/bin/google-chrome-stable $wayland_flags %U|" "$USER_DESKTOP_FILE"
    sed -i "s|^Exec=/usr/bin/google-chrome-stable$|Exec=/usr/bin/google-chrome-stable $wayland_flags|" "$USER_DESKTOP_FILE"

    chmod 644 "$USER_DESKTOP_FILE"
    update-desktop-database "$USER_DESKTOP_DIR" 2>/dev/null || true
    echo -e "${GREEN}✅ Lanzador optimizado para Wayland configurado en $USER_DESKTOP_FILE.${NC}"
}

restore_desktop() {
    if [ -f "$USER_DESKTOP_FILE" ]; then
        rm -f "$USER_DESKTOP_FILE"
        update-desktop-database "$USER_DESKTOP_DIR" 2>/dev/null || true
        echo -e "${GREEN}✅ Lanzador personalizado eliminado. Se usará el lanzador estándar del sistema.${NC}"
    else
        echo -e "${YELLOW}ℹ️ No se detectó un lanzador personalizado en el perfil de usuario.${NC}"
    fi
}

uninstall_chrome() {
    require_root
    echo -e "${YELLOW}🗑️ Desinstalando Google Chrome...${NC}"
    $SUDO apt-get purge -y "$PACKAGE_NAME"
    rm -f "$USER_DESKTOP_FILE"
    echo -e "${GREEN}✅ Google Chrome desinstalado.${NC}"
}

case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    -i|--install|install)
        install_chrome
        ;;
    -u|--update|update)
        update_chrome
        ;;
    -w|--wayland|wayland)
        optimize_wayland
        ;;
    --restore-desktop)
        restore_desktop
        ;;
    -r|--uninstall|uninstall)
        uninstall_chrome
        ;;
    "")
        install_chrome
        optimize_wayland
        ;;
    *)
        echo -e "${RED}❌ Opción desconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac
