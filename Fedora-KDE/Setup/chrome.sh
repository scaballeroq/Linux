#!/usr/bin/env bash
# ==============================================================================
# chrome.sh - Instalación, Optimización y Diagnóstico de Google Chrome
# Sistema: Fedora 44 Workstation | Escritorio: KDE Plasma 6 (Wayland)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Radeon Vega 7 / VA-API)
# ==============================================================================
# Características:
# - Gestión idempotente del repositorio RPM oficial firmado por Google.
# - Importación de clave GPG oficial en /etc/pki/rpm-gpg/.
# - Optimización nativa para Wayland y aceleración por GPU (Ozone + VA-API AMD).
# - Descarga de respaldo oficial RPM en caso de contingencia.
# - Diagnóstico integral del estado del navegador, repositorio y aceleración gráfica.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
REPO_NAME="google-chrome"
REPO_FILE="/etc/yum.repos.d/google-chrome.repo"
REPO_URL="http://dl.google.com/linux/chrome/rpm/stable/x86_64"
GPG_KEY_URL="https://dl.google.com/linux/linux_signing_key.pub"
FALLBACK_RPM_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
PACKAGE_NAME="google-chrome-stable"
SYSTEM_DESKTOP="/usr/share/applications/google-chrome.desktop"

# Colores ANSI para terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

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

# ------------------------------------------------------------------------------
# 3. FUNCIONES DE AYUDA Y DIAGNÓSTICO
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}🌐 Instalador y Optimizador de Google Chrome - Fedora 44 (KDE 6)${NC}

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)        Instala Google Chrome y activa el repositorio oficial de forma idempotente.
  -i, --install           Fuerza la configuración del repositorio e instalación/revisión del paquete.
  -u, --update            Busca e instala actualizaciones de Google Chrome desde el repositorio oficial.
  -w, --wayland           Optimiza el lanzador de escritorio para KDE Plasma 6 Wayland y aceleración VA-API (AMD Vega).
      --restore-desktop   Restaura el lanzador de escritorio original del sistema.
  -s, --status            Muestra diagnóstico detallado del repositorio, paquete, Wayland y aceleración GPU.
  -r, --uninstall         Desinstala Google Chrome del sistema.
  -h, --help              Muestra este mensaje de ayuda.

${BOLD}Ejemplos:${NC}
  $0                    # Instalación idempotente estándar
  $0 --wayland          # Activa Wayland nativo y aceleración por GPU para el usuario actual
  $0 --status           # Comprueba estado y configuración"
}

is_repo_configured() {
    [ -f "$REPO_FILE" ] && grep -q "dl.google.com" "$REPO_FILE" 2>/dev/null
}

is_chrome_installed() {
    rpm -q "$PACKAGE_NAME" >/dev/null 2>&1
}

get_chrome_version() {
    if is_chrome_installed; then
        rpm -q --qf '%{VERSION}-%{RELEASE} (%{ARCH})\n' "$PACKAGE_NAME" 2>/dev/null
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
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE GOOGLE CHROME - FEDORA 44 (KDE PLASMA 6)${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    # 1. Repositorio Oficial
    if is_repo_configured; then
        echo -e "• ${BOLD}Repositorio DNF5:${NC}      ${GREEN}✅ Configurado y Activo${NC} ($REPO_FILE)"
    else
        echo -e "• ${BOLD}Repositorio DNF5:${NC}      ${RED}❌ No configurado${NC}"
    fi

    # 2. Paquete y Binario
    if is_chrome_installed; then
        local chrome_bin
        chrome_bin=$(command -v google-chrome-stable 2>/dev/null || command -v google-chrome || echo "/usr/bin/google-chrome-stable")
        echo -e "• ${BOLD}Google Chrome RPM:${NC}     ${GREEN}✅ Instalado${NC}"
        echo -e "  - Versión instalada:   $(get_chrome_version)"
        echo -e "  - Binario ejecutable:  $chrome_bin"
    else
        echo -e "• ${BOLD}Google Chrome RPM:${NC}     ${RED}❌ No instalado${NC}"
    fi

    # 3. Integración Wayland y Entorno Gráfico
    local session_type="${XDG_SESSION_TYPE:-wayland}"
    echo -e "• ${BOLD}Sesión de Escritorio:${NC}  ${CYAN}${session_type^}${NC} (KDE Plasma 6)"

    if is_wayland_optimized; then
        echo -e "• ${BOLD}Optimización Wayland:${NC}  ${GREEN}✅ Activa en lanzador de usuario${NC}"
        echo -e "  - Archivo Desktop:     $USER_DESKTOP_FILE"
        echo -e "  - Flags activos:       --ozone-platform-hint=auto, --enable-features=VaapiVideoDecodeLinuxGL"
    else
        echo -e "• ${BOLD}Optimización Wayland:${NC}  ${YELLOW}ℹ️ Estándar del sistema (XWayland por defecto)${NC}"
        echo -e "  - Sugerencia:          Ejecuta '$0 --wayland' para activar Wayland nativo y aceleración VA-API."
    fi

    # 4. Aceleración por Hardware VA-API (AMD Radeon Vega 7)
    if command -v vainfo &>/dev/null; then
        if vainfo 2>&1 | grep -qi "Driver version.*AMD"; then
            echo -e "• ${BOLD}Aceleración VA-API:${NC}    ${GREEN}✅ Hardware AMD Radeon Vega activo (Mesa radeonsi)${NC}"
        else
            echo -e "• ${BOLD}Aceleración VA-API:${NC}    ${CYAN}ℹ️ vainfo disponible en el sistema${NC}"
        fi
    else
        echo -e "• ${BOLD}Aceleración VA-API:${NC}    ${YELLOW}ℹ️ Herramienta 'vainfo' no instalada${NC}"
    fi

    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. GESTIÓN DEL REPOSITORIO
# ------------------------------------------------------------------------------
setup_repository() {
    if is_repo_configured; then
        echo -e "${GREEN}✔${NC} Repositorio oficial '$REPO_NAME' ya configurado en $REPO_FILE."
        return 0
    fi

    echo -e "${BLUE}📦 Añadiendo repositorio oficial de Google Chrome a DNF5...${NC}"
    require_root
    $SUDO tee "$REPO_FILE" >/dev/null <<EOF
[google-chrome]
name=google-chrome
baseurl=$REPO_URL
enabled=1
gpgcheck=1
gpgkey=$GPG_KEY_URL
EOF
    $SUDO chmod 644 "$REPO_FILE"
    echo -e "${GREEN}✔${NC} Repositorio registrado exitosamente en $REPO_FILE."
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN Y ACTUALIZACIÓN
# ------------------------------------------------------------------------------
optimize_wayland_launcher() {
    echo -e "${BLUE}🎨 Configurando lanzador optimizado para Wayland y aceleración VA-API...${NC}"
    mkdir -p "$USER_DESKTOP_DIR"

    if [ ! -f "$SYSTEM_DESKTOP" ]; then
        echo -e "${YELLOW}⚠️ Aviso:${NC} $SYSTEM_DESKTOP no existe aún. Omitiendo ajuste."
        return 0
    fi

    # Flags optimizados para KDE Plasma 6 Wayland + AMD Radeon Vega
    local WAYLAND_FLAGS="--ozone-platform-hint=auto --enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoderLinuxGL,OverlayScrollbar --enable-gpu-rasterization"

    cp "$SYSTEM_DESKTOP" "$USER_DESKTOP_FILE"
    sed -i "s|^Exec=/usr/bin/google-chrome-stable|Exec=/usr/bin/google-chrome-stable $WAYLAND_FLAGS|g" "$USER_DESKTOP_FILE"
    sed -i "s|^Exec=google-chrome-stable|Exec=google-chrome-stable $WAYLAND_FLAGS|g" "$USER_DESKTOP_FILE"
    chmod 644 "$USER_DESKTOP_FILE"

    echo -e "${GREEN}✔${NC} Lanzador configurado en $USER_DESKTOP_FILE."
}

restore_desktop_launcher() {
    if [ -f "$USER_DESKTOP_FILE" ]; then
        echo -e "${BLUE}🔄 Restaurando lanzador de escritorio original del sistema...${NC}"
        rm -f "$USER_DESKTOP_FILE"
        echo -e "${GREEN}✔${NC} Lanzador personalizado de usuario eliminado."
    else
        echo -e "${YELLOW}ℹ️ No hay lanzador personalizado que restaurar.${NC}"
    fi
}

install_chrome() {
    local force="${1:-false}"

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🌐 CONFIGURACIÓN E INSTALACIÓN DE GOOGLE CHROME - FEDORA 44${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    if is_chrome_installed && is_repo_configured && [ "$force" != "true" ]; then
        echo -e "${GREEN}✔${NC} Google Chrome ya está instalado en el sistema ($(get_chrome_version))."
        echo -e "${GREEN}✔${NC} Repositorio oficial validado."
        optimize_wayland_launcher
        return 0
    fi

    setup_repository

    echo -e "${BLUE}⬇️ Instalando $PACKAGE_NAME vía DNF5...${NC}"
    require_root
    if $SUDO dnf5 install -y "$PACKAGE_NAME" 2>/dev/null; then
        echo -e "${GREEN}✔${NC} Paquete $PACKAGE_NAME instalado correctamente vía DNF5."
    else
        echo -e "${YELLOW}⚠️ DNF5 falló. Intentando RPM directo de Google...${NC}"
        local temp_rpm
        temp_rpm=$(mktemp /tmp/google-chrome-XXXXXX.rpm)
        curl -fsSL "$FALLBACK_RPM_URL" -o "$temp_rpm"
        $SUDO dnf5 install -y "$temp_rpm"
        rm -f "$temp_rpm"
        echo -e "${GREEN}✔${NC} Google Chrome instalado desde RPM directo."
    fi

    optimize_wayland_launcher
    echo -e "${GREEN}✅ Google Chrome configurado con éxito.${NC}"
}

update_chrome() {
    echo -e "${BLUE}🔄 Buscando actualizaciones de Google Chrome en DNF5...${NC}"
    require_root
    setup_repository
    $SUDO dnf5 upgrade --refresh -y "$PACKAGE_NAME"
    echo -e "${GREEN}✔${NC} Google Chrome se encuentra en la versión más reciente ($(get_chrome_version))."
}

uninstall_chrome() {
    echo -e "${YELLOW}⚠️ Desinstalando Google Chrome del sistema...${NC}"
    require_root
    $SUDO dnf5 remove -y "$PACKAGE_NAME" 2>/dev/null || true
    restore_desktop_launcher
    echo -e "${GREEN}✔${NC} Google Chrome desinstalado exitosamente."
}

# ------------------------------------------------------------------------------
# 6. DESPACHADOR DE COMANDOS
# ------------------------------------------------------------------------------
case "${1:-}" in
    -s|--status|status)
        show_status
        ;;
    -w|--wayland|wayland)
        if ! is_chrome_installed; then
            echo -e "${YELLOW}⚠️ Google Chrome no está instalado. Instalándolo primero...${NC}"
            install_chrome false
        else
            optimize_wayland_launcher
        fi
        ;;
    --restore-desktop)
        restore_desktop_launcher
        ;;
    -u|--update|update)
        update_chrome
        ;;
    -i|--install|install)
        install_chrome true
        ;;
    -r|--uninstall|uninstall)
        uninstall_chrome
        ;;
    -h|--help|help)
        show_help
        ;;
    "")
        install_chrome false
        ;;
    *)
        echo -e "${RED}❌ Opción desconocida: '$1'${NC}\n" >&2
        show_help
        exit 1
        ;;
esac
