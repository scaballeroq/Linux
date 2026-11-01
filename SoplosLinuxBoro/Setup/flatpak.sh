#!/usr/bin/env bash
# ==============================================================================
# flatpak.sh - Instalación, Gestión y Diagnóstico de Software Flatpak
# Soplos Linux Boro | Escritorio: GNOME Shell (Wayland)
# Hardware: AMD Ryzen 7 7730U / Radeon Graphics (Vega 8) (VA-API)
# ==============================================================================
# Filosofía y Arquitectura:
# - Soplos Linux Boro integra Flatpak y Flathub de fábrica a nivel de sistema.
# - Enfoque desacoplado y seguro: aplicaciones multimedia, de productividad y
#   desarrollo aisladas vía Flatpak (Flathub), preservando la integridad del
#   sistema base Debian Testing.
# - 100% nativo GNOME y Wayland (PipeWire, xdg-desktop-portal-gnome, Adwaita).
# - Idempotencia absoluta y rendimiento óptimo: comprobaciones en lote sin I/O redundante.
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

# ------------------------------------------------------------------------------
# 3. CATÁLOGO DE APLICACIONES RECOMENDADAS
# Formato: ID|NOMBRE|CATEGORÍA|PERFIL_DEFAULT (1=Sí, 0=No)|DESCRIPCIÓN
# ------------------------------------------------------------------------------
APPS_CATALOG=(
    # Gestión del Sistema y Ecosistema Soplos Linux Boro (Core)
    "io.github.kolunmi.Bazaar|Bazar|core|1|Tienda gráfica de aplicaciones Flatpak integrada en Soplos Linux"
    "io.github.flattool.Warehouse|Warehouse|core|1|Gestor versátil de Flatpaks, limpieza de restos y control de runtimes"
    "com.github.tchx84.Flatseal|Flatseal|core|1|Gestor gráfico de permisos y sandbox para Flatpaks en GNOME"
    "io.podman_desktop.PodmanDesktop|Podman Desktop|core|1|Panel gráfico de gestión para Podman, contenedores y Quadlets"
    
    # Multimedia Desacoplado
    "org.videolan.VLC|VLC Media Player|multimedia|1|Reproductor multimedia universal con códecs completos integrados"
    "io.github.celluloid_player.Celluloid|Celluloid|multimedia|1|Reproductor GTK/MPV optimizado para Wayland y aceleración VA-API"
    "com.obsproject.Studio|OBS Studio|multimedia|1|Grabación y streaming con soporte Wayland PipeWire y códecs aislados"
    "org.shotcut.Shotcut|Shotcut|multimedia|0|Editor de vídeo profesional no lineal con códecs completos"
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
    "org.libreoffice.LibreOffice|LibreOffice|productivity|0|Suite ofimática completa desacoplada del sistema"
    "md.obsidian.Obsidian|Obsidian|productivity|0|Bóveda de conocimiento y notas interconectadas en Markdown local"
    "org.localsend.localsend_app|LocalSend|productivity|0|Transferencia segura y rápida de archivos en red local (LAN/Wi-Fi)"
    "org.gnome.World.PikaBackup|Pika Backup|productivity|0|Copias de seguridad incrementales y cifradas basadas en BorgBackup"

    # Navegadores Web y Privacidad (Firefox base ya viene preinstalado nativamente vía APT)
    "org.mozilla.firefox|Mozilla Firefox (Flatpak)|web|0|Navegador web con sandbox estricto y códecs multimedia completos"

    # Diseño y Creatividad
    "org.gimp.GIMP|GIMP|graphics|0|Editor avanzado de imágenes con códecs y runtimes desacoplados"
    "org.inkscape.Inkscape|Inkscape|graphics|0|Editor profesional de gráficos vectoriales (SVG)"
    
    # Compatibilidad y Gaming
    "com.valvesoftware.Steam.CompatibilityTool.Proton-GE|Proton-GE|gaming|0|Capa de compatibilidad avanzada para Steam Play"
)

# ------------------------------------------------------------------------------
# 4. MAPAS EN MEMORIA PARA CONSULTA RÁPIDA (OPTIMIZACIÓN BATCH)
# ------------------------------------------------------------------------------
declare -A INSTALLED_APPS=()
declare -A INSTALLED_VERSIONS=()
declare -A INSTALLED_SCOPES=()
declare -A INSTALLED_SIZES=()
CACHE_LOADED=0

load_installed_cache() {
    if [ "$CACHE_LOADED" -eq 1 ]; then
        return 0
    fi

    if ! command -v flatpak &>/dev/null; then
        return 0
    fi

    # Carga de una sola llamada todas las aplicaciones instaladas con sus metadatos
    while IFS=$'\t' read -r app_id ver scope size; do
        [ -z "$app_id" ] && continue
        INSTALLED_APPS["$app_id"]=1
        INSTALLED_VERSIONS["$app_id"]="${ver:-instalada}"
        INSTALLED_SCOPES["$app_id"]="${scope:-system}"
        INSTALLED_SIZES["$app_id"]="${size:--}"
    done < <(flatpak list --app --columns=application,version,installation,size 2>/dev/null)

    CACHE_LOADED=1
}

# ------------------------------------------------------------------------------
# 5. FUNCIONES AUXILIARES Y DE ENTORNO
# ------------------------------------------------------------------------------
ensure_flatpak_installed() {
    if command -v flatpak &>/dev/null; then
        return 0
    fi

    echo -e "${YELLOW}📦 Flatpak no está disponible en la ruta estándar. Verificando repositorios APT...${NC}"
    $SUDO apt update -qq
    $SUDO apt install -y flatpak gnome-software-plugin-flatpak
}

ensure_flathub_remote() {
    local target="${1:---system}"
    ensure_flatpak_installed

    # En Soplos Linux Boro, Flathub viene activo en --system por defecto.
    if flatpak remotes 2>/dev/null | grep -qi "^flathub"; then
        # Si el repositorio ya está activo en cualquier ámbito, no requiere volver a registrarse
        return 0
    fi

    echo -e "${YELLOW}🌐 Configurando repositorio Flathub (${target})...${NC}"
    if [ "$target" = "--system" ]; then
        if [ "$EUID" -ne 0 ] && command -v sudo &>/dev/null; then
            sudo flatpak remote-add --system --if-not-exists flathub "$FLATHUB_URL" 2>/dev/null || true
        else
            flatpak remote-add --system --if-not-exists flathub "$FLATHUB_URL" 2>/dev/null || true
        fi
    else
        flatpak remote-add --user --if-not-exists flathub "$FLATHUB_URL" 2>/dev/null || true
    fi
}

is_app_installed() {
    local app_id="$1"
    load_installed_cache

    if [ "$CACHE_LOADED" -eq 1 ]; then
        [[ -n "${INSTALLED_APPS[$app_id]:-}" ]]
    else
        flatpak info "$app_id" &>/dev/null
    fi
}

get_app_details() {
    local app_id="$1"
    load_installed_cache

    if is_app_installed "$app_id"; then
        local version="${INSTALLED_VERSIONS[$app_id]:-instalada}"
        local install_scope="${INSTALLED_SCOPES[$app_id]:-system}"
        local size="${INSTALLED_SIZES[$app_id]:--}"
        echo -e "${GREEN}✅ Instalado [${install_scope}] (v${version} | ${size})${NC}"
    else
        echo -e "${RED}❌ No instalado${NC}"
    fi
}

resolve_app_id() {
    local query="$1"
    case "${query,,}" in
        bazar|bazaar) echo "io.github.kolunmi.Bazaar" ;;
        warehouse) echo "io.github.flattool.Warehouse" ;;
        flatseal) echo "com.github.tchx84.Flatseal" ;;
        podman|podman-desktop|podmandesktop) echo "io.podman_desktop.PodmanDesktop" ;;
        vlc) echo "org.videolan.VLC" ;;
        celluloid) echo "io.github.celluloid_player.Celluloid" ;;
        obs|obs-studio) echo "com.obsproject.Studio" ;;
        shotcut) echo "org.shotcut.Shotcut" ;;
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
        libreoffice|office) echo "org.libreoffice.LibreOffice" ;;
        firefox) echo "org.mozilla.firefox" ;;
        *) echo "$query" ;;
    esac
}

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
# 6. DIAGNÓSTICO DEL SISTEMA (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 ESTADO DE FLATPAK Y FLATHUB - SOPLOS LINUX BORO (GNOME WAYLAND)${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    
    if command -v flatpak &>/dev/null; then
        local flatpak_ver
        flatpak_ver=$(flatpak --version 2>/dev/null || echo "flatpak")
        echo -e "• Motor Flatpak (Nativo):       ${GREEN}✅ $(which flatpak) (${flatpak_ver})${NC}"
    else
        echo -e "• Motor Flatpak:                ${RED}❌ No instalado${NC}"
    fi

    local flathub_sys
    flathub_sys=$(if flatpak remotes --system 2>/dev/null | grep -qi "^flathub"; then echo -e "${GREEN}✅ Configurado (Predeterminado Soplos Linux)${NC}"; else echo -e "${RED}❌ No presente${NC}"; fi)
    echo -e "• Repositorio Flathub (System): $flathub_sys"

    local flathub_usr
    flathub_usr=$(if flatpak remotes --user 2>/dev/null | grep -qi "^flathub"; then echo -e "${GREEN}✅ Configurado${NC}"; else echo -e "${BLUE}ℹ️ Disponible vía repositorio de sistema${NC}"; fi)
    echo -e "• Repositorio Flathub (User):   $flathub_usr"

    # Verificación de runtimes críticos de Soplos Linux (Mesa AMD GPU, Codecs, GNOME)
    echo -e "${BOLD}-----------------------------------------------------------------${NC}"
    echo -e "${BOLD}⚙️  RUNTIMES ESENCIALES (Wayland / AMD Radeon RADV / Códecs):${NC}"
    echo -e "${BOLD}-----------------------------------------------------------------${NC}"

    local mesa_gl
    mesa_gl=$(if flatpak list --runtime 2>/dev/null | grep -q "Platform.GL.default"; then echo -e "${GREEN}✅ Activo (Aceleración Gráfica Mesa AMD RADV)${NC}"; else echo -e "${YELLOW}⚠️ No detectado${NC}"; fi)
    echo -e "• Mesa Graphics Driver (GL):    $mesa_gl"

    local codecs_extra
    codecs_extra=$(if flatpak list --runtime 2>/dev/null | grep -q "Platform.codecs-extra"; then echo -e "${GREEN}✅ Activo (Codecs multimedia adicionales H.264/H.265/VA-API)${NC}"; else echo -e "${YELLOW}⚠️ No detectado${NC}"; fi)
    echo -e "• Extensiones de Códecs:        $codecs_extra"

    local gnome_platform
    gnome_platform=$(if flatpak list --runtime 2>/dev/null | grep -q "org.gnome.Platform"; then echo -e "${GREEN}✅ Activo (GNOME Desktop Integration)${NC}"; else echo -e "${YELLOW}⚠️ No detectado${NC}"; fi)
    echo -e "• Plataforma GNOME Shell:       $gnome_platform"

    echo -e "${BOLD}-----------------------------------------------------------------${NC}"
    echo -e "${BOLD}📦 CATÁLOGO DE APLICACIONES FLATPAK:${NC}"
    echo -e "${BOLD}-----------------------------------------------------------------${NC}"

    load_installed_cache

    local total_installed=0
    local total_apps=0

    for item in "${APPS_CATALOG[@]}"; do
        IFS="|" read -r app_id app_name category is_default desc <<< "$item"
        total_apps=$((total_apps + 1))
        
        printf "• ${BOLD}%-26s${NC} " "${app_name}:"
        local details
        details=$(get_app_details "$app_id")
        echo -e "$details"

        if is_app_installed "$app_id"; then
            total_installed=$((total_installed + 1))
        fi
    done

    echo -e "${BOLD}=================================================================${NC}"
    echo -e "📊 Resumen: ${GREEN}${total_installed}${NC} de ${BOLD}${total_apps}${NC} aplicaciones del catálogo instaladas."
    echo -e "💡 Consejo: Ejecuta '${BOLD}$0 --help${NC}' para opciones de instalación modular o mantenimiento."
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 7. INSTALACIÓN DE APLICACIONES
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
    
    if flatpak install "$target_scope" -y flathub "$app_id"; then
        echo -e "  ${GREEN}✅ ${app_name} instalado correctamente.${NC}"
        # Invalidar caché local
        CACHE_LOADED=0
    else
        echo -e "  ${RED}❌ Error al instalar ${app_name} (${app_id}).${NC}" >&2
    fi
}

install_suite() {
    local filter_mode="${1:-default}"
    local target_scope="${2:---system}"

    ensure_flatpak_installed
    ensure_flathub_remote "$target_scope"
    load_installed_cache

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
            web)
                if [ "$category" = "web" ]; then should_install=1; fi
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
    echo -e "💡 Recuerda que puedes gestionar los permisos de tus apps con ${BOLD}Flatseal${NC} o ${BOLD}Warehouse${NC}."
    echo -e "${BOLD}=================================================================${NC}"
}

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
    flatpak uninstall --unused -y || true
    echo -e "${GREEN}✅ Limpieza de runtimes no utilizados completada.${NC}"
}

show_help() {
    cat <<EOF
📦 Gestor e Instalador de Software Flatpak - Soplos Linux Boro

Uso:
  $0 [OPCIÓN] [MODIFICADORES]

Opciones principales:
  (sin argumentos)        Instala el conjunto recomendado por defecto (Core + Multimedia + Comms).
  -s, --status            Muestra el estado de Flatpak, repositorios, runtimes gráficos y aplicaciones.
  -a, --all               Instala todo el catálogo completo disponible.
  -e, --essential, --core Instala únicamente las herramientas esenciales del sistema (Bazar, Warehouse, Flatseal, Podman Desktop).
  -m, --multimedia        Instala la suite multimedia desacoplada (VLC, Celluloid, OBS Studio, Shotcut, Kodi, Stremio, Audacity, Spotify).
      --dev               Instala herramientas de desarrollo y APIs (Bruno, DBeaver).
      --productivity      Instala utilidades de productividad y ofimática (LibreOffice, Obsidian, LocalSend, Pika Backup).
      --graphics          Instala suite de diseño gráfico (GIMP, Inkscape).
      --web               Instala navegadores web en sandbox (Mozilla Firefox).
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

Modificadores de ámbito (compatibles en cualquier posición):
  --system                Instala a nivel de sistema (/var/lib/flatpak) [Predeterminado en Soplos Linux].
  --user                  Instala en el directorio del usuario actual (~/.local/share/flatpak).
EOF
}

# ------------------------------------------------------------------------------
# 8. PARSEO ROBUSTO DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
TARGET_SCOPE="--system"
ACTION=""
ACTION_PARAM=""

for arg in "$@"; do
    case "$arg" in
        --user)
            TARGET_SCOPE="--user"
            ;;
        --system)
            TARGET_SCOPE="--system"
            ;;
        *)
            if [ -z "$ACTION" ]; then
                ACTION="$arg"
            elif [ -z "$ACTION_PARAM" ]; then
                ACTION_PARAM="$arg"
            fi
            ;;
    esac
done

case "${ACTION:-}" in
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
    --essential|--core|-e)
        install_suite "core" "$TARGET_SCOPE"
        exit 0
        ;;
    --multimedia|-m)
        install_suite "multimedia" "$TARGET_SCOPE"
        exit 0
        ;;
    --dev)
        install_suite "dev" "$TARGET_SCOPE"
        exit 0
        ;;
    --productivity)
        install_suite "productivity" "$TARGET_SCOPE"
        exit 0
        ;;
    --graphics)
        install_suite "graphics" "$TARGET_SCOPE"
        exit 0
        ;;
    --web)
        install_suite "web" "$TARGET_SCOPE"
        exit 0
        ;;
    --comms)
        install_suite "comms" "$TARGET_SCOPE"
        exit 0
        ;;
    --gaming)
        install_suite "gaming" "$TARGET_SCOPE"
        exit 0
        ;;
    install)
        if [ -z "$ACTION_PARAM" ]; then
            echo -e "${RED}❌ Error: Debes especificar un ID o alias de aplicación.${NC}"
            echo -e "Ejemplo: $0 install vlc $TARGET_SCOPE"
            exit 1
        fi
        resolved_id=$(resolve_app_id "$ACTION_PARAM")
        resolved_name=$(resolve_app_name "$resolved_id")
        ensure_flatpak_installed
        ensure_flathub_remote "$TARGET_SCOPE"
        install_single_app "$resolved_id" "$resolved_name" "$TARGET_SCOPE"
        exit 0
        ;;
    "")
        install_suite "default" "$TARGET_SCOPE"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $ACTION${NC}"
        show_help
        exit 1
        ;;
esac
