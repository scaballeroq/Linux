#!/usr/bin/env bash
# ==============================================================================
# chrome.sh - Instalación, Optimización y Diagnóstico de Google Chrome
# Sistema: CachyOS (Arch Linux) | Escritorio: GNOME Shell (Wayland)
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD Graphics 4600)
# Pantalla: Sony TV (Plataformas de streaming: Netflix, Prime Video, RTVE, YouTube)
# ==============================================================================
# Características:
# - Soporte nativo para CachyOS / Arch Linux (Chaotic-AUR, paru, yay o pacman).
# - Optimización nativa para Wayland y aceleración por GPU VA-API (Intel Haswell i965).
# - Widevine DRM nativo para reproducción 1080p en Netflix, Prime Video, RTVE, Pluto TV.
# - Diagnóstico integral del estado del navegador, Wayland y aceleración gráfica.
# ==============================================================================

set -euo pipefail

# Colores ANSI para terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detección de usuario real
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

USER_DESKTOP_DIR="$USER_HOME/.local/share/applications"
USER_DESKTOP_FILE="$USER_DESKTOP_DIR/google-chrome.desktop"
SYSTEM_DESKTOP="/usr/share/applications/google-chrome.desktop"

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

detect_aur_helper() {
    if run_as_user command -v paru &>/dev/null; then
        echo "paru"
    elif run_as_user command -v yay &>/dev/null; then
        echo "yay"
    else
        echo ""
    fi
}

show_help() {
    echo -e "${BOLD}🌐 Instalador y Optimizador de Google Chrome - CachyOS (GNOME Wayland)${NC}

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)        Instala Google Chrome y optimiza el lanzador para Intel VA-API y Wayland.
  -i, --install           Instala Google Chrome (mediante paru, yay o pacman con Chaotic-AUR).
  -u, --update            Actualiza Google Chrome a la última versión disponible.
  -w, --wayland           Optimiza el lanzador de escritorio para GNOME Shell Wayland y aceleración VA-API (Intel HD 4600).
      --restore-desktop   Restaura el lanzador de escritorio original del sistema.
  -s, --status            Muestra diagnóstico detallado del paquete, Wayland y aceleración GPU.
  -r, --uninstall         Desinstala Google Chrome del sistema.
  -h, --help              Muestra este mensaje de ayuda."
}

is_chrome_installed() {
    if command -v google-chrome-stable &>/dev/null || command -v google-chrome &>/dev/null; then
        return 0
    elif pacman -Qq google-chrome &>/dev/null 2>&1; then
        return 0
    fi
    return 1
}

get_chrome_version() {
    if command -v google-chrome-stable &>/dev/null; then
        google-chrome-stable --version 2>/dev/null || echo "Instalado"
    elif command -v google-chrome &>/dev/null; then
        google-chrome --version 2>/dev/null || echo "Instalado"
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
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE GOOGLE CHROME - CACHYOS (GNOME WAYLAND / SONY TV)${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    local aur_h
    aur_h=$(detect_aur_helper)
    if [ -n "$aur_h" ]; then
        echo -e "• ${BOLD}AUR Helper:${NC}            ${GREEN}✅ $aur_h disponible${NC}"
    else
        echo -e "• ${BOLD}AUR Helper:${NC}            ${YELLOW}⚠️ No detectado (paru/yay)${NC}"
    fi

    local chrome_ver
    chrome_ver=$(get_chrome_version)
    if is_chrome_installed; then
        echo -e "• ${BOLD}Paquete Chrome:${NC}        ${GREEN}✅ $chrome_ver${NC}"
    else
        echo -e "• ${BOLD}Paquete Chrome:${NC}        ${RED}❌ No instalado${NC}"
    fi

    if is_wayland_optimized; then
        echo -e "• ${BOLD}Optimización Wayland:${NC}  ${GREEN}✅ Activa (--ozone-platform-hint=auto + VA-API Haswell)${NC}"
    else
        echo -e "• ${BOLD}Optimización Wayland:${NC}  ${YELLOW}ℹ️ Predeterminada (ejecuta '$0 --wayland')${NC}"
    fi

    if [ -f "/usr/lib/google-chrome/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so" ] || [ -f "/opt/google/chrome/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so" ]; then
        echo -e "• ${BOLD}Widevine DRM:${NC}          ${GREEN}✅ Presente (Soporte Netflix / Prime Video 1080p)${NC}"
    else
        echo -e "• ${BOLD}Widevine DRM:${NC}          ${CYAN}ℹ️ Incluido en el paquete nativo de Google Chrome${NC}"
    fi

    echo -e "${CYAN}=================================================================${NC}"
}

install_chrome() {
    if is_chrome_installed; then
        echo -e "${GREEN}✅ Google Chrome ya está instalado ($(get_chrome_version)).${NC}"
        return 0
    fi

    echo -e "${BLUE}⬇️ Instalando Google Chrome en CachyOS...${NC}"
    local aur_h
    aur_h=$(detect_aur_helper)

    if pacman -Si google-chrome &>/dev/null; then
        echo "Instalando google-chrome desde repositorios de CachyOS / Chaotic-AUR..."
        $SUDO pacman -S --needed --noconfirm google-chrome
    elif [ -n "$aur_h" ]; then
        echo "Instalando google-chrome mediante $aur_h..."
        run_as_user "$aur_h" -S --needed --noconfirm google-chrome
    elif command -v flatpak &>/dev/null; then
        echo -e "${YELLOW}⚠️ AUR helper no disponible. Instalando Google Chrome vía Flatpak como respaldo...${NC}"
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
        flatpak install -y flathub com.google.Chrome
    else
        echo -e "${RED}❌ Error: No se pudo instalar Google Chrome. Instala paru, yay o habilita Chaotic-AUR.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Google Chrome instalado exitosamente.${NC}"
}

update_chrome() {
    echo -e "${BLUE}🔄 Actualizando Google Chrome...${NC}"
    local aur_h
    aur_h=$(detect_aur_helper)

    if pacman -Qq google-chrome &>/dev/null; then
        $SUDO pacman -Sy --noconfirm google-chrome
    elif [ -n "$aur_h" ]; then
        run_as_user "$aur_h" -Sy --noconfirm google-chrome
    elif command -v flatpak &>/dev/null && flatpak list --app | grep -qi "com.google.Chrome"; then
        flatpak update -y com.google.Chrome
    fi
    echo -e "${GREEN}✅ Google Chrome actualizado.${NC}"
}

optimize_wayland() {
    echo -e "${BLUE}🚀 Optimizando lanzador para GNOME Shell Wayland y aceleración GPU (Intel HD 4600 / Haswell)...${NC}"
    
    local target_desktop=""
    if [ -f "$SYSTEM_DESKTOP" ]; then
        target_desktop="$SYSTEM_DESKTOP"
    elif [ -f "/usr/share/applications/google-chrome-stable.desktop" ]; then
        target_desktop="/usr/share/applications/google-chrome-stable.desktop"
    elif [ -f "/var/lib/flatpak/exports/share/applications/com.google.Chrome.desktop" ]; then
        target_desktop="/var/lib/flatpak/exports/share/applications/com.google.Chrome.desktop"
    fi

    if [ -z "$target_desktop" ]; then
        echo -e "${YELLOW}⚠️ Lanzador del sistema no encontrado aún. Creando lanzador optimizado en espacio de usuario...${NC}"
        mkdir -p "$USER_DESKTOP_DIR"
        cat << 'EOF' > "$USER_DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Name=Google Chrome
GenericName=Navegador web
Comment=Accede a Internet
Exec=/usr/bin/google-chrome-stable --ozone-platform-hint=auto --enable-features=VaapiVideoDecodeLinuxGL,VaapiIgnoreDriverChecks --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy %U
Terminal=false
Icon=google-chrome
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml_xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF
    else
        mkdir -p "$USER_DESKTOP_DIR"
        cp "$target_desktop" "$USER_DESKTOP_FILE"
        local wayland_flags="--ozone-platform-hint=auto --enable-features=VaapiVideoDecodeLinuxGL,VaapiIgnoreDriverChecks --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy"
        
        sed -i "s|^Exec=/usr/bin/google-chrome-stable %U|Exec=/usr/bin/google-chrome-stable $wayland_flags %U|" "$USER_DESKTOP_FILE" 2>/dev/null || true
        sed -i "s|^Exec=/usr/bin/google-chrome-stable$|Exec=/usr/bin/google-chrome-stable $wayland_flags|" "$USER_DESKTOP_FILE" 2>/dev/null || true
        sed -i "s|^Exec=/usr/bin/google-chrome %U|Exec=/usr/bin/google-chrome $wayland_flags %U|" "$USER_DESKTOP_FILE" 2>/dev/null || true
        sed -i "s|^Exec=/usr/bin/google-chrome$|Exec=/usr/bin/google-chrome $wayland_flags|" "$USER_DESKTOP_FILE" 2>/dev/null || true
    fi

    chmod 644 "$USER_DESKTOP_FILE" 2>/dev/null || true
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
    echo -e "${YELLOW}🗑️ Desinstalando Google Chrome...${NC}"
    local aur_h
    aur_h=$(detect_aur_helper)
    if pacman -Qq google-chrome &>/dev/null; then
        $SUDO pacman -Rns --noconfirm google-chrome || true
    elif [ -n "$aur_h" ]; then
        run_as_user "$aur_h" -Rns --noconfirm google-chrome || true
    elif command -v flatpak &>/dev/null && flatpak list --app | grep -qi "com.google.Chrome"; then
        flatpak uninstall -y com.google.Chrome || true
    fi
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
        optimize_wayland
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
