#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  firefox.sh - Instalación y Optimización de Mozilla Firefox Nativo en Wayland
#  Sistema: Fedora 45 Workstation (DNF5 + RPM Fusion VA-API + Policies JSON)
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

if [[ $EUID -eq 0 ]]; then
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
else
    REAL_USER="${USER:-$(whoami)}"
fi
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"

POLICIES_DIR="/etc/firefox/policies"
POLICIES_FILE="$POLICIES_DIR/policies.json"
ENV_FILE="$USER_HOME/.config/environment.d/90-firefox-wayland.conf"

show_help() {
    cat << EOF
${BOLD}🦊 Instalador y Optimizador de Mozilla Firefox - Fedora 45 Workstation (GNOME Wayland)${NC}

Instala Firefox nativo mediante DNF5 junto con el soporte de decodificación por
hardware VA-API de ${BOLD}RPM Fusion${NC} (${BOLD}ffmpeg${NC}, ${BOLD}mesa-va-drivers-freeworld${NC}, ${BOLD}mozilla-openh264${NC}),
y despliega políticas empresariales (${BOLD}/etc/firefox/policies/policies.json${NC}) para
activar aceleración GPU en Wayland, XDG Portals y desactivar telemetría.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)   Instala Firefox, códecs RPM Fusion y aplica optimización Wayland/VA-API
  -i, --install      Instala Firefox, paquetes de idioma y códecs VA-API
  -u, --update       Actualiza Firefox mediante DNF5
  -w, --wayland      Aplica solo políticas de aceleración VA-API y variables Wayland
  --uninstall        Desinstala Firefox y limpia políticas personalizadas
  -s, --status       Muestra el estado de Firefox, OpenH264, RPM Fusion VA-API y políticas
  -h, --help         Muestra esta ayuda
EOF
}

ensure_rpmfusion() {
    local fed_ver
    fed_ver=$(rpm -E %fedora)
    if ! rpm -q rpmfusion-free-release &>/dev/null || ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
        log_info "Instalando RPM Fusion Free & Non-Free (obligatorio para H.264/HEVC/VA-API en Firefox)..."
        sudo "$DNF_BIN" install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fed_ver}.noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fed_ver}.noarch.rpm"
    fi
    sudo "$DNF_BIN" config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🦊 ${BOLD}ESTADO DE MOZILLA FIREFOX - FEDORA 45 WORKSTATION (WAYLAND)${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if command -v firefox &>/dev/null; then
        echo -e "  • Binario Firefox:           ${GREEN}$(firefox --version 2>/dev/null || echo 'Instalado')${NC}"
    else
        echo -e "  • Binario Firefox:           ${RED}No instalado${NC}"
    fi

    for pkg in firefox-langpacks mozilla-openh264 ffmpeg mesa-va-drivers-freeworld; do
        if rpm -q "$pkg" &>/dev/null; then
            echo -e "  • $(printf '%-26s' "$pkg"): ${GREEN}Instalado${NC}"
        else
            echo -e "  • $(printf '%-26s' "$pkg"): ${YELLOW}No instalado${NC}"
        fi
    done

    [[ -f "$POLICIES_FILE" ]] && echo -e "  • Políticas VA-API/Wayland:  ${GREEN}${POLICIES_FILE}${NC}" || echo -e "  • Políticas VA-API/Wayland:  ${YELLOW}No aplicadas${NC}"
    [[ -f "$ENV_FILE" ]]      && echo -e "  • Entorno Wayland:           ${GREEN}${ENV_FILE}${NC}"      || echo -e "  • Entorno Wayland:           ${YELLOW}No configurado${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

configure_wayland_policies() {
    log_info "Configurando políticas de aceleración VA-API, WebRender y XDG Portals en $POLICIES_FILE..."
    sudo mkdir -p "$POLICIES_DIR"
    sudo tee "$POLICIES_FILE" > /dev/null << 'EOF'
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "DontCheckDefaultBrowser": true,
    "HardwareAcceleration": true,
    "Preferences": {
      "media.ffmpeg.vaapi.enabled": {
        "Value": true,
        "Status": "default"
      },
      "media.hardware-video-decoding.force-enabled": {
        "Value": true,
        "Status": "default"
      },
      "gfx.webrender.all": {
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
      }
    }
  }
}
EOF

    mkdir -p "$(dirname "$ENV_FILE")"
    cat << 'EOF' > "$ENV_FILE"
# Forzar protocolo nativo Wayland para Mozilla Firefox en Fedora 45 Workstation
MOZ_ENABLE_WAYLAND=1
EOF

    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        chown -R "$REAL_USER:$REAL_USER" "$(dirname "$ENV_FILE")"
    fi
    log_ok "Políticas de aceleración VA-API y entorno Wayland configurados para Firefox."
}

install_firefox() {
    ensure_rpmfusion
    log_info "Instalando Firefox nativo, langpacks, OpenH264 y drivers VA-API desde DNF5 / RPM Fusion..."
    sudo "$DNF_BIN" install -y --skip-unavailable firefox firefox-langpacks mozilla-openh264 gstreamer1-plugin-openh264 libva-utils
    sudo "$DNF_BIN" install -y --allowerasing ffmpeg ffmpeg-libs 2>/dev/null || true
    if lspci 2>/dev/null | grep -E "VGA|3D" | grep -qiE "AMD|ATI|Radeon"; then
        sudo "$DNF_BIN" swap -y mesa-va-drivers mesa-va-drivers-freeworld 2>/dev/null || \
            sudo "$DNF_BIN" install -y --allowerasing mesa-va-drivers-freeworld 2>/dev/null || true
    fi
    configure_wayland_policies
}

ACTION="all"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)    ACTION="status"; shift ;;
        -i|--install)   ACTION="install"; shift ;;
        -u|--update)    ACTION="update"; shift ;;
        -w|--wayland)   ACTION="wayland"; shift ;;
        --uninstall)    ACTION="uninstall"; shift ;;
        -h|--help)      show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

case "$ACTION" in
    status)  show_status ;;
    install|all)
        install_firefox
        show_status
        ;;
    update)
        log_info "Actualizando Firefox mediante $DNF_BIN..."
        sudo "$DNF_BIN" upgrade --refresh -y firefox firefox-langpacks mozilla-openh264
        log_ok "Firefox actualizado."
        ;;
    wayland)
        configure_wayland_policies
        ;;
    uninstall)
        log_warn "Desinstalando Firefox y eliminando políticas personalizadas..."
        sudo "$DNF_BIN" remove -y firefox
        sudo rm -f "$POLICIES_FILE"
        rm -f "$ENV_FILE"
        log_ok "Firefox desinstalado."
        ;;
esac
