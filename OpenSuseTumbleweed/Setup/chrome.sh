#!/usr/bin/env bash
# ==============================================================================
# chrome.sh - Instalación, Optimización y Diagnóstico de Google Chrome
# Sistema: openSUSE Tumbleweed | Escritorio: KDE Plasma 6 (Wayland)
# Hardware: AMD Ryzen 7 PRO 4750U / Radeon Vega 7 (VA-API)
# ==============================================================================
# Características:
# - Gestión idempotente del repositorio RPM oficial firmado por Google.
# - Comprobación inteligente de clave GPG en llavero RPM (sin descargas redundantes).
# - Prevención de instantáneas redundantes de Snapper en Btrfs si ya está instalado.
# - Optimización nativa para Wayland y aceleración por GPU (Ozone + VA-API AMD).
# - Descarga de respaldo oficial segura con limpieza garantizada mediante traps.
# - Ajuste de /etc/default/google-chrome para evitar interferencias de cron con Zypper.
# - Diagnóstico integral del estado del navegador, repositorio y aceleración gráfica.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
REPO_ALIAS="google-chrome"
REPO_NAME="Google Chrome"
REPO_URL="https://dl.google.com/linux/chrome/rpm/stable/x86_64"
GPG_KEY_URL="https://dl.google.com/linux/linux_signing_key.pub"
FALLBACK_RPM_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
PACKAGE_NAME="google-chrome-stable"
SYSTEM_DESKTOP="/usr/share/applications/google-chrome.desktop"
DEFAULTS_FILE="/etc/default/google-chrome"

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
    echo -e "${BOLD}🌐 Instalador y Optimizador de Google Chrome - openSUSE Tumbleweed${NC}

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
    zypper lr -u 2>/dev/null | grep -qE "${REPO_URL}|${REPO_ALIAS}"
}

is_repo_enabled() {
    local repo_info
    repo_info=$(zypper lr -u 2>/dev/null | grep -E "${REPO_ALIAS}" || true)
    if [ -n "$repo_info" ]; then
        # Comprobar si la columna Enabled indica Sí / Yes / 1
        echo "$repo_info" | grep -qiE "\b(sí|yes|1)\b"
    else
        return 1
    fi
}

is_gpg_imported() {
    rpm -qa "gpg-pubkey*" --qf '%{SUMMARY}\n' 2>/dev/null | grep -qi "Google Inc."
}

is_chrome_installed() {
    rpm -q "$PACKAGE_NAME" &>/dev/null
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
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE GOOGLE CHROME - OPENSUSE TUMBLEWEED${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    # 1. Repositorio Oficial
    if is_repo_configured; then
        if is_repo_enabled; then
            echo -e "• ${BOLD}Repositorio Zypper:${NC}    ${GREEN}✅ Configurado y Activo${NC} ($REPO_ALIAS)"
        else
            echo -e "• ${BOLD}Repositorio Zypper:${NC}    ${YELLOW}⚠️ Configurado pero Deshabilitado${NC} ($REPO_ALIAS)"
        fi
        local repo_uri
        repo_uri=$(zypper lr -u 2>/dev/null | grep -E "${REPO_ALIAS}" | awk -F'|' '{print $NF}' | xargs)
        echo -e "  - URI Oficial:         ${repo_uri:-$REPO_URL}"
    else
        echo -e "• ${BOLD}Repositorio Zypper:${NC}    ${RED}❌ No configurado${NC}"
    fi

    # 2. Clave GPG
    if is_gpg_imported; then
        echo -e "• ${BOLD}Clave GPG de Google:${NC}   ${GREEN}✅ Importada en la base de datos RPM${NC}"
    else
        echo -e "• ${BOLD}Clave GPG de Google:${NC}   ${YELLOW}⚠️ No encontrada en el llavero RPM${NC}"
    fi

    # 3. Paquete y Binario
    if is_chrome_installed; then
        local chrome_bin
        chrome_bin=$(command -v google-chrome-stable 2>/dev/null || command -v google-chrome || echo "/usr/bin/google-chrome-stable")
        echo -e "• ${BOLD}Google Chrome RPM:${NC}     ${GREEN}✅ Instalado${NC}"
        echo -e "  - Versión instalada:   $(get_chrome_version)"
        echo -e "  - Binario ejecutable:  $chrome_bin"
    else
        echo -e "• ${BOLD}Google Chrome RPM:${NC}     ${RED}❌ No instalado${NC}"
    fi

    # 4. Integración Wayland y Entorno Gráfico
    local session_type="${XDG_SESSION_TYPE:-desconocida}"
    echo -e "• ${BOLD}Sesión de Escritorio:${NC}  ${CYAN}${session_type^}${NC} (KDE Plasma 6)"

    if is_wayland_optimized; then
        echo -e "• ${BOLD}Optimización Wayland:${NC}  ${GREEN}✅ Activa en lanzador de usuario${NC}"
        echo -e "  - Archivo Desktop:     $USER_DESKTOP_FILE"
        echo -e "  - Flags activos:       --ozone-platform-hint=auto, --enable-features=VaapiVideoDecodeLinuxGL"
    else
        echo -e "• ${BOLD}Optimización Wayland:${NC}  ${YELLOW}ℹ️ Estándar del sistema (XWayland por defecto)${NC}"
        echo -e "  - Sugerencia:          Ejecuta '$0 --wayland' para activar Wayland nativo y aceleración VA-API."
    fi

    # 5. Aceleración por Hardware VA-API (AMD Radeon Vega 7)
    if command -v vainfo &>/dev/null; then
        if vainfo 2>&1 | grep -qi "Driver version.*AMD"; then
            echo -e "• ${BOLD}Aceleración VA-API:${NC}    ${GREEN}✅ Hardware AMD Radeon Vega activo (Mesa RADV/radeonsi)${NC}"
        else
            echo -e "• ${BOLD}Aceleración VA-API:${NC}    ${CYAN}ℹ️ vainfo disponible en el sistema${NC}"
        fi
    else
        echo -e "• ${BOLD}Aceleración VA-API:${NC}    ${YELLOW}ℹ️ Herramienta 'vainfo' no instalada (opcional: zypper in libva-utils)${NC}"
    fi

    # 6. Configuración de Cron / Defaults
    if [ -f "$DEFAULTS_FILE" ]; then
        local repo_cron
        repo_cron=$(grep -E "^[[:space:]]*repo_add_once=" "$DEFAULTS_FILE" 2>/dev/null || echo "no configurado")
        echo -e "• ${BOLD}Ajuste de Cron Google:${NC} Configurado ($repo_cron)"
    fi

    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. GESTIÓN DEL REPOSITORIO Y CLAVE GPG
# ------------------------------------------------------------------------------
setup_gpg_key() {
    if is_gpg_imported; then
        echo -e "${GREEN}✔${NC} Clave pública GPG de Google ya presente en el sistema."
        return 0
    fi

    echo -e "${BLUE}🔑 Importando clave pública GPG oficial de Google...${NC}"
    require_root

    local temp_key
    temp_key=$(mktemp /tmp/google-key-XXXXXX.pub)

    if curl -fsSL "$GPG_KEY_URL" -o "$temp_key"; then
        $SUDO rpm --import "$temp_key"
        rm -f "$temp_key"
        echo -e "${GREEN}✔${NC} Clave pública GPG de Google importada correctamente."
    else
        rm -f "$temp_key"
        echo -e "${YELLOW}⚠️ Aviso:${NC} No se pudo descargar la clave GPG directamente. Se intentará auto-importar con Zypper."
    fi
}

setup_repository() {
    if is_repo_configured; then
        if ! is_repo_enabled; then
            echo -e "${YELLOW}🔄 Reactivando repositorio $REPO_ALIAS deshabilitado...${NC}"
            require_root
            $SUDO zypper --non-interactive mr -e -r "$REPO_ALIAS"
        else
            echo -e "${GREEN}✔${NC} Repositorio oficial '$REPO_ALIAS' ya está configurado y habilitado."
        fi
    else
        echo -e "${BLUE}📦 Añadiendo repositorio oficial de Google Chrome a Zypper...${NC}"
        require_root
        $SUDO zypper --non-interactive addrepo \
            --check \
            --refresh \
            --name "$REPO_NAME" \
            "$REPO_URL" \
            "$REPO_ALIAS"
        echo -e "${GREEN}✔${NC} Repositorio '$REPO_ALIAS' registrado exitosamente."
    fi
}

refresh_repository() {
    require_root
    echo -e "${BLUE}🔄 Refrescando metadatos del repositorio oficial...${NC}"
    $SUDO zypper --gpg-auto-import-keys refresh "$REPO_ALIAS" || {
        echo -e "${YELLOW}⚠️ Aviso:${NC} No se pudo refrescar el repositorio inmediatamente. Continuando..."
    }
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN Y ACTUALIZACIÓN
# ------------------------------------------------------------------------------
install_chrome() {
    local force="${1:-false}"

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🌐 CONFIGURACIÓN E INSTALACIÓN DE GOOGLE CHROME - OPENSUSE${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    # Si ya está instalado, el repositorio activo y la clave GPG presente, y no se fuerza:
    if is_chrome_installed && is_repo_configured && is_repo_enabled && is_gpg_imported && [ "$force" != "true" ]; then
        echo -e "${GREEN}✔${NC} Google Chrome ya está instalado en el sistema ($(get_chrome_version))."
        echo -e "${GREEN}✔${NC} Repositorio oficial '$REPO_ALIAS' y clave GPG validados."
        echo -e "   Para buscar o forzar actualizaciones, ejecuta: ${BOLD}$0 --update${NC} (o 'just chrome -u')"
        optimize_wayland_launcher
        show_final_summary
        return 0
    fi

    # Paso 1: Configurar Clave GPG
    setup_gpg_key

    # Paso 2: Configurar Repositorio
    setup_repository
    refresh_repository

    # Paso 3: Verificar si ya está instalado tras asegurar repo
    if is_chrome_installed && [ "$force" != "true" ]; then
        echo -e "${GREEN}✔${NC} Google Chrome ya está instalado en el sistema ($(get_chrome_version))."
        echo -e "   Para verificar o forzar actualización, ejecuta: ${BOLD}$0 --update${NC}"
        configure_defaults_file
        optimize_wayland_launcher
        show_final_summary
        return 0
    fi

    # Paso 4: Instalar vía Zypper
    echo -e "${BLUE}⬇️ Instalando $PACKAGE_NAME vía Zypper...${NC}"
    require_root

    if $SUDO zypper --non-interactive install -y "$PACKAGE_NAME"; then
        echo -e "${GREEN}✔${NC} Paquete $PACKAGE_NAME instalado correctamente vía Zypper."
    else
        echo -e "${YELLOW}⚠️ Zypper reportó un problema con el repositorio.${NC}"
        echo -e "${BLUE}⬇️ Intentando descarga directa del paquete RPM oficial de Google...${NC}"
        
        local temp_rpm
        temp_rpm=$(mktemp /tmp/google-chrome-XXXXXX.rpm)
        # Asegurar limpieza en cualquier circunstancia
        trap 'rm -f "$temp_rpm"' EXIT INT TERM

        if curl -fsSL "$FALLBACK_RPM_URL" -o "$temp_rpm"; then
            echo -e "${BLUE}📦 Instalando RPM descargado y resolviendo dependencias...${NC}"
            $SUDO zypper --non-interactive install -y "$temp_rpm"
            rm -f "$temp_rpm"
            trap - EXIT INT TERM
            echo -e "${GREEN}✔${NC} Google Chrome instalado exitosamente mediante paquete RPM directo."
        else
            echo -e "${RED}❌ Error:${NC} No se pudo descargar el paquete RPM oficial desde Google."
            rm -f "$temp_rpm"
            trap - EXIT INT TERM
            exit 1
        fi
    fi

    # Paso 5: Ajuste de archivos de configuración y Wayland
    configure_defaults_file
    optimize_wayland_launcher
    show_final_summary
}

update_chrome() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔄 ACTUALIZACIÓN DE GOOGLE CHROME${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    require_root
    setup_gpg_key
    setup_repository
    refresh_repository

    echo -e "${BLUE}🔍 Comprobando actualizaciones para $PACKAGE_NAME...${NC}"
    if $SUDO zypper --non-interactive update -y "$PACKAGE_NAME"; then
        echo -e "${GREEN}✔${NC} Proceso de actualización finalizado con éxito."
        echo -e "   Versión actual: $(get_chrome_version)"
    else
        echo -e "${RED}❌ Error:${NC} Falló la actualización de Google Chrome."
        exit 1
    fi
}

configure_defaults_file() {
    # Evita que /etc/cron.daily/google-chrome intente reconfigurar repositorios en segundo plano
    if [ ! -f "$DEFAULTS_FILE" ] || ! grep -q 'repo_add_once="false"' "$DEFAULTS_FILE" 2>/dev/null; then
        require_root
        if [ ! -d "/etc/default" ]; then
            $SUDO mkdir -p /etc/default
        fi
        echo 'repo_add_once="false"' | $SUDO tee "$DEFAULTS_FILE" >/dev/null
    fi
}

# ------------------------------------------------------------------------------
# 6. OPTIMIZACIÓN WAYLAND Y ACELERACIÓN POR HARDWARE (AMD VEGA)
# ------------------------------------------------------------------------------
optimize_wayland_launcher() {
    if [ ! -f "$SYSTEM_DESKTOP" ]; then
        return 0
    fi

    echo -e "${BLUE}🚀 Optimizando lanzador de escritorio para Wayland y aceleración GPU (AMD Vega)...${NC}"

    # Crear directorio local si no existe
    if [ ! -d "$USER_DESKTOP_DIR" ]; then
        if [ "$EUID" -eq 0 ] && [ "$REAL_USER" != "root" ]; then
            su - "$REAL_USER" -c "mkdir -p '$USER_DESKTOP_DIR'"
        else
            mkdir -p "$USER_DESKTOP_DIR"
        fi
    fi

    # Flags de optimización:
    # --ozone-platform-hint=auto: Wayland nativo bajo Wayland, X11 bajo X11.
    # --enable-features=VaapiVideoDecodeLinuxGL: Decodificación por hardware de vídeo VA-API (radeonsi/amdgpu).
    # --enable-gpu-rasterization: Rasterización por GPU para rendimiento óptimo.
    local wayland_flags="--ozone-platform-hint=auto --enable-features=VaapiVideoDecodeLinuxGL --enable-gpu-rasterization"

    local temp_desktop
    temp_desktop=$(mktemp /tmp/google-chrome-desktop-XXXXXX)

    # Copiar lanzador del sistema y añadir flags a todas las directivas Exec=
    sed -E \
        -e "s|^Exec=/usr/bin/google-chrome-stable %U|Exec=/usr/bin/google-chrome-stable ${wayland_flags} %U|g" \
        -e "s|^Exec=/usr/bin/google-chrome-stable$|Exec=/usr/bin/google-chrome-stable ${wayland_flags}|g" \
        -e "s|^Exec=/usr/bin/google-chrome-stable --incognito|Exec=/usr/bin/google-chrome-stable ${wayland_flags} --incognito|g" \
        "$SYSTEM_DESKTOP" > "$temp_desktop"

    if [ "$EUID" -eq 0 ] && [ "$REAL_USER" != "root" ]; then
        install -o "$REAL_USER" -g "$(id -gn "$REAL_USER")" -m 644 "$temp_desktop" "$USER_DESKTOP_FILE"
    else
        install -m 644 "$temp_desktop" "$USER_DESKTOP_FILE"
    fi
    rm -f "$temp_desktop"

    # Actualizar bases de datos de escritorio y caché de KDE Plasma 6
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$USER_DESKTOP_DIR" 2>/dev/null || true
    fi
    if command -v kbuildsycoca6 &>/dev/null; then
        if [ "$EUID" -eq 0 ] && [ "$REAL_USER" != "root" ]; then
            su - "$REAL_USER" -c "kbuildsycoca6 --noincremental 2>/dev/null || true"
        else
            kbuildsycoca6 --noincremental 2>/dev/null || true
        fi
    fi

    echo -e "${GREEN}✔${NC} Lanzador optimizado configurado en: $USER_DESKTOP_FILE"
}

restore_desktop_launcher() {
    if [ -f "$USER_DESKTOP_FILE" ]; then
        echo -e "${BLUE}🔄 Restaurando lanzador de escritorio por defecto del sistema...${NC}"
        rm -f "$USER_DESKTOP_FILE"
        if command -v update-desktop-database &>/dev/null; then
            update-desktop-database "$USER_DESKTOP_DIR" 2>/dev/null || true
        fi
        if command -v kbuildsycoca6 &>/dev/null; then
            kbuildsycoca6 --noincremental 2>/dev/null || true
        fi
        echo -e "${GREEN}✔${NC} Lanzador de usuario eliminado. Se usará el lanzador estándar del sistema ($SYSTEM_DESKTOP)."
    else
        echo -e "${GREEN}✔${NC} No hay lanzador personalizado de usuario activo."
    fi
}

uninstall_chrome() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🗑️ DESINSTALACIÓN DE GOOGLE CHROME${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    require_root
    restore_desktop_launcher

    if is_chrome_installed; then
        echo -e "${BLUE}📦 Eliminando paquete $PACKAGE_NAME vía Zypper...${NC}"
        $SUDO zypper --non-interactive remove -y "$PACKAGE_NAME"
        echo -e "${GREEN}✔${NC} Google Chrome desinstalado del sistema."
    else
        echo -e "${YELLOW}ℹ️ El paquete $PACKAGE_NAME no está instalado.${NC}"
    fi

    if is_repo_configured; then
        echo -e "${BLUE}📦 Eliminando repositorio oficial de Zypper...${NC}"
        $SUDO zypper --non-interactive removerepo "$REPO_ALIAS" 2>/dev/null || true
        echo -e "${GREEN}✔${NC} Repositorio '$REPO_ALIAS' eliminado."
    fi

    echo -e "${GREEN}✅ Proceso de desinstalación completado.${NC}"
}

show_final_summary() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${GREEN}✅ Google Chrome configurado y listo para usar.${NC}"
    echo -e "   - Binario:     $(command -v google-chrome-stable 2>/dev/null || command -v google-chrome || echo 'google-chrome')"
    echo -e "   - Versión:     $(get_chrome_version)"
    echo -e "   - Repositorio: $REPO_ALIAS ($REPO_URL)"
    if is_wayland_optimized; then
        echo -e "   - Modo Wayland: ${GREEN}Nativo (Ozone Auto + VA-API AMD Radeon Vega)${NC}"
    else
        echo -e "   - Modo Wayland: Estándar"
    fi
    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 7. PARSER DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    --wayland|-w|wayland)
        if ! is_chrome_installed; then
            echo -e "${YELLOW}⚠️ Aviso:${NC} Google Chrome no está instalado aún. Instalando primero..."
            install_chrome "false"
        else
            optimize_wayland_launcher
        fi
        exit 0
        ;;
    --restore-desktop)
        restore_desktop_launcher
        exit 0
        ;;
    --update|-u|update)
        update_chrome
        exit 0
        ;;
    --uninstall|-r|remove|uninstall)
        uninstall_chrome
        exit 0
        ;;
    --install|-i|install)
        install_chrome "true"
        exit 0
        ;;
    "")
        install_chrome "false"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opción desconocida:${NC} ${1}"
        echo "Ejecuta '$0 --help' para ver las opciones disponibles."
        exit 1
        ;;
esac
