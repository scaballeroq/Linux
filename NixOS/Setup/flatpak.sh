#!/usr/bin/env bash
# ==============================================================================
# flatpak.sh - Instalación, Gestión y Diagnóstico de Software Flatpak en NixOS
# Escritorio: KDE Plasma 6 (Wayland)
# ==============================================================================

set -euo pipefail

FLATPAK_BIN="$(command -v flatpak 2>/dev/null || echo 'flatpak')"
FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"

# Colores ANSI
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Detección de usuario
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

APPS_CATALOG=(
    # Gestión del Sistema y Contenedores (Core)
    "com.github.tchx84.Flatseal|Flatseal|core|1|Gestor gráfico de permisos y sandbox para Flatpaks"
    "io.podman_desktop.PodmanDesktop|Podman Desktop|core|1|Panel gráfico de gestión para Podman, contenedores y Quadlets"
    "io.github.flattool.Warehouse|Warehouse|core|1|Gestor versátil de Flatpaks, limpieza de restos y control de runtimes"

    # Multimedia Desacoplado
    "org.videolan.VLC|VLC Media Player|multimedia|1|Reproductor multimedia universal con códecs completos integrados"
    "io.github.celluloid_player.Celluloid|Celluloid|multimedia|1|Reproductor GTK/MPV optimizado para Wayland y aceleración VA-API"
    "com.obsproject.Studio|OBS Studio|multimedia|1|Grabación y streaming con soporte Wayland PipeWire y códecs aislados"
    "org.kde.kdenlive|Kdenlive|multimedia|0|Editor de vídeo profesional no lineal con códecs completos"
    "tv.kodi.Kodi|Kodi Media Center|multimedia|0|Centro multimedia avanzado para streaming y reproducción local"
    "com.stremio.Stremio|Stremio|multimedia|0|Plataforma moderna de agregación de contenido multimedia y streaming"
    "org.audacityteam.Audacity|Audacity|multimedia|0|Editor y grabador de audio profesional multi-pista"
    "com.spotify.Client|Spotify|multimedia|1|Cliente oficial de reproducción de música en streaming"

    # Comunicación y Colaboración
    "dev.vencord.Vesktop|Vesktop (Discord)|comms|1|Discord optimizado para Wayland con soporte PipeWire screen sharing"
    "org.telegram.desktop|Telegram Desktop|comms|0|Mensajería rápida y segura en sandbox Flatpak"

    # Desarrollo y Productividad
    "com.usebruno.Bruno|Bruno (API Client)|dev|0|Cliente API REST y GraphQL ligero y offline"
    "io.dbeaver.DBeaverCommunity|DBeaver Community|dev|0|Gestor universal de bases de datos"
    "org.libreoffice.LibreOffice|LibreOffice|productivity|0|Suite ofimática completa desacoplada"
    "md.obsidian.Obsidian|Obsidian|productivity|0|Bóveda de conocimiento y notas interconectadas en Markdown"
    "org.localsend.localsend_app|LocalSend|productivity|0|Transferencia segura y rápida de archivos en LAN"
    "org.gnome.World.PikaBackup|Pika Backup|productivity|0|Copias de seguridad basadas en BorgBackup"

    # Navegación y Diseño
    "org.mozilla.firefox|Mozilla Firefox|web|0|Navegador web con sandbox estricto"
    "org.gimp.GIMP|GIMP|graphics|0|Editor avanzado de imágenes"
    "org.inkscape.Inkscape|Inkscape|graphics|0|Editor profesional de gráficos vectoriales (SVG)"

    # Gaming
    "com.valvesoftware.Steam.CompatibilityTool.Proton-GE|Proton-GE|gaming|0|Capa de compatibilidad avanzada para Steam Play"
)

ensure_flathub_remote() {
    local target="${1:---user}"
    if ! command -v flatpak &>/dev/null; then
        echo -e "${RED}❌ Flatpak no está instalado. En NixOS se activa con 'services.flatpak.enable = true;' (modules/flatpak.nix).${NC}"
        return 1
    fi

    if ! flatpak remotes "$target" 2>/dev/null | grep -q "^flathub"; then
        echo -e "${YELLOW}🌐 Configurando repositorio Flathub (${target})...${NC}"
        if [ "$target" = "--system" ]; then
            $SUDO flatpak remote-add --system --if-not-exists flathub "$FLATHUB_URL" 2>/dev/null || true
        else
            flatpak remote-add --user --if-not-exists flathub "$FLATHUB_URL" 2>/dev/null || true
        fi
    fi
}

is_app_installed() {
    local app_id="$1"
    flatpak info "$app_id" &>/dev/null
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}🔍 DIAGNÓSTICO DE FLATPAK Y FLATHUB (NIXOS)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    echo -n "• Estado de Flatpak: "
    if command -v flatpak &>/dev/null; then
        echo -e "${GREEN}✅ Instalado ($(flatpak --version))${NC}"
    else
        echo -e "${RED}❌ No instalado (revisar modules/flatpak.nix)${NC}"
    fi

    echo -n "• Repositorio Flathub (Sistema): "
    if flatpak remotes --system 2>/dev/null | grep -q "^flathub"; then
        echo -e "${GREEN}✅ Activo${NC}"
    else
        echo -e "${YELLOW}ℹ️ No configurado en system${NC}"
    fi

    echo -n "• Repositorio Flathub (Usuario): "
    if flatpak remotes --user 2>/dev/null | grep -q "^flathub"; then
        echo -e "${GREEN}✅ Activo${NC}"
    else
        echo -e "${YELLOW}ℹ️ No configurado en user${NC}"
    fi

    echo ""
    echo -e "${BOLD}📦 Catálogo de Aplicaciones:${NC}"
    for app_entry in "${APPS_CATALOG[@]}"; do
        IFS="|" read -r app_id app_name category is_default desc <<< "$app_entry"
        printf "  %-32s : " "$app_name"
        if is_app_installed "$app_id"; then
            echo -e "${GREEN}✅ Instalado${NC}"
        else
            echo -e "${RED}❌ No instalado${NC}"
        fi
    done
    echo -e "${BOLD}=================================================================${NC}"
}

install_apps() {
    local mode="${1:-essential}"
    ensure_flathub_remote --user

    echo -e "${CYAN}🚀 Iniciando instalación de Flatpaks (Modo: ${mode})...${NC}"
    for app_entry in "${APPS_CATALOG[@]}"; do
        IFS="|" read -r app_id app_name category is_default desc <<< "$app_entry"

        local should_install=0
        case "$mode" in
            all) should_install=1 ;;
            essential) [ "$is_default" -eq 1 ] && should_install=1 ;;
            multimedia) [ "$category" = "multimedia" ] && should_install=1 ;;
            core) [ "$category" = "core" ] && should_install=1 ;;
        esac

        if [ "$should_install" -eq 1 ]; then
            if is_app_installed "$app_id"; then
                echo -e "${GREEN}✅ $app_name ya está instalado.${NC}"
            else
                echo -e "${YELLOW}⬇️ Instalando $app_name ($app_id)...${NC}"
                flatpak install -y --user --noninteractive flathub "$app_id" || echo -e "${RED}⚠️ Error al instalar $app_name${NC}"
            fi
        fi
    done
    echo -e "${GREEN}✅ Despliegue de Flatpak finalizado.${NC}"
}

update_apps() {
    echo -e "${CYAN}🔄 Actualizando todas las aplicaciones y runtimes de Flatpak...${NC}"
    flatpak update -y
    echo -e "${GREEN}✅ Flatpaks actualizados.${NC}"
}

clean_apps() {
    echo -e "${CYAN}🧹 Limpiando runtimes huérfanos y no utilizados de Flatpak...${NC}"
    flatpak uninstall --unused -y
    echo -e "${GREEN}✅ Limpieza completada.${NC}"
}

show_help() {
    cat <<EOF
📦 Gestor de Aplicaciones Flatpak - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala el perfil recomendado (Flatseal, Warehouse, Podman Desktop, VLC, Spotify, Vesktop).
  --status, -s        Comprueba el estado de repositorios y aplicaciones instaladas.
  --all, -a           Instala todo el catálogo completo.
  --multimedia, -m    Instala únicamente las aplicaciones multimedia.
  --update, -u        Actualiza aplicaciones y runtimes instalados.
  --clean, -c         Elimina dependencias y runtimes huérfanos no utilizados.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --all|-a|all)
        install_apps all
        exit 0
        ;;
    --multimedia|-m|multimedia)
        install_apps multimedia
        exit 0
        ;;
    --update|-u|update)
        update_apps
        exit 0
        ;;
    --clean|-c|clean)
        clean_apps
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        install_apps essential
        ;;
esac
