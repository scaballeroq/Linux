#!/usr/bin/env bash
# ==============================================================================
# firefox.sh - Instalación, Optimización y Diagnóstico de Mozilla Firefox Nativo
# Sistema: Debian GNU/Linux 13 (Trixie) | Escritorio: GNOME Shell (Wayland)
# Hardware: AMD Ryzen 7 7730U / Radeon Graphics (Vega 8 Barcelo-R) (VA-API)
# ==============================================================================
# Características:
#   - Instalación del paquete nativo (.deb) desde el repositorio oficial de Mozilla APT.
#   - Gestión idempotente de clave GPG moderna (/etc/apt/keyrings/packages.mozilla.org.asc).
#   - Pinning prioritario en APT (/etc/apt/preferences.d/mozilla) para evitar colisiones con ESR.
#   - Sustitución limpia de Firefox ESR y versiones residuales de Snap.
#   - Paquete de idioma español oficial (firefox-l10n-es-es).
#   - Aceleración por hardware VA-API (Mesa radeonsi) y portales nativos GNOME Wayland.
#   - Políticas empresariales de sistema (/etc/firefox/policies/policies.json).
#   - Opciones CLI: --status / -s, --install / -i, --update / -u, --wayland / -w,
#                   --uninstall / -r, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
KEYRING_URL="https://packages.mozilla.org/apt/repo-signing-key.gpg"
KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="$KEYRING_DIR/packages.mozilla.org.asc"
SOURCES_FILE="/etc/apt/sources.list.d/mozilla.list"
PREFERENCES_FILE="/etc/apt/preferences.d/mozilla"
POLICIES_DIR="/etc/firefox/policies"
POLICIES_FILE="$POLICIES_DIR/policies.json"
PACKAGE_NAME="firefox"
L10N_PACKAGE="firefox-l10n-es-es"

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

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

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

run_as_user() {
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$REAL_UID}"
    local dbus_addr="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$runtime_dir/bus}"
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="/usr/local/bin:/usr/bin:/bin:$PATH" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    else
        env \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    fi
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}🌐 Gestor y Optimizador de Mozilla Firefox - Debian 13 Workstation${NC}

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Instala Firefox oficial desde Mozilla, configura repositorios,
                      aplica aceleración VA-API Wayland e idioma español.
  -s, --status        Muestra diagnóstico detallado del repositorio, paquete, Wayland y VA-API.
  -i, --install       Fuerza la configuración del repositorio e instalación del navegador.
  -u, --update        Actualiza Firefox y su localización desde el repositorio oficial de Mozilla.
  -w, --wayland       Aplica políticas de aceleración por GPU (VA-API Radeon) y portales XDG GNOME.
  -r, --uninstall     Desinstala Firefox del sistema respetando los perfiles de usuario.
  -h, --help          Muestra este mensaje de ayuda.

${BOLD}Ajustes incluidos en Debian 13 (Trixie / GNOME Shell Wayland):${NC}
  • Repositorio APT:  packages.mozilla.org firmado con clave asc oficial de Mozilla.
  • Pinning APT:      Prioridad 1000 para garantizar versiones Rapid Release nativas sobre ESR.
  • Idioma:           Localización oficial en español (España) instalada e integrada.
  • Wayland nativo:   Integración de portales XDG para selector de archivos nativo de GNOME.
  • Aceleración HW:   VA-API habilitado para GPU AMD Radeon Vega 8 (decodificación 4K fluida)."
}

is_firefox_installed() {
    dpkg -s "$PACKAGE_NAME" &>/dev/null
}

get_firefox_version() {
    if is_firefox_installed; then
        dpkg -s "$PACKAGE_NAME" 2>/dev/null | grep -i "^Version:" | awk '{print $2}'
    elif command -v firefox &>/dev/null; then
        firefox --version 2>/dev/null | awk '{print $NF}' || echo "Desconocida"
    else
        echo "No instalado"
    fi
}

get_firefox_origin() {
    if is_firefox_installed; then
        apt-cache policy "$PACKAGE_NAME" 2>/dev/null | grep -A 1 "\*\*\*" | tail -n 1 | awk '{print $2, $3}' || echo "APT local"
    else
        echo "n/a"
    fi
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE MOZILLA FIREFOX - DEBIAN WORKSTATION (WAYLAND)${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    # 1. Repositorio Oficial
    if [ -f "$SOURCES_FILE" ]; then
        echo -e "• ${BOLD}Repositorio Mozilla APT:${NC}  ${GREEN}✅ Configurado ($SOURCES_FILE)${NC}"
    else
        echo -e "• ${BOLD}Repositorio Mozilla APT:${NC}  ${RED}❌ No configurado${NC}"
    fi

    # 2. Clave GPG
    if [ -f "$KEYRING_FILE" ]; then
        echo -e "• ${BOLD}Clave GPG Mozilla:${NC}        ${GREEN}✅ Presente en $KEYRING_FILE${NC}"
    else
        echo -e "• ${BOLD}Clave GPG Mozilla:${NC}        ${RED}❌ No encontrada${NC}"
    fi

    # 3. Pinning APT
    if [ -f "$PREFERENCES_FILE" ]; then
        local pin_prio
        pin_prio=$(grep -i "^Pin-Priority:" "$PREFERENCES_FILE" 2>/dev/null | awk '{print $2}' || echo "n/a")
        echo -e "• ${BOLD}Prioridad APT (Pinning):${NC}  ${GREEN}✅ Activa (Prioridad: $pin_prio)${NC}"
    else
        echo -e "• ${BOLD}Prioridad APT (Pinning):${NC}  ${YELLOW}⚠️ No configurada${NC}"
    fi

    # 4. Paquete Firefox
    local ff_ver ff_orig
    ff_ver=$(get_firefox_version)
    ff_orig=$(get_firefox_origin)
    if is_firefox_installed; then
        echo -e "• ${BOLD}Paquete Firefox:${NC}          ${GREEN}✅ Instalado (v${ff_ver})${NC}"
        echo -e "  - Origen del paquete:     $ff_orig"
    else
        echo -e "• ${BOLD}Paquete Firefox:${NC}          ${RED}❌ No instalado${NC}"
    fi

    # 5. Idioma Español
    if dpkg -s "$L10N_PACKAGE" &>/dev/null; then
        echo -e "• ${BOLD}Localización Español:${NC}     ${GREEN}✅ Instalada ($L10N_PACKAGE)${NC}"
    else
        echo -e "• ${BOLD}Localización Español:${NC}     ${YELLOW}⚠️ No instalada${NC}"
    fi

    # 6. Firefox ESR
    if dpkg -s firefox-esr &>/dev/null; then
        local esr_v
        esr_v=$(dpkg -s firefox-esr 2>/dev/null | grep -i "^Version:" | awk '{print $2}')
        echo -e "• ${BOLD}Firefox ESR:${NC}              ${YELLOW}⚠️ Presente en el sistema (v$esr_v)${NC}"
    else
        echo -e "• ${BOLD}Firefox ESR:${NC}              ${GREEN}✅ No presente (limpio)${NC}"
    fi

    # 7. Políticas de Aceleración y Wayland
    if [ -f "$POLICIES_FILE" ] && grep -qi "media.ffmpeg.vaapi.enabled" "$POLICIES_FILE" 2>/dev/null; then
        echo -e "• ${BOLD}Aceleración VA-API / GPU:${NC} ${GREEN}✅ Activa en $POLICIES_FILE${NC}"
    else
        echo -e "• ${BOLD}Aceleración VA-API / GPU:${NC} ${YELLOW}ℹ️ Predeterminada (ejecuta '$0 --wayland')${NC}"
    fi

    # 8. Variable MOZ_ENABLE_WAYLAND
    if [ -f "$USER_HOME/.config/environment.d/90-debian-multimedia.conf" ] && grep -q "MOZ_ENABLE_WAYLAND=1" "$USER_HOME/.config/environment.d/90-debian-multimedia.conf" 2>/dev/null; then
        echo -e "• ${BOLD}Entorno Wayland:${NC}          ${GREEN}✅ Configurado (MOZ_ENABLE_WAYLAND=1)${NC}"
    else
        echo -e "• ${BOLD}Entorno Wayland:${NC}          ${GREEN}✅ Nativo Wayland en Firefox moderno${NC}"
    fi

    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. CONFIGURACIÓN DEL REPOSITORIO Y PINNING DE MOZILLA
# ------------------------------------------------------------------------------
setup_repo() {
    require_root
    echo -e "${BLUE}ℹ️ [1/4] Configurando repositorio oficial APT de Mozilla...${NC}"

    # 1. Asegurar directorio de llaveros seguros
    $SUDO mkdir -p "$KEYRING_DIR"
    $SUDO chmod 755 "$KEYRING_DIR"

    # 2. Descargar e instalar la clave pública firmada por Mozilla
    echo -e "  - Instalando clave de firma oficial de Mozilla..."
    if command -v curl &>/dev/null; then
        curl -fsSL "$KEYRING_URL" | $SUDO tee "$KEYRING_FILE" > /dev/null
    else
        wget -qO- "$KEYRING_URL" | $SUDO tee "$KEYRING_FILE" > /dev/null
    fi
    $SUDO chmod 644 "$KEYRING_FILE"

    # 3. Configurar el archivo de orígenes APT de Mozilla
    echo -e "  - Configurando archivo de orígenes en $SOURCES_FILE..."
    echo "deb [signed-by=$KEYRING_FILE] https://packages.mozilla.org/apt mozilla main" | $SUDO tee "$SOURCES_FILE" > /dev/null
    $SUDO chmod 644 "$SOURCES_FILE"

    # 4. Configurar Pinning prioritario para preferir paquetes oficiales sobre Debian ESR
    echo -e "  - Configurando prioridad APT (Pin-Priority: 1000)..."
    $SUDO mkdir -p /etc/apt/preferences.d
    cat <<'EOF' | $SUDO tee "$PREFERENCES_FILE" > /dev/null
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
    $SUDO chmod 644 "$PREFERENCES_FILE"

    echo -e "${GREEN}  ✅ Repositorio oficial y prioridades de Mozilla configurados correctamente.${NC}"
}

# ------------------------------------------------------------------------------
# 5. LIMPIEZA DE VERSIONES PREVIAS (ESR / SNAP)
# ------------------------------------------------------------------------------
remove_legacy() {
    require_root
    echo -e "${BLUE}ℹ️ [2/4] Verificando y limpiando versiones redundantes de Firefox...${NC}"

    # Eliminar paquete Snap si existiera
    if command -v snap &>/dev/null && snap list firefox &>/dev/null; then
        echo -e "  - Eliminando Firefox Snap..."
        $SUDO snap remove firefox || true
    fi

    # Purgar Firefox ESR y sus paquetes de localización
    if dpkg -s firefox-esr &>/dev/null; then
        echo -e "  - Purgando Firefox ESR del sistema..."
        $SUDO env DEBIAN_FRONTEND=noninteractive apt-get purge -y \
            firefox-esr \
            firefox-esr-l10n-* 2>/dev/null || true
    fi

    echo -e "${GREEN}  ✅ Entorno limpio para Firefox nativo.${NC}"
}

# ------------------------------------------------------------------------------
# 6. ACELERACIÓN VA-API Y POLÍTICAS DE INTEGRACIÓN EN GNOME WAYLAND
# ------------------------------------------------------------------------------
setup_wayland_vaapi() {
    require_root
    echo -e "${BLUE}ℹ️ Optimizando Firefox para GNOME Wayland y aceleración VA-API (AMD Radeon Vega 8)...${NC}"

    # 1. Crear directorio de políticas de sistema de Firefox
    $SUDO mkdir -p "$POLICIES_DIR"

    # 2. Configurar Enterprise Policies para aceleración de hardware y portales Wayland
    cat <<'EOF' | $SUDO tee "$POLICIES_FILE" > /dev/null
{
  "policies": {
    "DisableAppUpdate": false,
    "Preferences": {
      "media.ffmpeg.vaapi.enabled": {
        "Value": true,
        "Status": "default"
      },
      "media.hardware-video-decoding.enabled": {
        "Value": true,
        "Status": "default"
      },
      "widget.use-xdg-desktop-portal.file-picker": {
        "Value": 1,
        "Status": "default"
      },
      "widget.use-xdg-desktop-portal.mime-handler": {
        "Value": 1,
        "Status": "default"
      },
      "browser.tabs.firefox-view": {
        "Value": false,
        "Status": "default"
      }
    }
  }
}
EOF
    $SUDO chmod 644 "$POLICIES_FILE"

    # 3. Asegurar variable MOZ_ENABLE_WAYLAND en variables de entorno del usuario
    local env_dir="$USER_HOME/.config/environment.d"
    run_as_user mkdir -p "$env_dir"
    if [ -f "$env_dir/90-debian-multimedia.conf" ]; then
        if ! grep -q "MOZ_ENABLE_WAYLAND=1" "$env_dir/90-debian-multimedia.conf"; then
            echo "MOZ_ENABLE_WAYLAND=1" | run_as_user tee -a "$env_dir/90-debian-multimedia.conf" > /dev/null
        fi
    else
        echo "MOZ_ENABLE_WAYLAND=1" | run_as_user tee "$env_dir/90-debian-multimedia.conf" > /dev/null
    fi

    echo -e "${GREEN}  ✅ Políticas de aceleración gráfica VA-API y Wayland aplicadas con éxito.${NC}"
}

# ------------------------------------------------------------------------------
# 7. INSTALACIÓN DE FIREFOX NATIVO
# ------------------------------------------------------------------------------
install_firefox() {
    require_root
    setup_repo
    remove_legacy

    echo -e "${BLUE}ℹ️ [3/4] Actualizando catálogo e instalando Firefox nativo (.deb)...${NC}"
    $SUDO apt-get update -qq

    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        "$PACKAGE_NAME" \
        "$L10N_PACKAGE"

    echo -e "${BLUE}ℹ️ [4/4] Aplicando optimizaciones de vídeo por hardware y Wayland...${NC}"
    setup_wayland_vaapi

    echo -e "${GREEN}✅ Mozilla Firefox nativo instalado y optimizado correctamente.${NC}"
}

# ------------------------------------------------------------------------------
# 8. ACTUALIZACIÓN DE FIREFOX
# ------------------------------------------------------------------------------
update_firefox() {
    require_root
    if ! [ -f "$SOURCES_FILE" ]; then
        echo -e "${YELLOW}⚠️ El repositorio oficial de Mozilla no está configurado. Configurándolo...${NC}"
        setup_repo
    fi

    echo -e "${BLUE}ℹ️ Buscando actualizaciones de Firefox en packages.mozilla.org...${NC}"
    $SUDO apt-get update -qq
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install --only-upgrade -y \
        "$PACKAGE_NAME" \
        "$L10N_PACKAGE" 2>/dev/null || true

    echo -e "${GREEN}✅ Proceso de actualización completado.${NC}"
}

# ------------------------------------------------------------------------------
# 9. DESINSTALACIÓN DE FIREFOX
# ------------------------------------------------------------------------------
uninstall_firefox() {
    require_root
    echo -e "${YELLOW}⚠️ Desinstalando Mozilla Firefox del sistema...${NC}"

    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get purge -y \
        "$PACKAGE_NAME" \
        "$L10N_PACKAGE" 2>/dev/null || true

    if [ -f "$POLICIES_FILE" ]; then
        $SUDO rm -f "$POLICIES_FILE"
    fi

    echo -e "${GREEN}✅ Firefox ha sido desinstalado. (Los datos de usuario en ~/.mozilla se conservan).${NC}"
}

# ------------------------------------------------------------------------------
# 10. ENTRADA PRINCIPAL
# ------------------------------------------------------------------------------
case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    -i|--install|install)
        install_firefox
        echo ""
        show_status
        exit 0
        ;;
    -u|--update|update)
        update_firefox
        echo ""
        show_status
        exit 0
        ;;
    -w|--wayland|wayland)
        setup_wayland_vaapi
        echo ""
        show_status
        exit 0
        ;;
    -r|--uninstall|uninstall)
        uninstall_firefox
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    "")
        echo -e "${CYAN}=================================================================${NC}"
        echo -e "${BOLD}🚀 INSTALANDO Y OPTIMIZANDO MOZILLA FIREFOX EN DEBIAN 13 (GNOME)${NC}"
        echo -e "${CYAN}=================================================================${NC}"
        install_firefox
        echo ""
        show_status
        echo -e "${CYAN}=================================================================${NC}"
        echo -e "${GREEN}✅ Instalación y configuración completada con éxito.${NC}"
        echo -e "${CYAN}=================================================================${NC}"
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida:${NC} $1"
        show_help
        exit 1
        ;;
esac
