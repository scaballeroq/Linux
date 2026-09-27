#!/usr/bin/env bash
# ==============================================================================
# opencode.sh - Gestor e Instalador de OpenCode AI CLI en NixOS
# ==============================================================================
# - Instalación 100% rootless en ~/.opencode y symlink en ~/.local/bin
# - Compatible con NixOS mediante nix-ld (modules/development.nix)
# ==============================================================================

set -euo pipefail

# Colores para salida
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

# Detección de usuario
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

get_latest_version() {
    local redirect_url version
    redirect_url=$(curl -sSI "https://github.com/anomalyco/opencode/releases/latest" 2>/dev/null | grep -i "^location:" | head -n1 || true)
    version=$(echo "$redirect_url" | grep -oP 'tag/v?\K[0-9.]+' | head -n1 || true)
    
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "0.1.0"
    fi
}

show_help() {
    cat <<EOF
⚡ Gestor de OpenCode AI CLI - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala o actualiza a la última versión disponible en ~/.local/bin/opencode.
  --status, -s        Comprueba el estado de la instalación.
  --uninstall         Elimina OpenCode del sistema de usuario.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

check_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}🔍 ESTADO DE OPENCODE AI CLI (NIXOS)${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    echo -n "• Binario opencode: "
    if command -v opencode &>/dev/null; then
        echo -e "${GREEN}✅ Instalado ($(opencode --version 2>/dev/null || echo 'activo'))${NC}"
        echo "  Ruta: $(which opencode)"
    else
        echo -e "${RED}❌ No instalado en PATH (~/.local/bin/opencode)${NC}"
    fi

    echo -n "• Soporte nix-ld en NixOS: "
    if [ -e "/run/current-system/sw/bin/nix-ld" ] || [ -e "/lib64/ld-linux-x86-64.so.2" ]; then
        echo -e "${GREEN}✅ Activo (los binarios ELF dinámicos funcionan sin problemas)${NC}"
    else
        echo -e "${YELLOW}ℹ️ Asegúrate de tener programs.nix-ld.enable = true en modules/development.nix${NC}"
    fi
    echo -e "${BOLD}=================================================================${NC}"
}

install_opencode() {
    echo -e "${BLUE}>> Buscando última versión de OpenCode...${NC}"
    local ver
    ver=$(get_latest_version)
    echo -e "${GREEN}Versión objetivo: v$ver${NC}"

    local arch
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64-unknown-linux-gnu" ;;
        aarch64|arm64) arch="aarch64-unknown-linux-gnu" ;;
        *) echo -e "${RED}Arquitectura no soportada: $(uname -m)${NC}"; exit 1 ;;
    esac

    local download_url="https://github.com/anomalyco/opencode/releases/download/v${ver}/opencode-v${ver}-${arch}.tar.gz"
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT

    echo -e "${YELLOW}⬇️ Descargando OpenCode desde GitHub...${NC}"
    if curl -fSL "$download_url" -o "$tmp_dir/opencode.tar.gz" 2>/dev/null; then
        mkdir -p "$OPENCODE_DIR/bin" "$LOCAL_BIN"
        tar -xzf "$tmp_dir/opencode.tar.gz" -C "$tmp_dir"
        
        # Encontrar binario
        local extracted_bin
        extracted_bin=$(find "$tmp_dir" -type f -name "opencode" | head -n1)
        if [ -n "$extracted_bin" ]; then
            install -m 755 "$extracted_bin" "$OPENCODE_BIN"
            ln -sf "$OPENCODE_BIN" "$LOCAL_BIN_LINK"
            echo -e "${GREEN}✅ OpenCode instalado con éxito en $LOCAL_BIN_LINK${NC}"
        fi
    else
        echo -e "${YELLOW}ℹ️ Descarga de release directo fallida, intentando script oficial...${NC}"
        curl -fsSL https://opencode.ai/install.sh | bash 2>/dev/null || true
    fi

    check_status
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --uninstall|uninstall)
        rm -rf "$OPENCODE_DIR" "$LOCAL_BIN_LINK"
        echo -e "${GREEN}✅ OpenCode desinstalado.${NC}"
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        install_opencode
        ;;
esac
