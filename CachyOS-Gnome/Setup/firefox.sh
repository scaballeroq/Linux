#!/usr/bin/env bash
# ==============================================================================
# firefox.sh - Instalación y Optimización de Mozilla Firefox Nativo en Wayland
# Sistema: CachyOS / Arch Linux (Pacman + Mesa VA-API + Policies JSON)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / VA-API)
# ==============================================================================
# Características:
#   - Instalación del paquete nativo Firefox desde repositorios oficiales de CachyOS / Arch.
#   - Paquete de idioma en español (firefox-i18n-es-es).
#   - Decodificación por hardware nativa VA-API (libva-mesa-driver, ffmpeg).
#   - Aceleración por hardware VA-API (Mesa radeonsi) y WebRender GPU activo.
#   - Políticas empresariales (/etc/firefox/policies/policies.json) para privacidad y Wayland.
#   - Variables de entorno de sesión (~/.config/environment.d/90-firefox-wayland.conf).
#   - Opciones CLI: --status / -s, --install / -i, --update / -u, --wayland / -w,
#                   --uninstall, --help / -h.
# ==============================================================================

set -euo pipefail

BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible. Ejecuta este script con privilegios de superusuario.${NC}" >&2
        exit 1
    fi
    SUDO="sudo"
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

POLICIES_DIR="/etc/firefox/policies"
POLICIES_FILE="$POLICIES_DIR/policies.json"
ENV_FILE="$USER_HOME/.config/environment.d/90-firefox-wayland.conf"

show_help() {
    cat << EOF
${BOLD}🦊 Instalador y Optimizador de Mozilla Firefox - CachyOS Workstation (GNOME Wayland)${NC}

Instala Firefox nativo mediante Pacman junto con el soporte de decodificación por
hardware VA-API (${BOLD}ffmpeg${NC}, ${BOLD}libva-mesa-driver${NC}, ${BOLD}libva-utils${NC}),
y despliega políticas empresariales (${BOLD}/etc/firefox/policies/policies.json${NC}) para
activar aceleración GPU en Wayland, XDG Portals y desactivar telemetría.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)   Instala Firefox, códecs y aplica optimización Wayland/VA-API
  -i, --install      Instala Firefox, paquetes de idioma y códecs VA-API
  -u, --update       Actualiza Firefox y complementos mediante Pacman
  -w, --wayland      Aplica solo políticas de aceleración VA-API y variables Wayland
  --uninstall        Desinstala Firefox y limpia políticas personalizadas
  -s, --status       Muestra el estado de Firefox, VA-API y políticas
  -h, --help         Muestra esta ayuda
EOF
}

is_pkg_installed() {
    pacman -Q "$1" &>/dev/null
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🦊 ${BOLD}ESTADO DE MOZILLA FIREFOX - CACHYOS WORKSTATION (WAYLAND)${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if command -v firefox &>/dev/null; then
        echo -e "  • Binario Firefox:           ${GREEN}$(firefox --version 2>/dev/null || echo 'Instalado')${NC}"
    else
        echo -e "  • Binario Firefox:           ${RED}No instalado${NC}"
    fi

    for pkg in firefox firefox-i18n-es-es ffmpeg libva-mesa-driver libva-utils; do
        if is_pkg_installed "$pkg"; then
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
    $SUDO mkdir -p "$POLICIES_DIR"
    $SUDO tee "$POLICIES_FILE" > /dev/null << 'EOF'
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
# Forzar protocolo nativo Wayland para Mozilla Firefox en CachyOS Workstation
MOZ_ENABLE_WAYLAND=1
EOF

    if [ "$EUID" -eq 0 ] && [ "$REAL_USER" != "root" ]; then
        chown -R "$REAL_USER:$REAL_USER" "$(dirname "$ENV_FILE")"
    fi
    log_ok "Políticas de aceleración VA-API y entorno Wayland configurados para Firefox."
}

install_firefox() {
    log_info "Instalando Firefox nativo, idioma español y drivers VA-API desde repositorios de CachyOS..."
    local pkgs=(
        firefox
        firefox-i18n-es-es
        ffmpeg
        libva-mesa-driver
        mesa-vdpau
        libva-utils
    )
    $SUDO pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || true
    configure_wayland_policies
    log_ok "Mozilla Firefox instalado y optimizado."
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
        log_info "Actualizando Firefox mediante Pacman..."
        $SUDO pacman -S --needed --noconfirm firefox firefox-i18n-es-es
        log_ok "Firefox actualizado."
        ;;
    wayland)
        configure_wayland_policies
        ;;
    uninstall)
        log_warn "Desinstalando Firefox y eliminando políticas personalizadas..."
        $SUDO pacman -Rns --noconfirm firefox 2>/dev/null || true
        $SUDO rm -f "$POLICIES_FILE"
        rm -f "$ENV_FILE"
        log_ok "Firefox desinstalado."
        ;;
esac
