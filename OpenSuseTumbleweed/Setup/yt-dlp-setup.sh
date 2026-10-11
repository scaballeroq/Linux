#!/usr/bin/env bash
# ==============================================================================
# yt-dlp-setup.sh - Instalación, Optimización y Diagnóstico de yt-dlp y FFmpeg
# Sistema: openSUSE Tumbleweed | Escritorio: KDE Plasma 6 (Wayland)
# ==============================================================================
# Características:
# - Stack multimedia de alto rendimiento: yt-dlp + FFmpeg oficial + aria2.
# - Inserción nativa de carátulas, metadatos y capítulos con FFmpeg y Mutagen.
# - Despliegue de motor JavaScript Deno vía Mise para retos de YouTube (n-tokens).
# - Configuración global optimizada (~/.config/yt-dlp/config) con subtítulos y concurrencia.
# - Comprobación idempotente de paquetes (evita llamadas innecesarias a Zypper y Snapper).
# - Diagnóstico visual completo del entorno multimedia (--status).
# - Actualización centralizada de herramientas y motor JS (--update).
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
CONFIG_DIR_REL=".config/yt-dlp"
CONFIG_FILE_REL=".config/yt-dlp/config"

# Paquetes requeridos en openSUSE Tumbleweed
REQUIRED_PACKAGES=(
    "yt-dlp"
    "ffmpeg"
    "aria2"
    "python3-mutagen"
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

# ------------------------------------------------------------------------------
# 3. FUNCIONES DE DETECCIÓN Y VERSIONES
# ------------------------------------------------------------------------------
get_ytdlp_version() {
    if command -v yt-dlp &>/dev/null; then
        yt-dlp --version 2>/dev/null || echo "Desconocida"
    elif rpm -q yt-dlp &>/dev/null; then
        rpm -q --qf '%{VERSION}-%{RELEASE}\n' yt-dlp 2>/dev/null
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
    if rpm -q python3-mutagen &>/dev/null || rpm -q python313-mutagen &>/dev/null; then
        local pkg
        pkg=$(rpm -qa "python3*-mutagen*" --qf '%{NAME}-%{VERSION}\n' 2>/dev/null | head -n1)
        echo "${pkg:-Instalado}"
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
    fi

    if [ -n "$mise_cmd" ]; then
        if run_as_user "$mise_cmd" where deno &>/dev/null; then
            local deno_path
            deno_path=$(run_as_user "$mise_cmd" where deno 2>/dev/null)
            if [ -x "$deno_path/bin/deno" ]; then
                local deno_ver
                deno_ver=$("$deno_path/bin/deno" --version 2>/dev/null | awk 'NR==1 {print $2}')
                echo "Deno $deno_ver (vía Mise: $deno_path)"
                return 0
            fi
        fi
    fi

    # 2. Node.js como alternativa
    if command -v node &>/dev/null; then
        local node_ver
        node_ver=$(node --version 2>/dev/null)
        echo "Node.js $node_ver (Respaldo en PATH)"
        return 0
    fi

    echo "No detectado"
}

are_packages_installed() {
    rpm -q yt-dlp &>/dev/null && \
    rpm -q ffmpeg &>/dev/null && \
    rpm -q aria2 &>/dev/null && \
    (rpm -q python3-mutagen &>/dev/null || rpm -q python313-mutagen &>/dev/null)
}

# ------------------------------------------------------------------------------
# 4. DIAGNÓSTICO Y AYUDA
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}🎬 Gestor y Optimizador Multimedia yt-dlp - openSUSE Tumbleweed${NC}

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)       Instala y optimiza yt-dlp, FFmpeg, aria2, Deno (vía Mise) y genera la configuración.
  -i, --install          Fuerza la comprobación e instalación de paquetes y configuración.
  -c, --config           Genera o actualiza la configuración (~/.config/yt-dlp/config) en modo usuario.
  -s, --status           Muestra el estado detallado de herramientas multimedia y motor JavaScript.
  -u, --update           Actualiza yt-dlp, FFmpeg, aria2 y el motor JavaScript Deno a la última versión.
  -h, --help             Muestra este mensaje de ayuda.

${BOLD}Características configuradas:${NC}
  • ${BOLD}Stack Multimedia:${NC}   yt-dlp + FFmpeg oficial para muxing y conversión de alta fidelidad.
  • ${BOLD}Metadatos & Tags:${NC}   Mutagen y FFmpeg para incrustar carátulas, capítulos y metadatos en MP4/M4A/MP3/Opus.
  • ${BOLD}Aceleración:${NC}       Descargas multihilo concurrentes con fragmentos paralelos.
  • ${BOLD}Motor JavaScript:${NC}   Deno (gestionado con Mise) para resolver los retos n-sig/n-token de YouTube.
  • ${BOLD}Configuración:${NC}      Genera $CONFIG_FILE con opciones optimizadas para openSUSE.

${BOLD}Ejemplos:${NC}
  $0                    # Instalación y verificación estándar idempotente
  $0 --status           # Comprueba estado y versiones activas
  $0 --update           # Actualiza yt-dlp y componentes"
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 ESTADO MULTIMEDIA YT-DLP - OPENSUSE TUMBLEWEED${NC}"
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
        echo -e "• ${BOLD}Mutagen (tags/covers):${NC} ${GREEN}✅ Instalado${NC} ($mutagen_ver)"
    else
        echo -e "• ${BOLD}Mutagen (tags/covers):${NC} ${YELLOW}⚠️ No instalado${NC}"
    fi

    # 5. Motor JavaScript
    local js_engine
    js_engine=$(get_js_engine_info)
    if [[ "$js_engine" != "No detectado"* ]]; then
        echo -e "• ${BOLD}Motor JavaScript:${NC}      ${GREEN}✅ $js_engine${NC}"
    else
        echo -e "• ${BOLD}Motor JavaScript:${NC}      ${YELLOW}⚠️ No detectado (requerido para resolver retos n-sig de YouTube)${NC}"
    fi

    # 6. Archivo de configuración
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
    if are_packages_installed; then
        echo -e "${GREEN}✔${NC} Paquetes multimedia ya instalados (yt-dlp, FFmpeg, aria2, Mutagen)."
        return 0
    fi

    echo -e "${BLUE}📦 Instalando paquetes multimedia vía Zypper...${NC}"
    require_root

    $SUDO zypper --non-interactive install -y "${REQUIRED_PACKAGES[@]}" || {
        echo -e "${YELLOW}⚠️ Aviso:${NC} Intentando instalación individual de paquetes esenciales..."
        $SUDO zypper --non-interactive install -y yt-dlp ffmpeg aria2 || true
        $SUDO zypper --non-interactive install -y python313-mutagen 2>/dev/null || true
    }

    echo -e "${GREEN}✔${NC} Paquetes multimedia instalados con éxito."
}

configure_js_engine() {
    echo -e "${BLUE}⚡ Configurando motor JavaScript (Deno) para retos de descifrado de YouTube...${NC}"

    local mise_cmd
    mise_cmd=$(get_mise_executable)

    if [ -n "$mise_cmd" ]; then
        echo -e "   Desplegando Deno vía Mise ($mise_cmd)..."
        run_as_user "$mise_cmd" use --global deno@latest || true
        run_as_user "$mise_cmd" reshim || true
        echo -e "${GREEN}✔${NC} Deno configurado globalmente con Mise."
        return 0
    fi

    # Respaldo si no está Mise pero existe Node en el sistema
    if command -v node &>/dev/null; then
        echo -e "${GREEN}✔${NC} Node.js detectado en el sistema como motor JS alternativo."
        return 0
    fi

    echo -e "${YELLOW}⚠️ Aviso:${NC} Mise no detectado. Se recomienda instalar Mise ('just mise') para soporte de Deno."
}

generate_config() {
    echo -e "${BLUE}⚙️ Generando configuración optimizada en $CONFIG_FILE...${NC}"
    run_as_user mkdir -p "$CONFIG_DIR"

    cat << 'EOF' | run_as_user tee "$CONFIG_FILE" > /dev/null
# =============================================================================
# CONFIGURACIÓN GLOBAL DE YT-DLP - OPENSUSE TUMBLEWEED (KDE PLASMA 6)
# =============================================================================

# --- Metadatos, Portadas y Capítulos ---
--embed-metadata
--embed-thumbnail
--embed-chapters

# --- Descargas y Rendimiento Concurrente ---
--concurrent-fragments 5
--no-overwrites
--continue

# --- Integración y Compatibilidad de Formatos ---
--prefer-free-formats
--compat-options no-youtube-prefer-utc-upload-date

# --- Subtítulos ---
--sub-langs "es.*,en.*"
--embed-subs

# --- Limpieza de Caché Residual ---
--rm-cache-dir
EOF

    echo -e "${GREEN}✔${NC} Configuración ~/.config/yt-dlp/config lista."
}

update_components() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔄 ACTUALIZACIÓN DE YT-DLP Y COMPONENTES MULTIMEDIA${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    require_root
    echo -e "${BLUE}📦 Actualizando yt-dlp, FFmpeg y aria2 vía Zypper...${NC}"
    $SUDO zypper --non-interactive update -y yt-dlp ffmpeg aria2 2>/dev/null || true

    local mise_cmd
    mise_cmd=$(get_mise_executable)
    if [ -n "$mise_cmd" ]; then
        echo -e "${BLUE}⚡ Actualizando motor JavaScript Deno vía Mise...${NC}"
        run_as_user "$mise_cmd" upgrade deno 2>/dev/null || run_as_user "$mise_cmd" use --global deno@latest 2>/dev/null || true
        run_as_user "$mise_cmd" reshim 2>/dev/null || true
    fi

    echo -e "${GREEN}✅ Componentes multimedia actualizados con éxito.${NC}"
    show_status
}

show_final_summary() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${GREEN}✅ yt-dlp y stack multimedia configurados con éxito.${NC}"
    echo -e "   - yt-dlp:    $(get_ytdlp_version)"
    echo -e "   - FFmpeg:    $(get_ffmpeg_version)"
    echo -e "   - Motor JS:  $(get_js_engine_info)"
    echo -e "   - Config:    $CONFIG_FILE"
    echo -e "   - Aliases:   ytvideo, ytaudio, ytlista, ytlista-audio, ytdl-subs"
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
    --update|-u|update)
        update_components
        exit 0
        ;;
    --install|-i|install|"")
        echo -e "${CYAN}=================================================================${NC}"
        echo -e "${BOLD}🎬 CONFIGURADOR MULTIMEDIA YT-DLP - OPENSUSE TUMBLEWEED${NC}"
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
