#!/usr/bin/env bash
# ==============================================================================
# flatpak.sh - Instalación, Gestión y Diagnóstico de Software Flatpak
# openSUSE Tumbleweed | Escritorio: KDE Plasma 6 (Wayland)
# Hardware: AMD Ryzen 7 PRO 4750U / Radeon Vega 7 (VA-API)
# ==============================================================================
# Filosofía y Arquitectura:
# - Enfoque desacoplado y seguro: aplicaciones multimedia, contenedores y herramientas
#   de escritorio aisladas vía Flatpak (Flathub), manteniendo el sistema base 100% puro
#   contra los servidores oficiales de openSUSE (sin conflictos en 'zypper dup').
# - Idempotencia absoluta: comprueba si la aplicación ya está instalada antes de descargar.
# - Detección inteligente de objetivos (--system o --user) evitando conflictos de resolución.
# - Integración nativa con KDE Plasma 6 (tema Breeze Dark y aceleración gráfica RADV/VA-API).
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
FLATPAK_BIN="/usr/bin/flatpak"
FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"

# Colores ANSI para terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# ------------------------------------------------------------------------------
# 3. CATÁLOGO DE APLICACIONES RECOMENDADAS
# Formato: ID|NOMBRE|CATEGORÍA|PERFIL_DEFAULT (1=Sí, 0=No)|DESCRIPCIÓN
# ------------------------------------------------------------------------------
APPS_CATALOG=(
    # Gestión del Sistema y Contenedores (Core)
    "com.github.tchx84.Flatseal|Flatseal|core|1|Gestor gráfico de permisos y sandbox para Flatpaks"
    "io.podman_desktop.PodmanDesktop|Podman Desktop|core|1|Panel gráfico de gestión para Podman, contenedores y Quadlets"
    "io.github.flattool.Warehouse|Warehouse|core|1|Gestor versátil de Flatpaks, limpieza de restos y control de runtimes"
    
    # Multimedia Desacoplado (Reemplazo oficial de Packman sin romper zypper dup)
    "org.videolan.VLC|VLC Media Player|multimedia|1|Reproductor multimedia universal con códecs completos integrados"
    "io.github.celluloid_player.Celluloid|Celluloid|multimedia|1|Reproductor GTK/MPV optimizado para Wayland y aceleración VA-API"
    "com.obsproject.Studio|OBS Studio|multimedia|1|Grabación y streaming con soporte Wayland PipeWire y códecs aislados"
    "org.kde.kdenlive|Kdenlive|multimedia|0|Editor de vídeo profesional no lineal con códecs completos"
    "tv.kodi.Kodi|Kodi Media Center|multimedia|0|Centro multimedia avanzado para streaming y reproducción local"
    "com.stremio.Stremio|Stremio|multimedia|0|Plataforma moderna de agregación de contenido multimedia y streaming"
    "org.audacityteam.Audacity|Audacity|multimedia|0|Editor y grabador de audio profesional multi-pista"
    "com.spotify.Client|Spotify|multimedia|1|Cliente oficial de reproducción de música en streaming"
    
    # Comunicación y Colaboración (Aislamiento Wayland)
    "dev.vencord.Vesktop|Vesktop (Discord)|comms|1|Discord optimizado para Wayland con soporte PipeWire screen sharing"
    "org.telegram.desktop|Telegram Desktop|comms|0|Mensajería rápida y segura en sandbox Flatpak"

    # Desarrollo y Bases de Datos
    "com.usebruno.Bruno|Bruno (API Client)|dev|0|Cliente API REST y GraphQL ligero, offline y versionable en Git"
    "io.dbeaver.DBeaverCommunity|DBeaver Community|dev|0|Gestor universal de bases de datos (SQL, NoSQL, Podman containers)"

    # Productividad, Notas y Copias de Seguridad
    "md.obsidian.Obsidian|Obsidian|productivity|0|Bóveda de conocimiento y notas interconectadas en Markdown local"
    "org.localsend.localsend_app|LocalSend|productivity|0|Transferencia segura y rápida de archivos en red local (LAN/Wi-Fi)"
    "org.gnome.World.PikaBackup|Pika Backup|productivity|0|Copias de seguridad incrementales y cifradas basadas en BorgBackup"

    # Diseño y Creatividad
    "org.gimp.GIMP|GIMP|graphics|0|Editor avanzado de imágenes con códecs y runtimes desacoplados"
    "org.inkscape.Inkscape|Inkscape|graphics|0|Editor profesional de gráficos vectoriales (SVG)"
    
    # Compatibilidad y Gaming
    "com.valvesoftware.Steam.CompatibilityTool.Proton-GE|Proton-GE|gaming|0|Capa de compatibilidad avanzada para Steam Play"
)

# ------------------------------------------------------------------------------
# 4. FUNCIONES AUXILIARES Y DE ENTORNO
# ------------------------------------------------------------------------------
ensure_flatpak_installed() {
    if ! command -v flatpak &>/dev/null; then
        echo -e "${YELLOW}📦 Flatpak no está instalado en el sistema. Instalando vía Zypper...${NC}"
        $SUDO zypper --non-interactive install -y flatpak
    fi
}

ensure_flathub_remote() {
    local target="${1:---system}"
    ensure_flatpak_installed

    if ! flatpak remotes "$target" 2>/dev/null | grep -q "^flathub"; then
        echo -e "${YELLOW}🌐 Configurando repositorio Flathub (${target})...${NC}"
        if [ "$target" = "--system" ]; then
            $SUDO flatpak remote-add --system --if-not-exists flathub "$FLATHUB_URL" 2>/dev/null || true
        else
            flatpak remote-add --user --if-not-exists flathub "$FLATHUB_URL" 2>/dev/null || true
        fi
    fi
}

# Comprueba si una app está instalada (en sistema o en usuario)
is_app_installed() {
    local app_id="$1"
    flatpak info "$app_id" &>/dev/null
}

# Obtiene detalles de una app instalada
get_app_details() {
    local app_id="$1"
    local version="desconocida"
    local install_scope="-"
    local size="-"

    if is_app_installed "$app_id"; then
        version=$(flatpak info "$app_id" 2>/dev/null | awk -F: '/Versión|Version/ {print $2; exit}' | tr -d ' ' || echo "instalada")
        [ -z "$version" ] && version="instalada"
        install_scope=$(flatpak info "$app_id" 2>/dev/null | awk -F: '/Instalación|Installation/ {print $2; exit}' | tr -d ' ' || echo "system")
        size=$(flatpak info "$app_id" 2>/dev/null | awk -F: '/Tamaño instalado|Installed Size/ {print $2; exit}' | xargs || echo "-")
        echo -e "${GREEN}✅ Instalado [${install_scope}] (v${version} | ${size})${NC}"
    else
        echo -e "${RED}❌ No instalado${NC}"
    fi
}

# Resuelve alias cortos a IDs oficiales
resolve_app_id() {
    local query="$1"
    case "${query,,}" in
        flatseal) echo "com.github.tchx84.Flatseal" ;;
        podman|podman-desktop|podmandesktop) echo "io.podman_desktop.PodmanDesktop" ;;
        warehouse) echo "io.github.flattool.Warehouse" ;;
        vlc) echo "org.videolan.VLC" ;;
        celluloid) echo "io.github.celluloid_player.Celluloid" ;;
        obs|obs-studio) echo "com.obsproject.Studio" ;;
        kdenlive) echo "org.kde.kdenlive" ;;
        kodi) echo "tv.kodi.Kodi" ;;
        stremio) echo "com.stremio.Stremio" ;;
        audacity) echo "org.audacityteam.Audacity" ;;
        spotify) echo "com.spotify.Client" ;;
        vesktop|discord) echo "dev.vencord.Vesktop" ;;
        telegram|telegram-desktop) echo "org.telegram.desktop" ;;
        proton|proton-ge) echo "com.valvesoftware.Steam.CompatibilityTool.Proton-GE" ;;
        bruno) echo "com.usebruno.Bruno" ;;
        dbeaver) echo "io.dbeaver.DBeaverCommunity" ;;
        obsidian) echo "md.obsidian.Obsidian" ;;
        localsend) echo "org.localsend.localsend_app" ;;
        pika|pika-backup|pikabackup) echo "org.gnome.World.PikaBackup" ;;
        gimp) echo "org.gimp.GIMP" ;;
        inkscape) echo "org.inkscape.Inkscape" ;;
        *) echo "$query" ;;
    esac
}

# Resuelve el nombre descriptivo a partir del ID o alias
resolve_app_name() {
    local target_id="$1"
    for item in "${APPS_CATALOG[@]}"; do
        IFS="|" read -r c_id c_name c_cat c_def c_desc <<< "$item"
        if [ "$c_id" = "$target_id" ]; then
            echo "$c_name"
            return 0
        fi
    done
    echo "$target_id"
}

# ------------------------------------------------------------------------------
# 5. DIAGNÓSTICO DEL SISTEMA (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 ESTADO DE FLATPAK Y FLATHUB - OPENSUSE TUMBLEWEED${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    
    # 1. Sistema base
    if command -v flatpak &>/dev/null; then
        local flatpak_ver
        flatpak_ver=$(flatpak --version 2>/dev/null || echo "flatpak")
        echo -e "• Binario Flatpak:              ${GREEN}✅ $(which flatpak) (${flatpak_ver})${NC}"
    else
        echo -e "• Binario Flatpak:              ${RED}❌ No instalado${NC}"
    fi

    # 2. Remotos Flathub
    local flathub_sys
    flathub_sys=$(if flatpak remotes --system 2>/dev/null | grep -qi "^flathub"; then echo -e "${GREEN}✅ Configurado${NC}"; else echo -e "${RED}❌ No presente${NC}"; fi)
    echo -e "• Repositorio Flathub (System): $flathub_sys"

    local flathub_usr
    flathub_usr=$(if flatpak remotes --user 2>/dev/null | grep -qi "^flathub"; then echo -e "${GREEN}✅ Configurado${NC}"; else echo -e "${YELLOW}⚠️ No configurado (opcional)${NC}"; fi)
    echo -e "• Repositorio Flathub (User):   $flathub_usr"

    # 3. Integración con KDE / GTK
    local gtk_breeze
    gtk_breeze=$(if flatpak list 2>/dev/null | grep -qi "org.gtk.Gtk3theme.Breeze"; then echo -e "${GREEN}✅ Instalado (Breeze Dark GTK)${NC}"; else echo -e "${YELLOW}No instalado${NC}"; fi)
    echo -e "• Tema Breeze para Flatpak GTK: $gtk_breeze"

    echo -e "${BOLD}-----------------------------------------------------------------${NC}"
    echo -e "${BOLD}📦 CATÁLOGO DE APLICACIONES FLATPAK:${NC}"
    echo -e "${BOLD}-----------------------------------------------------------------${NC}"

    local total_installed=0
    local total_apps=0

    for item in "${APPS_CATALOG[@]}"; do
        IFS="|" read -r app_id app_name category is_default desc <<< "$item"
        total_apps=$((total_apps + 1))
        
        printf "• ${BOLD}%-22s${NC} " "${app_name}:"
        local details
        details=$(get_app_details "$app_id")
        echo -e "$details"

        if is_app_installed "$app_id"; then
            total_installed=$((total_installed + 1))
        fi
    done

    echo -e "${BOLD}=================================================================${NC}"
    echo -e "📊 Resumen: ${GREEN}${total_installed}${NC} de ${BOLD}${total_apps}${NC} aplicaciones instaladas."
    echo -e "💡 Consejo: Ejecuta '${BOLD}$0 --help${NC}' para opciones de instalación modular o mantenimiento."
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 6. INSTALACIÓN DE APLICACIONES
# ------------------------------------------------------------------------------
install_single_app() {
    local app_id="$1"
    local app_name="$2"
    local target_scope="$3"

    if is_app_installed "$app_id"; then
        echo -e "  ${GREEN}✔${NC} ${BOLD}${app_name}${NC} (${CYAN}${app_id}${NC}) ya está instalado. Omitiendo."
        return 0
    fi

    echo -e "  ${YELLOW}⬇️ Instalando${NC} ${BOLD}${app_name}${NC} (${CYAN}${app_id}${NC}) [${target_scope}]..."
    
    # Se añade la flag de scope (--system o --user) para evitar ambigüedades si flathub está en ambos
    if flatpak install "$target_scope" -y flathub "$app_id"; then
        echo -e "  ${GREEN}✅ ${app_name} instalado correctamente.${NC}"
    else
        echo -e "  ${RED}❌ Error al instalar ${app_name} (${app_id}).${NC}" >&2
    fi
}

install_suite() {
    local filter_mode="${1:-default}"
    local target_scope="${2:---system}"

    ensure_flatpak_installed
    ensure_flathub_remote "$target_scope"

    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🚀 INSTALANDO SOFTWARE VÍA FLATPAK (${target_scope})${NC}"
    echo -e "Modo de selección: ${BOLD}${filter_mode}${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    local count=0
    for item in "${APPS_CATALOG[@]}"; do
        IFS="|" read -r app_id app_name category is_default desc <<< "$item"
        local should_install=0

        case "$filter_mode" in
            default)
                if [ "$is_default" -eq 1 ]; then should_install=1; fi
                ;;
            all)
                should_install=1
                ;;
            essential|core)
                if [ "$category" = "core" ]; then should_install=1; fi
                ;;
            multimedia)
                if [ "$category" = "multimedia" ]; then should_install=1; fi
                ;;
            comms)
                if [ "$category" = "comms" ]; then should_install=1; fi
                ;;
            gaming)
                if [ "$category" = "gaming" ]; then should_install=1; fi
                ;;
            dev)
                if [ "$category" = "dev" ]; then should_install=1; fi
                ;;
            productivity)
                if [ "$category" = "productivity" ]; then should_install=1; fi
                ;;
            graphics)
                if [ "$category" = "graphics" ]; then should_install=1; fi
                ;;
        esac

        if [ "$should_install" -eq 1 ]; then
            count=$((count + 1))
            echo -e "\n${BOLD}[$count] Procesando ${app_name}...${NC}"
            install_single_app "$app_id" "$app_name" "$target_scope"
        fi
    done

    echo -e "\n${BOLD}=================================================================${NC}"
    echo -e "${GREEN}✅ Proceso de instalación finalizado con éxito.${NC}"
    echo -e "💡 Recuerda que puedes gestionar los permisos de tus apps con ${BOLD}Flatseal${NC}."
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 7. TAREAS DE MANTENIMIENTO (UPDATE / CLEAN)
# ------------------------------------------------------------------------------
update_all() {
    ensure_flatpak_installed
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}🔄 ACTUALIZANDO TODAS LAS APLICACIONES Y RUNTIMES FLATPAK...${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    flatpak update -y
    echo -e "${GREEN}✅ Todas las aplicaciones y runtimes están al día.${NC}"
}

clean_unused() {
    ensure_flatpak_installed
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${YELLOW}🧹 LIMPIANDO RUNTIMES Y DEPENDENCIAS HUÉRFANAS...${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    flatpak uninstall --unused -y
    echo -e "${GREEN}✅ Limpieza de runtimes no utilizados completada.${NC}"
}

# ------------------------------------------------------------------------------
# 8. MENSAJE DE AYUDA (--help)
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
📦 Gestor e Instalador de Software Flatpak - openSUSE Tumbleweed
(Mantiene el sistema base limpio y libre de conflictos en 'zypper dup')

Uso:
  $0 [OPCIÓN] [PARÁMETROS]

Opciones principales:
  (sin argumentos)        Instala el conjunto recomendado por defecto (Core + Multimedia + Comms).
  -s, --status            Muestra el estado de Flatpak, repositorios y aplicaciones instaladas.
  -a, --all               Instala todo el catálogo completo disponible.
  -e, --essential, --core Instala únicamente las herramientas esenciales del sistema (Flatseal, Podman Desktop, Warehouse).
  -m, --multimedia        Instala la suite multimedia desacoplada (VLC, Celluloid, OBS Studio, Kdenlive, Kodi, Stremio, Audacity, Spotify).
      --dev               Instala herramientas de desarrollo y APIs (Bruno, DBeaver).
      --productivity      Instala utilidades de productividad y notas (Obsidian, LocalSend, Pika Backup).
      --graphics          Instala suite de diseño gráfico (GIMP, Inkscape).
      --comms             Instala las herramientas de comunicación (Vesktop/Discord, Telegram).
      --gaming            Instala herramientas de gaming (Proton-GE).
  -u, --update            Actualiza todas las aplicaciones y runtimes instalados.
  -c, --clean             Elimina runtimes y extensiones sin usar ('flatpak uninstall --unused').
  -h, --help              Muestra este mensaje de ayuda.

Instalación individual:
  $0 install <app_id|alias> [--user|--system]
  Ejemplos:
    $0 install vlc
    $0 install warehouse
    $0 install dev.vencord.Vesktop
    $0 install obs --user

Modificadores de ámbito:
  --system                Instala a nivel de sistema (/var/lib/flatpak) [Predeterminado].
  --user                  Instala en el directorio del usuario actual (~/.local/share/flatpak).

Catálogo disponible:
  • Flatseal          (com.github.tchx84.Flatseal)       [Gestión de permisos]
  • Podman Desktop    (io.podman_desktop.PodmanDesktop)  [Contenedores Podman]
  • Warehouse         (io.github.flattool.Warehouse)     [Mantenimiento Flatpak]
  • VLC               (org.videolan.VLC)                 [Reproductor universal]
  • Celluloid         (io.github.celluloid_player.Celluloid) [Reproductor MPV VA-API]
  • OBS Studio        (com.obsproject.Studio)            [Grabación Wayland]
  • Kdenlive          (org.kde.kdenlive)                 [Editor de vídeo no lineal]
  • Kodi              (tv.kodi.Kodi)                     [Centro multimedia]
  • Stremio           (com.stremio.Stremio)              [Plataforma de streaming]
  • Audacity          (org.audacityteam.Audacity)        [Edición de audio]
  • Spotify           (com.spotify.Client)               [Música en streaming]
  • Vesktop           (dev.vencord.Vesktop)              [Discord para Wayland]
  • Telegram          (org.telegram.desktop)             [Mensajería segura]
  • Bruno             (com.usebruno.Bruno)               [Cliente API REST/GraphQL]
  • DBeaver           (io.dbeaver.DBeaverCommunity)      [Gestor universal de BBDD]
  • Obsidian          (md.obsidian.Obsidian)             [Bóveda de notas Markdown]
  • LocalSend         (org.localsend.localsend_app)      [Compartir por LAN/Wi-Fi]
  • Pika Backup       (org.gnome.World.PikaBackup)       [Copias de seguridad Borg]
  • GIMP              (org.gimp.GIMP)                    [Edición gráfica avanzada]
  • Inkscape          (org.inkscape.Inkscape)            [Gráficos vectoriales SVG]
  • Proton-GE         (com.valvesoftware.Steam.CompatibilityTool.Proton-GE) [Juegos Steam]
EOF
}

# ------------------------------------------------------------------------------
# 9. PROCESAMIENTO DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
TARGET_SCOPE="--system"

# Detectar flags de ámbito en cualquier posición
for arg in "$@"; do
    case "$arg" in
        --user) TARGET_SCOPE="--user" ;;
        --system) TARGET_SCOPE="--system" ;;
    esac
done

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    --update|-u|update)
        update_all
        exit 0
        ;;
    --clean|-c|clean)
        clean_unused
        exit 0
        ;;
    --all|-a|all)
        install_suite "all" "$TARGET_SCOPE"
        exit 0
        ;;
    --essential|-e|essential|--core|core)
        install_suite "core" "$TARGET_SCOPE"
        exit 0
        ;;
    --multimedia|-m|multimedia)
        install_suite "multimedia" "$TARGET_SCOPE"
        exit 0
        ;;
    --comms|comms)
        install_suite "comms" "$TARGET_SCOPE"
        exit 0
        ;;
    --gaming|gaming)
        install_suite "gaming" "$TARGET_SCOPE"
        exit 0
        ;;
    --dev|dev)
        install_suite "dev" "$TARGET_SCOPE"
        exit 0
        ;;
    --productivity|productivity)
        install_suite "productivity" "$TARGET_SCOPE"
        exit 0
        ;;
    --graphics|graphics)
        install_suite "graphics" "$TARGET_SCOPE"
        exit 0
        ;;
    install)
        shift
        if [ $# -eq 0 ]; then
            echo -e "${RED}❌ Error: Debes especificar el nombre o ID de la aplicación.${NC}" >&2
            echo -e "Ejemplo: $0 install vlc" >&2
            exit 1
        fi
        
        target_app=""
        for arg in "$@"; do
            if [ "$arg" != "--user" ] && [ "$arg" != "--system" ]; then
                target_app="$arg"
                break
            fi
        done

        if [ -z "$target_app" ]; then
            echo -e "${RED}❌ Error: No se especificó ninguna aplicación válida.${NC}" >&2
            exit 1
        fi

        app_id=$(resolve_app_id "$target_app")
        app_name=$(resolve_app_name "$app_id")
        ensure_flatpak_installed
        ensure_flathub_remote "$TARGET_SCOPE"
        install_single_app "$app_id" "$app_name" "$TARGET_SCOPE"
        exit 0
        ;;
    --user|--system)
        # Invocado solo con flag de scope: ejecuta perfil por defecto en ese scope
        install_suite "default" "$TARGET_SCOPE"
        exit 0
        ;;
    "")
        # Invocación por defecto sin argumentos
        install_suite "default" "$TARGET_SCOPE"
        exit 0
        ;;
    *)
        # Si el primer argumento coincide con un alias del catálogo, instalarlo
        resolved=$(resolve_app_id "$1")
        if [ "$resolved" != "$1" ] || [[ "$1" == *.*.* ]]; then
            app_name=$(resolve_app_name "$resolved")
            ensure_flatpak_installed
            ensure_flathub_remote "$TARGET_SCOPE"
            install_single_app "$resolved" "$app_name" "$TARGET_SCOPE"
            exit 0
        fi

        echo -e "${RED}❌ Opción no reconocida: '$1'${NC}\n" >&2
        show_help
        exit 1
        ;;
esac
