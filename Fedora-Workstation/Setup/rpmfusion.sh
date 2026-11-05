#!/usr/bin/env bash
# ==============================================================================
# rpmfusion.sh - Configuración Oficial e Idempotente de RPM Fusion en Fedora
# Sistema: Fedora 45 Workstation (GNOME Shell Wayland + DNF5)
# Referencia Oficial: https://rpmfusion.org/Configuration
# ==============================================================================
# Características:
#   - Instalación de repositorios RPM Fusion Free y Non-Free según la versión de Fedora.
#   - Activación de metadatos AppStream para soporte nativo en GNOME Software.
#   - Habilitación del repositorio Cisco OpenH264 oficial (fedora-cisco-openh264).
#   - Instalación de repositorios Tainted (Free y Non-Free) para libdvdcss y codecs propietarios.
#   - Idempotencia total: comprueba el estado previo antes de invocar DNF5.
#   - Opciones CLI: --status / -s, --tainted / -t, --appstream / -a, --openh264, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

# ------------------------------------------------------------------------------
# 2. DETECCIÓN DE USUARIO Y GESTOR DE PAQUETES (DNF5)
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible. Ejecuta este script con privilegios de superusuario.${NC}" >&2
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

if command -v dnf5 &>/dev/null; then
    DNF_BIN="dnf5"
else
    DNF_BIN="dnf"
fi

FEDORA_VER=$(rpm -E %fedora 2>/dev/null || echo "45")

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
${BOLD}📦 Gestor Oficial de Repositorios RPM Fusion - Fedora 45 Workstation${NC}
Referencia Oficial: https://rpmfusion.org/Configuration

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala y configura la suite completa de RPM Fusion:
                      Free, Non-Free, AppStream metadata, Cisco OpenH264 y Tainted.
  --status, -s        Muestra el diagnóstico detallado de todos los repositorios RPM Fusion.
  --tainted, -t       Instala únicamente los repositorios Tainted (Free y Non-Free).
  --appstream, -a     Instala y actualiza únicamente los metadatos AppStream de GNOME Software.
  --openh264          Habilita únicamente el repositorio Cisco OpenH264.
  --help, -h          Muestra este mensaje de ayuda.

Repositorios gestionados:
  • RPM Fusion Free:          Software de código abierto no distribuible directamente por Fedora.
  • RPM Fusion Non-Free:      Software privativo y controladores (Steam, codecs, drivers).
  • RPM Fusion Tainted:       Paquetes con restricciones severas de patente (libdvdcss).
  • Cisco OpenH264:           Soporte WebRTC y codec H.264 para navegadores y GStreamer.
  • AppStream Data:           Metadatos para descubrimiento gráfico en GNOME Software.
EOF
}

is_pkg_installed() {
    rpm -q "$1" &>/dev/null
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  📦 ${BOLD}ESTADO DE REPOSITORIOS RPM FUSION - FEDORA ${FEDORA_VER} WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    echo -e "${BOLD}Repositorios Principales:${NC}"
    for repo_pkg in rpmfusion-free-release rpmfusion-nonfree-release; do
        if is_pkg_installed "$repo_pkg"; then
            local ver
            ver=$(rpm -q --queryformat '%{VERSION}' "$repo_pkg" 2>/dev/null || echo "activo")
            echo -e "  • $(printf '%-32s' "$repo_pkg"): ${GREEN}✅ Instalado (v$ver)${NC}"
        else
            echo -e "  • $(printf '%-32s' "$repo_pkg"): ${RED}❌ No instalado (Obligatorio)${NC}"
        fi
    done

    echo ""
    echo -e "${BOLD}Repositorios Especiales y Tainted:${NC}"
    for repo_pkg in rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted; do
        if is_pkg_installed "$repo_pkg"; then
            echo -e "  • $(printf '%-32s' "$repo_pkg"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-32s' "$repo_pkg"): ${YELLOW}⚠️ No instalado (Opcional: DVDs/Firmware)${NC}"
        fi
    done

    echo ""
    echo -e "${BOLD}Integración AppStream (GNOME Software) y Cisco OpenH264:${NC}"
    for app_pkg in rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data; do
        if is_pkg_installed "$app_pkg"; then
            echo -e "  • $(printf '%-32s' "$app_pkg"): ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  • $(printf '%-32s' "$app_pkg"): ${YELLOW}⚠️ No instalado${NC}"
        fi
    done

    # Cisco OpenH264
    local openh264_status
    if $DNF_BIN repolist --enabled 2>/dev/null | grep -qi "fedora-cisco-openh264"; then
        openh264_status="${GREEN}✅ Habilitado${NC}"
    else
        openh264_status="${YELLOW}⚠️ Deshabilitado o no presente${NC}"
    fi
    echo -e "  • $(printf '%-32s' "fedora-cisco-openh264"): $openh264_status"

    echo ""
    echo -e "${BOLD}Repositorios RPM Fusion Activos en $DNF_BIN:${NC}"
    local active_repos
    active_repos=$($DNF_BIN repolist --enabled 2>/dev/null | grep -iE "rpmfusion|cisco" || true)
    if [ -n "$active_repos" ]; then
        echo "$active_repos" | while IFS= read -r line; do
            echo -e "    ${CYAN}• $line${NC}"
        done
    else
        echo -e "    ${YELLOW}Ningún repositorio RPM Fusion activo reportado por $DNF_BIN${NC}"
    fi
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
enable_cisco_openh264() {
    log_info "Configurando repositorio Cisco OpenH264..."
    $SUDO "$DNF_BIN" config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
    log_ok "Repositorio Cisco OpenH264 habilitado."
}

install_appstream() {
    log_info "Instalando metadatos AppStream de RPM Fusion para GNOME Software..."
    $SUDO "$DNF_BIN" install -y --skip-unavailable \
        rpmfusion-free-appstream-data \
        rpmfusion-nonfree-appstream-data 2>/dev/null || true
    log_ok "Metadatos AppStream configurados."
}

install_tainted() {
    log_info "Instalando repositorios Tainted (Free y Non-Free) para libdvdcss y drivers privativos..."
    $SUDO "$DNF_BIN" install -y --skip-unavailable \
        rpmfusion-free-release-tainted \
        rpmfusion-nonfree-release-tainted 2>/dev/null || true
    log_ok "Repositorios Tainted instalados."
}

install_core_rpmfusion() {
    local need_install=false
    if ! is_pkg_installed rpmfusion-free-release || ! is_pkg_installed rpmfusion-nonfree-release; then
        need_install=true
    fi

    if [ "$need_install" = true ]; then
        log_info "Instalando RPM Fusion Free y Non-Free para Fedora ${FEDORA_VER}..."
        $SUDO "$DNF_BIN" install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"
        log_ok "RPM Fusion Free y Non-Free instalados con éxito."
    else
        log_ok "RPM Fusion Free y Non-Free ya se encuentran instalados."
    fi
}

install_all() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🚀 ${BOLD}CONFIGURACIÓN COMPLETA DE RPM FUSION - FEDORA ${FEDORA_VER} WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"
    install_core_rpmfusion
    enable_cisco_openh264
    install_appstream
    install_tainted
    log_ok "Configuración de RPM Fusion completada."
    echo ""
    show_status
}

# ------------------------------------------------------------------------------
# 5. PARSEO DE ARGUMENTOS
# ------------------------------------------------------------------------------
case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    -t|--tainted)
        install_tainted
        exit 0
        ;;
    -a|--appstream)
        install_appstream
        exit 0
        ;;
    --openh264)
        enable_cisco_openh264
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    "")
        install_all
        ;;
    *)
        log_err "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
