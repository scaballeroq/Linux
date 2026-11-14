#!/usr/bin/env bash
# ==============================================================================
# chrome.sh - Instalación, Optimización y Diagnóstico de Google Chrome
# Sistema: CachyOS / Arch Linux | Escritorio: GNOME Shell (Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / VA-API)
# ==============================================================================
# Características:
# - Despliegue prioritario desde repositorio [chaotic-aur] (paquete binario oficial google-chrome).
# - Configuración automática de repositorio Chaotic-AUR si no está presente en /etc/pacman.conf.
# - Alternativa nativa vía Paru (AUR) o Flatpak (Flathub) en caso de contingencia.
# - Configuración transparente de aceleración por GPU y Wayland nativo vía ~/.config/chrome-flags.conf.
# - Optimización para AMD Radeon Vega 8 (Ozone Wayland, VA-API Linux GL, GPU rasterization).
# - Diagnóstico integral del estado del navegador, paquete, flags y aceleración gráfica (--status).
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
PACKAGE_NAME="google-chrome"
FLATPAK_APP_ID="com.google.Chrome"

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

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

FLAGS_FILE="$USER_HOME/.config/chrome-flags.conf"
PACMAN_CONF="/etc/pacman.conf"

run_as_user() {
    if [ "$EUID" -eq 0 ] && [ "$REAL_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" USER="$REAL_USER" "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN Y CONFIGURACIÓN DE CHAOTIC-AUR
# ------------------------------------------------------------------------------
ensure_chaotic_aur() {
    if grep -q "^\[chaotic-aur\]" "$PACMAN_CONF" 2>/dev/null; then
        echo -e "${GREEN}✔ Repositorio [chaotic-aur] ya está activo en $PACMAN_CONF.${NC}"
        return 0
    fi

    echo -e "${BLUE}📦 Habilitando repositorio [chaotic-aur] para Google Chrome precompilado...${NC}"

    # Recibir llaves y mirrorlist
    $SUDO pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null || true
    $SUDO pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true

    if ! pacman -Q chaotic-keyring &>/dev/null; then
        $SUDO pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 2>/dev/null || true
    fi

    if ! pacman -Q chaotic-mirrorlist &>/dev/null; then
        $SUDO pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null || true
    fi

    if [ -f "/etc/pacman.d/chaotic-mirrorlist" ] && ! grep -q "^\[chaotic-aur\]" "$PACMAN_CONF"; then
        echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | $SUDO tee -a "$PACMAN_CONF" >/dev/null
        $SUDO pacman -Sy
        echo -e "${GREEN}✔ Repositorio [chaotic-aur] configurado y sincronizado.${NC}"
    fi
}

# ------------------------------------------------------------------------------
# 4. FUNCIONES DE DIAGNÓSTICO Y AYUDA
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}🌐 Instalador y Optimizador de Google Chrome - CachyOS (Chaotic-AUR / GNOME Wayland)${NC}

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)        Instala Google Chrome desde Chaotic-AUR y optimiza flags para Wayland y VA-API.
  -i, --install           Fuerza la instalación/revisión del paquete (Chaotic-AUR, Paru o Flatpak).
  -w, --wayland           Aplica la configuración de flags Wayland y aceleración GPU.
  -s, --status            Muestra diagnóstico detallado del paquete, Wayland y aceleración VA-API.
  -r, --uninstall         Desinstala Google Chrome del sistema.
  -h, --help              Muestra este mensaje de ayuda.

${BOLD}Ejemplos:${NC}
  $0                    # Instalación desde Chaotic-AUR y optimización
  $0 --status           # Comprueba estado y configuración"
}

is_chrome_installed() {
    pacman -Q "$PACKAGE_NAME" >/dev/null 2>&1 || \
    pacman -Q google-chrome-stable >/dev/null 2>&1 || \
    command -v google-chrome-stable >/dev/null 2>&1 || \
    command -v google-chrome >/dev/null 2>&1 || \
    flatpak info "$FLATPAK_APP_ID" >/dev/null 2>&1
}

get_chrome_version() {
    if pacman -Q "$PACKAGE_NAME" >/dev/null 2>&1; then
        pacman -Q "$PACKAGE_NAME" 2>/dev/null
    elif pacman -Q google-chrome-stable >/dev/null 2>&1; then
        pacman -Q google-chrome-stable 2>/dev/null
    elif command -v google-chrome-stable >/dev/null 2>&1; then
        google-chrome-stable --version 2>/dev/null || echo "Desconocida"
    elif flatpak info "$FLATPAK_APP_ID" >/dev/null 2>&1; then
        echo "Flatpak: $(flatpak info "$FLATPAK_APP_ID" | grep -i 'version:' | awk '{print $2}')"
    else
        echo "No instalado"
    fi
}

is_flags_configured() {
    [ -f "$FLAGS_FILE" ] && grep -q -- "--ozone-platform-hint=auto" "$FLAGS_FILE" 2>/dev/null
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🌐 ${BOLD}DIAGNÓSTICO DE GOOGLE CHROME - CACHYOS (GNOME WAYLAND)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    echo -n "• Estado de instalación:      "
    if is_chrome_installed; then
        echo -e "${GREEN}✔ Instalado [$(get_chrome_version)]${NC}"
    else
        echo -e "${RED}✘ No instalado${NC}"
    fi

    echo -n "• Repositorio Chaotic-AUR:    "
    if grep -q "^\[chaotic-aur\]" "$PACMAN_CONF" 2>/dev/null; then
        echo -e "${GREEN}✔ Activo (/etc/pacman.conf)${NC}"
    else
        echo -e "${YELLOW}✘ Inactivo o no configurado${NC}"
    fi

    echo -n "• Flags Wayland / VA-API:     "
    if is_flags_configured; then
        echo -e "${GREEN}✔ Configurado ($FLAGS_FILE)${NC}"
    else
        echo -e "${YELLOW}✘ No optimizado o archivo ausente${NC}"
    fi

    echo -n "• Acelerador VA-API (Mesa):   "
    if pacman -Q libva-mesa-driver >/dev/null 2>&1; then
        echo -e "${GREEN}✔ Presente (libva-mesa-driver)${NC}"
    else
        echo -e "${YELLOW}✘ Ausente (recomendado para decodificación por hardware)${NC}"
    fi

    echo -n "• Sesión Gráfica GNOME:       "
    echo -e "${CYAN}${XDG_SESSION_TYPE:-wayland}${NC}"
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 5. CONFIGURACIÓN Y OPTIMIZACIÓN
# ------------------------------------------------------------------------------
configure_flags() {
    echo -e "${BLUE}🎨 Configurando flags optimizados en $FLAGS_FILE...${NC}"
    run_as_user mkdir -p "$(dirname "$FLAGS_FILE")"

    cat << 'EOF' | run_as_user tee "$FLAGS_FILE" > /dev/null
# Google Chrome Flags - Optimizado para CachyOS GNOME Wayland
# Hardware: AMD Ryzen 7 7730U / AMD Radeon Vega 8 (VA-API / Vulkan)
--ozone-platform-hint=auto
--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoderLinuxGL,OverlayScrollbar
--enable-gpu-rasterization
--enable-zero-copy
--ignore-gpu-blocklist
EOF

    echo -e "${GREEN}✔ Flags de Wayland y aceleración gráfica aplicados con éxito.${NC}"
}

install_chrome() {
    local force="${1:-false}"

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🌐 INSTALACIÓN Y OPTIMIZACIÓN DE GOOGLE CHROME - CHAOTIC-AUR${NC}"
    echo -e "   ${CYAN}Sistema:${NC} CachyOS | GNOME Wayland | AMD Radeon Graphics"
    echo -e "${CYAN}=================================================================${NC}"

    if is_chrome_installed && [ "$force" != "true" ]; then
        echo -e "${GREEN}✔ Google Chrome ya está instalado ($(get_chrome_version)).${NC}"
        configure_flags
        return 0
    fi

    # 1. Asegurar repositorio Chaotic-AUR para descarga directa de binario precompilado
    ensure_chaotic_aur

    # 2. Intentar instalación directa vía Pacman desde Chaotic-AUR
    echo -e "${BLUE}⬇️ Instalando Google Chrome precompilado desde Chaotic-AUR vía Pacman...${NC}"
    if $SUDO pacman -S --needed --noconfirm "$PACKAGE_NAME" 2>/dev/null; then
        echo -e "${GREEN}✔ Paquete $PACKAGE_NAME instalado exitosamente desde Chaotic-AUR.${NC}"
    elif command -v paru &>/dev/null; then
        echo -e "${CYAN}ℹ️ Intentando instalación mediante Paru...${NC}"
        run_as_user paru -S --needed --noconfirm "$PACKAGE_NAME" || true
    fi

    # 3. Fallback a Flatpak si fallaron los métodos nativos
    if ! is_chrome_installed; then
        if command -v flatpak &>/dev/null; then
            echo -e "${YELLOW}⚠️ Paquete nativo no completado. Instalando vía Flatpak desde Flathub...${NC}"
            run_as_user flatpak install -y flathub "$FLATPAK_APP_ID"
        else
            echo -e "${RED}❌ No se pudo completar la instalación de Google Chrome.${NC}"
            exit 1
        fi
    fi

    # 4. Configurar flags Wayland y VA-API
    configure_flags
    echo -e "${GREEN}✅ Google Chrome instalado y optimizado con éxito.${NC}"
    show_status
}

uninstall_chrome() {
    echo -e "${YELLOW}⚠️ Desinstalando Google Chrome del sistema...${NC}"
    if pacman -Q "$PACKAGE_NAME" >/dev/null 2>&1; then
        $SUDO pacman -Rns --noconfirm "$PACKAGE_NAME" 2>/dev/null || true
    fi
    if flatpak info "$FLATPAK_APP_ID" >/dev/null 2>&1; then
        flatpak uninstall -y "$FLATPAK_APP_ID" 2>/dev/null || true
    fi
    run_as_user rm -f "$FLAGS_FILE"
    echo -e "${GREEN}✔ Google Chrome desinstalado exitosamente.${NC}"
}

# ------------------------------------------------------------------------------
# 6. ENTRADA PRINCIPAL
# ------------------------------------------------------------------------------
case "${1:-}" in
    -s|--status|status)
        show_status
        ;;
    -w|--wayland|wayland)
        configure_flags
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
