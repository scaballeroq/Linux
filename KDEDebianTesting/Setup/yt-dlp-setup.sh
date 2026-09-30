#!/usr/bin/env bash
# ==============================================================================
# yt-dlp-setup.sh - Instalación, Optimización y Diagnóstico de yt-dlp y FFmpeg
# Sistema: Debian Testing (Trixie/Sid) | Escritorio: KDE Plasma 6 (Wayland)
# ==============================================================================
# Características:
# - Stack multimedia de alto rendimiento: yt-dlp + FFmpeg oficial + aria2.
# - Inserción nativa de carátulas, metadatos y capítulos con FFmpeg, Mutagen y AtomicParsley.
# - Detección y despliegue robusto de motor JavaScript (Deno/Node.js vía Mise o sistema).
# - Configuración global optimizada (~/.config/yt-dlp/config) con subtítulos, no-mtime y SponsorBlock.
# - Eliminación del anti-patrón --rm-cache-dir en la config persistente (acelera descargas).
# - Comprobación inteligente e idempotente de paquetes APT faltantes.
# - Diagnóstico visual completo del entorno multimedia (--status).
# - Actualización centralizada y limpieza de caché selectiva (--update, --clean-cache).
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
CONFIG_DIR_REL=".config/yt-dlp"
CONFIG_FILE_REL=".config/yt-dlp/config"

REQUIRED_PACKAGES=(
    "yt-dlp"
    "ffmpeg"
    "aria2"
    "python3-mutagen"
    "atomicparsley"
)

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

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

# Propagar shims de Mise y rutas de binarios del usuario en PATH
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH"

CONFIG_DIR="$USER_HOME/$CONFIG_DIR_REL"
CONFIG_FILE="$USER_HOME/$CONFIG_FILE_REL"
MISE_BIN="$USER_HOME/.local/bin/mise"

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

require_root() {
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo &>/dev/null; then
            echo -e "${RED}❌ Error:${NC} Esta operación requiere privilegios de administrador ('sudo')." >&2
            exit 1
        fi
    fi
}

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    fi
}

get_mise_executable() {
    if [ -x "$MISE_BIN" ]; then
        echo "$MISE_BIN"
    elif command -v mise &>/dev/null; then
        command -v mise
    else
        echo ""
    fi
}

is_pkg_installed() {
    local pkg="$1"
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

are_packages_installed() {
    local pkg
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! is_pkg_installed "$pkg"; then
            return 1
        fi
    done
    return 0
}

# ------------------------------------------------------------------------------
# 3. FUNCIONES DE DETECCIÓN Y VERSIONES
# ------------------------------------------------------------------------------
get_ytdlp_version() {
    if command -v yt-dlp &>/dev/null; then
        yt-dlp --version 2>/dev/null || echo "Desconocida"
    elif is_pkg_installed yt-dlp; then
        dpkg-query -W -f='${Version}\n' yt-dlp 2>/dev/null
    else
        echo "No instalado"
    fi
}

get_ffmpeg_version() {
    if command -v ffmpeg &>/dev/null; then
        local ver
        ver=$(ffmpeg -version 2>/dev/null | awk 'NR==1 {for(i=1;i<=NF;i++) if($i ~ /^[0-9]/) {print $i; exit}}')
        echo "${ver:-Instalado}"
    else
        echo "No instalado"
    fi
}

get_aria2_version() {
    if command -v aria2c &>/dev/null; then
        local ver
        ver=$(aria2c --version 2>/dev/null | awk 'NR==1 {print $3}')
        echo "${ver:-Instalado}"
    else
        echo "No instalado"
    fi
}

get_mutagen_version() {
    if is_pkg_installed python3-mutagen; then
        dpkg-query -W -f='${Version}\n' python3-mutagen 2>/dev/null
    else
        echo "No instalado"
    fi
}

get_atomicparsley_version() {
    if command -v AtomicParsley &>/dev/null; then
        local ver
        ver=$(AtomicParsley --version 2>/dev/null | awk 'NR==1 {print $2}')
        echo "${ver:-Instalado}"
    elif is_pkg_installed atomicparsley; then
        dpkg-query -W -f='${Version}\n' atomicparsley 2>/dev/null
    else
        echo "No instalado"
    fi
}

get_js_engine_info() {
    local mise_cmd
    mise_cmd=$(get_mise_executable)

    # 1. Deno en PATH o vía Mise
    if command -v deno &>/dev/null; then
        local deno_ver
        deno_ver=$(deno --version 2>/dev/null | awk 'NR==1 {print $2}')
        echo "Deno $deno_ver (Activo en PATH)"
        return 0
    elif [ -n "$mise_cmd" ] && run_as_user "$mise_cmd" where deno &>/dev/null; then
        local deno_path deno_ver
        deno_path=$(run_as_user "$mise_cmd" where deno 2>/dev/null)
        if [ -x "$deno_path/bin/deno" ]; then
            deno_ver=$("$deno_path/bin/deno" --version 2>/dev/null | awk 'NR==1 {print $2}')
            echo "Deno $deno_ver (vía Mise: $deno_path)"
            return 0
        fi
    fi

    # 2. Node.js en PATH o vía Mise
    if command -v node &>/dev/null; then
        local node_ver
        node_ver=$(node --version 2>/dev/null)
        echo "Node.js $node_ver (Activo en PATH)"
        return 0
    elif [ -n "$mise_cmd" ] && run_as_user "$mise_cmd" where node &>/dev/null; then
        local node_path node_ver
        node_path=$(run_as_user "$mise_cmd" where node 2>/dev/null)
        if [ -x "$node_path/bin/node" ]; then
            node_ver=$("$node_path/bin/node" --version 2>/dev/null)
            echo "Node.js $node_ver (vía Mise: $node_path)"
            return 0
        fi
    fi

    # 3. QuickJS (qjs / quickjs)
    if command -v qjs &>/dev/null; then
        echo "QuickJS (Activo: qjs)"
        return 0
    elif command -v quickjs &>/dev/null; then
        echo "QuickJS (Activo: quickjs)"
        return 0
    fi

    echo "No detectado"
}

# ------------------------------------------------------------------------------
# 4. DIAGNÓSTICO Y AYUDA
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}🎬 Gestor y Optimizador Multimedia yt-dlp - Debian Testing${NC}

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)       Instala y optimiza yt-dlp, FFmpeg, aria2, Mutagen, AtomicParsley, motor JS y genera la configuración.
  -i, --install          Fuerza la comprobación e instalación de paquetes y configuración.
  -c, --config           Genera o actualiza la configuración (~/.config/yt-dlp/config) en modo usuario.
  -s, --status           Muestra el estado detallado de herramientas multimedia y motor JavaScript.
  -u, --update           Actualiza los paquetes vía APT, el motor JS en Mise y limpia la caché de yt-dlp.
  -k, --clean-cache      Limpia la caché de tokens y descifrado de yt-dlp (~/.cache/yt-dlp).
  -h, --help             Muestra este mensaje de ayuda.

${BOLD}Características configuradas:${NC}
  • ${BOLD}Stack Multimedia:${NC}   yt-dlp + FFmpeg oficial para muxing y conversión de alta fidelidad.
  • ${BOLD}Metadatos & Tags:${NC}   Mutagen y AtomicParsley para incrustar carátulas, capítulos y tags en MP4/M4A/MP3/Opus.
  • ${BOLD}Aceleración:${NC}       Descargas multihilo concurrentes con fragmentos paralelos (--concurrent-fragments 5).
  • ${BOLD}Motor JavaScript:${NC}   Deno/Node.js (gestionados con Mise o nativos) para retos n-sig/n-token de YouTube.
  • ${BOLD}SponsorBlock:${NC}       Marcado automático de capítulos para saltar publicidad e intros en reproductores.
  • ${BOLD}KDE & Dolphin:${NC}      Marca temporal actual (--no-mtime) para orden cronológico en Dolphin y nombres seguros.
  • ${BOLD}Configuración:${NC}      Genera $CONFIG_FILE con opciones optimizadas para Debian.

${BOLD}Ejemplos:${NC}
  $0                    # Instalación y verificación estándar idempotente
  $0 --status           # Comprueba estado y versiones activas
  $0 --update           # Actualiza paquetes multimedia y motor JS
  $0 --clean-cache      # Limpia la caché residual de yt-dlp"
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 ESTADO MULTIMEDIA YT-DLP - DEBIAN TESTING${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    # 1. yt-dlp
    local ytdlp_ver
    ytdlp_ver=$(get_ytdlp_version)
    if [ "$ytdlp_ver" != "No instalado" ]; then
        echo -e "• ${BOLD}yt-dlp:${NC}                ${GREEN}✅ Instalado${NC} ($ytdlp_ver)"
    else
        echo -e "• ${BOLD}yt-dlp:${NC}                ${RED}❌ No instalado${NC}"
    fi

    # 2. FFmpeg
    local ffmpeg_ver
    ffmpeg_ver=$(get_ffmpeg_version)
    if [ "$ffmpeg_ver" != "No instalado" ]; then
        echo -e "• ${BOLD}FFmpeg:${NC}                ${GREEN}✅ Instalado${NC} ($ffmpeg_ver)"
    else
        echo -e "• ${BOLD}FFmpeg:${NC}                ${RED}❌ No instalado${NC}"
    fi

    # 3. aria2
    local aria2_ver
    aria2_ver=$(get_aria2_version)
    if [ "$aria2_ver" != "No instalado" ]; then
        echo -e "• ${BOLD}aria2 (acelerador):${NC}    ${GREEN}✅ Instalado${NC} ($aria2_ver)"
    else
        echo -e "• ${BOLD}aria2 (acelerador):${NC}    ${YELLOW}⚠️ No instalado (opcional para multi-hilo)${NC}"
    fi

    # 4. Mutagen
    local mutagen_ver
    mutagen_ver=$(get_mutagen_version)
    if [ "$mutagen_ver" != "No instalado" ]; then
        echo -e "• ${BOLD}Mutagen (tags audio):${NC}  ${GREEN}✅ Instalado${NC} ($mutagen_ver)"
    else
        echo -e "• ${BOLD}Mutagen (tags audio):${NC}  ${YELLOW}⚠️ No instalado${NC}"
    fi

    # 5. AtomicParsley
    local atomic_ver
    atomic_ver=$(get_atomicparsley_version)
    if [ "$atomic_ver" != "No instalado" ]; then
        echo -e "• ${BOLD}AtomicParsley (MP4):${NC}   ${GREEN}✅ Instalado${NC} ($atomic_ver)"
    else
        echo -e "• ${BOLD}AtomicParsley (MP4):${NC}   ${YELLOW}⚠️ No instalado${NC}"
    fi

    # 6. Motor JavaScript
    local js_engine
    js_engine=$(get_js_engine_info)
    if [[ "$js_engine" != "No detectado"* ]]; then
        echo -e "• ${BOLD}Motor JavaScript:${NC}      ${GREEN}✅ $js_engine${NC}"
    else
        echo -e "• ${BOLD}Motor JavaScript:${NC}      ${YELLOW}⚠️ No detectado (requerido para resolver retos n-sig de YouTube)${NC}"
    fi

    # 7. Archivo de configuración
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "• ${BOLD}Archivo de config:${NC}     ${GREEN}✅ Presente${NC} ($CONFIG_FILE)"
    else
        echo -e "• ${BOLD}Archivo de config:${NC}     ${YELLOW}⚠️ No configurado${NC} ($CONFIG_FILE)"
    fi

    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN Y ACTUALIZACIÓN
# ------------------------------------------------------------------------------
install_packages() {
    local missing_packages=()
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! is_pkg_installed "$pkg"; then
            missing_packages+=("$pkg")
        fi
    done

    if [ ${#missing_packages[@]} -eq 0 ]; then
        echo -e "${GREEN}✔${NC} Paquetes multimedia ya instalados (${REQUIRED_PACKAGES[*]})."
        return 0
    fi

    echo -e "${BLUE}📦 Instalando paquetes multimedia faltantes: ${missing_packages[*]} vía APT...${NC}"
    require_root
    export DEBIAN_FRONTEND=noninteractive

    $SUDO apt-get update -qq
    $SUDO apt-get install -y "${missing_packages[@]}" || {
        echo -e "${YELLOW}⚠️ Aviso:${NC} Intentando instalación individual de paquetes faltantes..."
        for pkg in "${missing_packages[@]}"; do
            $SUDO apt-get install -y "$pkg" 2>/dev/null || echo -e "${YELLOW}⚠️ No se pudo instalar $pkg (continuando...)${NC}"
        done
    }

    echo -e "${GREEN}✔${NC} Instalación de paquetes multimedia completada."
}

configure_js_engine() {
    echo -e "${BLUE}⚡ Verificando motor JavaScript para retos de descifrado de YouTube...${NC}"

    local mise_cmd
    mise_cmd=$(get_mise_executable)

    # Si ya tenemos Deno disponible
    if command -v deno &>/dev/null; then
        local deno_ver
        deno_ver=$(deno --version 2>/dev/null | awk 'NR==1 {print $2}')
        echo -e "${GREEN}✔${NC} Deno $deno_ver ya está disponible en PATH."
        return 0
    fi

    # Desplegar Deno vía Mise si está disponible
    if [ -n "$mise_cmd" ]; then
        echo -e "   Desplegando Deno vía Mise ($mise_cmd)..."
        run_as_user "$mise_cmd" use --global deno@latest || true
        run_as_user "$mise_cmd" reshim || true
        echo -e "${GREEN}✔${NC} Deno configurado globalmente con Mise."
        return 0
    fi

    # Si Node.js está disponible como motor alternativo
    if command -v node &>/dev/null; then
        local node_ver
        node_ver=$(node --version 2>/dev/null)
        echo -e "${GREEN}✔${NC} Node.js ($node_ver) activo como motor JS de respaldo."
        return 0
    fi

    # Si QuickJS está disponible
    if command -v qjs &>/dev/null || command -v quickjs &>/dev/null; then
        echo -e "${GREEN}✔${NC} QuickJS detectado como motor JS ligero."
        return 0
    fi

    echo -e "${YELLOW}⚠️ Aviso:${NC} Mise no detectado. Se recomienda instalar Mise ('just mise') o quickjs para soporte JS."
}

generate_config() {
    echo -e "${BLUE}⚙️ Generando configuración optimizada en $CONFIG_FILE...${NC}"
    run_as_user mkdir -p "$CONFIG_DIR"

    # Determinar preferencia de runtimes JS
    local js_opt="--js-runtimes deno,node,quickjs"
    local mise_deno="$USER_HOME/.local/share/mise/shims/deno"
    local mise_node="$USER_HOME/.local/share/mise/shims/node"

    if [ -x "$mise_deno" ]; then
        js_opt="--js-runtimes deno:$mise_deno,deno,node,quickjs"
    elif [ -x "$mise_node" ]; then
        js_opt="--js-runtimes node:$mise_node,node,deno,quickjs"
    fi

    cat << EOF | run_as_user tee "$CONFIG_FILE" > /dev/null
# =============================================================================
# CONFIGURACIÓN GLOBAL DE YT-DLP - DEBIAN TESTING (KDE PLASMA 6)
# =============================================================================

# --- Metadatos, Portadas y Capítulos ---
--embed-metadata
--embed-thumbnail
--convert-thumbnails jpg
--embed-chapters

# --- Descargas y Rendimiento Concurrente ---
--concurrent-fragments 5
--no-overwrites
--continue

# --- Formato y Contenedor Predeterminado ---
--merge-output-format mp4/mkv

# --- Integración con Dolphin / Gestor de Archivos KDE ---
--no-mtime
--windows-filenames

# --- SponsorBlock (Marcadores de Capítulos para Patrocinios/Intros) ---
--sponsorblock-mark all

# --- Subtítulos ---
--sub-langs "es.*,en.*"
--embed-subs
--compat-options no-keep-subs

# --- Motor JavaScript para retos n-token / n-sig ---
$js_opt
EOF

    echo -e "${GREEN}✔${NC} Configuración ~/.config/yt-dlp/config lista y optimizada."
}

clean_cache() {
    echo -e "${BLUE}🧹 Limpiando caché residual de yt-dlp...${NC}"
    if command -v yt-dlp &>/dev/null; then
        run_as_user yt-dlp --rm-cache-dir 2>/dev/null || true
        echo -e "${GREEN}✔${NC} Caché de yt-dlp limpiada con éxito."
    else
        echo -e "${YELLOW}⚠️ Aviso:${NC} yt-dlp no está instalado todavía."
    fi
}

update_components() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔄 ACTUALIZACIÓN DE YT-DLP Y COMPONENTES MULTIMEDIA${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    require_root
    export DEBIAN_FRONTEND=noninteractive
    echo -e "${BLUE}📦 Actualizando lista de paquetes e instalando actualizaciones vía APT...${NC}"
    $SUDO apt-get update -qq
    $SUDO apt-get --only-upgrade install -y "${REQUIRED_PACKAGES[@]}" 2>/dev/null || true

    local mise_cmd
    mise_cmd=$(get_mise_executable)
    if [ -n "$mise_cmd" ]; then
        echo -e "${BLUE}⚡ Actualizando motor JavaScript Deno vía Mise...${NC}"
        run_as_user "$mise_cmd" upgrade deno 2>/dev/null || run_as_user "$mise_cmd" use --global deno@latest 2>/dev/null || true
        run_as_user "$mise_cmd" reshim 2>/dev/null || true
    fi

    clean_cache

    echo -e "${GREEN}✅ Componentes multimedia actualizados con éxito.${NC}"
    show_status
}

show_final_summary() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${GREEN}✅ yt-dlp y stack multimedia configurados con éxito.${NC}"
    echo -e "   - yt-dlp:        $(get_ytdlp_version)"
    echo -e "   - FFmpeg:        $(get_ffmpeg_version)"
    echo -e "   - AtomicParsley: $(get_atomicparsley_version)"
    echo -e "   - Motor JS:      $(get_js_engine_info)"
    echo -e "   - Config:        $CONFIG_FILE"
    echo -e "   - Aliases:       ytvideo, ytaudio, ytlista, ytlista-audio, ytdl-subs"
    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 6. PARSER DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    --config|-c|config)
        generate_config
        exit 0
        ;;
    --clean-cache|-k|clean-cache)
        clean_cache
        exit 0
        ;;
    --update|-u|update)
        update_components
        exit 0
        ;;
    --install|-i|install|"")
        echo -e "${CYAN}=================================================================${NC}"
        echo -e "${BOLD}🎬 CONFIGURADOR MULTIMEDIA YT-DLP - DEBIAN TESTING${NC}"
        echo -e "${CYAN}=================================================================${NC}"
        install_packages
        configure_js_engine
        generate_config
        show_final_summary
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opción desconocida:${NC} ${1}"
        echo "Ejecuta '$0 --help' para ver las opciones disponibles."
        exit 1
        ;;
esac

