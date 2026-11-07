#!/usr/bin/env bash
# ==============================================================================
# tv-streaming.sh - Accesos Directos WebApp y Dock para Televisión (Sony TV)
# Sistema: Debian GNU/Linux (GNOME Shell Wayland)
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD Graphics 4600)
# ==============================================================================
# Características:
#   - Genera lanzadores .desktop en modo WebApp para:
#     Netflix, Prime Video, RTVE Play, Pluto TV, YouTube y Orange TV.
#   - Ejecuta en modo ventana limpia (--app=URL) mediante Google Chrome o Firefox
#     con aceleración por hardware VA-API (Intel Haswell i965) y soporte Widevine DRM.
#   - Configura la barra de favoritos (Dock) de GNOME Shell con la disposición
#     multimedia exacta: Kodi, Stremio, RTVE Play, Netflix, Prime Video, Pluto TV, YouTube, VLC.
#   - Soporte para CLI: --status / -s, --dock, --install, --help / -h.
# ==============================================================================

set -euo pipefail

# Colores ANSI
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

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="$USER_HOME/.local/share/applications"
ICONS_DIR="$USER_HOME/.local/share/icons/hicolor/scalable/apps"

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

detect_browser_cmd() {
    local base_flags="--ozone-platform-hint=auto --enable-features=VaapiVideoDecodeLinuxGL,VaapiIgnoreDriverChecks --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy"
    if command -v google-chrome-stable &>/dev/null; then
        echo "google-chrome-stable $base_flags --app"
    elif command -v google-chrome &>/dev/null; then
        echo "google-chrome $base_flags --app"
    elif command -v chromium &>/dev/null; then
        echo "chromium $base_flags --app"
    elif command -v firefox &>/dev/null; then
        echo "firefox --new-window"
    else
        echo "x-www-browser"
    fi
}

show_help() {
    cat <<EOF
📺 Gestor de Plataformas de Streaming y Dock TV - HP Z230 SFF (Sony TV)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala los iconos, lanzadores WebApp y configura el Dock de GNOME.
  --install, -i       Crea o actualiza los lanzadores WebApp e instala sus iconos SVG.
  --dock, -d          Organiza los iconos favoritos del Dock de GNOME Shell con las apps multimedia.
  --uninstall, -u     Elimina los lanzadores WebApp e iconos, y restablece el Dock a apps nativas.
  --status, -s        Comprueba el estado de los lanzadores WebApp, iconos, navegador y Flatpaks.
  --help, -h          Muestra este mensaje de ayuda.

Plataformas configuradas:
  • Netflix           (https://www.netflix.com)
  • Amazon Prime Video(https://www.primevideo.com)
  • RTVE Play         (https://www.rtve.es/play/)
  • Pluto TV          (https://pluto.tv)
  • YouTube           (https://www.youtube.com)
  • Orange TV         (https://orangetv.orange.es)
EOF
}

create_webapps() {
    echo -e "${BLUE}ℹ️ Instalando iconos vectoriales (SVG) y lanzadores WebApp para televisor...${NC}"
    mkdir -p "$APPS_DIR" "$ICONS_DIR"

    # Instalar iconos vectoriales desde Setup/icons
    if [ -d "$SCRIPT_DIR/icons" ]; then
        cp -f "$SCRIPT_DIR/icons"/*.svg "$ICONS_DIR/" 2>/dev/null || true
        gtk-update-icon-cache -f -t "$USER_HOME/.local/share/icons/hicolor" 2>/dev/null || true
        echo -e "${GREEN}✅ Iconos vectoriales de alta definición instalados en $ICONS_DIR.${NC}"
    fi

    local browser_launcher
    browser_launcher=$(detect_browser_cmd)

    # 1. Netflix
    cat <<EOF > "$APPS_DIR/netflix.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Netflix
GenericName=Plataforma de Streaming
Comment=Ver películas y series en streaming en Netflix
Exec=$browser_launcher=https://www.netflix.com
Icon=netflix
Terminal=false
Categories=AudioVideo;Video;Player;TV;
StartupNotify=true
StartupWMClass=netflix.com
EOF

    # 2. Prime Video
    cat <<EOF > "$APPS_DIR/prime-video.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Prime Video
GenericName=Plataforma de Streaming
Comment=Ver películas y series en Amazon Prime Video
Exec=$browser_launcher=https://www.primevideo.com
Icon=prime-video
Terminal=false
Categories=AudioVideo;Video;Player;TV;
StartupNotify=true
StartupWMClass=primevideo.com
EOF

    # 3. RTVE Play
    cat <<EOF > "$APPS_DIR/rtve-play.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=RTVE Play
GenericName=Televisión a la carta
Comment=Contenido y canales en directo de RTVE
Exec=$browser_launcher=https://www.rtve.es/play/
Icon=rtve-play
Terminal=false
Categories=AudioVideo;Video;Player;TV;
StartupNotify=true
StartupWMClass=rtve.es
EOF

    # 4. Pluto TV
    cat <<EOF > "$APPS_DIR/pluto-tv.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Pluto TV
GenericName=Televisión por Internet
Comment=Canales gratuitos en directo y bajo demanda en Pluto TV
Exec=$browser_launcher=https://pluto.tv
Icon=pluto-tv
Terminal=false
Categories=AudioVideo;Video;Player;TV;
StartupNotify=true
StartupWMClass=pluto.tv
EOF

    # 5. YouTube
    cat <<EOF > "$APPS_DIR/youtube.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=YouTube
GenericName=Plataforma de Vídeo
Comment=Ver y reproducir vídeos en YouTube
Exec=$browser_launcher=https://www.youtube.com
Icon=youtube
Terminal=false
Categories=AudioVideo;Video;Player;TV;
StartupNotify=true
StartupWMClass=youtube.com
EOF

    # 6. Orange TV
    cat <<EOF > "$APPS_DIR/orange-tv.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Orange TV
GenericName=Televisión Online
Comment=Acceso a contenidos y canales de Orange TV
Exec=$browser_launcher=https://orangetv.orange.es
Icon=orange-tv
Terminal=false
Categories=AudioVideo;Video;Player;TV;
StartupNotify=true
StartupWMClass=orangetv.orange.es
EOF

    chmod +x "$APPS_DIR"/*.desktop 2>/dev/null || true
    update-desktop-database "$APPS_DIR" 2>/dev/null || true
    echo -e "${GREEN}✅ Lanzadores WebApp creados en $APPS_DIR.${NC}"
}

uninstall_webapps() {
    echo -e "${YELLOW}🗑️ Eliminando lanzadores WebApp e iconos personalizados...${NC}"
    
    local apps=("netflix" "prime-video" "rtve-play" "pluto-tv" "youtube" "orange-tv")
    for app in "${apps[@]}"; do
        rm -f "$APPS_DIR/$app.desktop"
        rm -f "$ICONS_DIR/$app.svg"
    done

    update-desktop-database "$APPS_DIR" 2>/dev/null || true
    gtk-update-icon-cache -f -t "$USER_HOME/.local/share/icons/hicolor" 2>/dev/null || true

    echo -e "${BLUE}ℹ️ Restableciendo barra de favoritos de GNOME Shell sin las WebApps...${NC}"
    local default_dock="['tv.kodi.Kodi.desktop', 'com.stremio.Stremio.desktop', 'org.videolan.VLC.desktop', 'google-chrome.desktop', 'kitty.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Settings.desktop']"
    run_as_user gsettings set org.gnome.shell favorite-apps "$default_dock" 2>/dev/null || true

    echo -e "${GREEN}✅ WebApps e iconos eliminados. Dock de GNOME restablecido.${NC}"
    echo -e "${CYAN}💡 Ahora puedes instalar tus WebApps manualmente desde Google Chrome con 'Instalar' o 'Crear acceso directo...'.${NC}"
}

setup_dock_favorites() {
    echo -e "${BLUE}ℹ️ Organizando barra de aplicaciones favoritas (Dock GNOME) para TV...${NC}"
    
    # Lista de aplicaciones favoritas en orden exacto para televisor
    local favorites_list="['tv.kodi.Kodi.desktop', 'com.stremio.Stremio.desktop', 'rtve-play.desktop', 'netflix.desktop', 'orange-tv.desktop', 'prime-video.desktop', 'pluto-tv.desktop', 'youtube.desktop', 'org.videolan.VLC.desktop', 'google-chrome.desktop', 'kitty.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Settings.desktop']"

    run_as_user gsettings set org.gnome.shell favorite-apps "$favorites_list" 2>/dev/null || true
    echo -e "${GREEN}✅ Dock de GNOME Shell configurado con las aplicaciones multimedia principales.${NC}"
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 ESTADO DE PLATAFORMAS MULTIMEDIA Y DOCK TV (HP Z230 SFF)${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "• Hardware:           HP Z230 SFF (Intel Core i7-4790 / Intel HD 4600)"
    echo -e "• Pantalla:           Sony TV"
    echo -e "• Navegador base:     $(detect_browser_cmd)"
    echo -e "-----------------------------------------------------------------"
    echo -e "• Aplicaciones Multimedia Flatpak:"
    for app in "tv.kodi.Kodi" "com.stremio.Stremio" "org.videolan.VLC"; do
        if flatpak list --app 2>/dev/null | grep -qi "$app"; then
            echo -e "  - $app: ${GREEN}✅ Instalado en Flatpak${NC}"
        else
            echo -e "  - $app: ${RED}❌ No instalado${NC}"
        fi
    done
    echo -e "-----------------------------------------------------------------"
    echo -e "• Lanzadores WebApp en ~/.local/share/applications/:"
    for desktop in "netflix.desktop" "prime-video.desktop" "rtve-play.desktop" "pluto-tv.desktop" "youtube.desktop" "orange-tv.desktop"; do
        if [ -f "$APPS_DIR/$desktop" ]; then
            echo -e "  - $desktop: ${GREEN}✅ Presente${NC}"
        else
            echo -e "  - $desktop: ${YELLOW}⚪ No creado${NC}"
        fi
    done
    echo -e "-----------------------------------------------------------------"
    echo -e "• Iconos vectoriales en ~/.local/share/icons/hicolor/scalable/apps/:"
    for icon in "netflix.svg" "prime-video.svg" "rtve-play.svg" "pluto-tv.svg" "youtube.svg" "orange-tv.svg"; do
        if [ -f "$ICONS_DIR/$icon" ]; then
            echo -e "  - $icon: ${GREEN}✅ Presente${NC}"
        else
            echo -e "  - $icon: ${YELLOW}⚪ No instalado${NC}"
        fi
    done
    echo -e "-----------------------------------------------------------------"
    echo -e "• Favoritos activos en Dock de GNOME:"
    local current_favs
    current_favs=$(run_as_user gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "n/a")
    echo -e "  $current_favs"
    echo -e "${BOLD}=================================================================${NC}"
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
        create_webapps
        ;;
    -d|--dock|dock)
        setup_dock_favorites
        ;;
    -u|--uninstall|uninstall|remove)
        uninstall_webapps
        ;;
    "")
        create_webapps
        setup_dock_favorites
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac
