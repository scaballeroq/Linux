#!/usr/bin/env bash
# ==============================================================================
# yt-dlp-setup.sh - Instalación, Optimización y Diagnóstico de yt-dlp y FFmpeg
# Sistema: Omarchy / Arch Linux | Escritorio: Hyprland (Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# ==============================================================================
# Características:
# - Despliegue nativo de yt-dlp, FFmpeg, aria2 y librerías de metadatos vía Pacman.
# - Integración y gestión de Deno mediante Mise para soporte de cifrado JavaScript.
# - Configuración global optimizada (~/.config/yt-dlp/config) con subtítulos, no-mtime y SponsorBlock.
# - Diagnóstico visual completo del entorno multimedia (--status).
# - Actualización centralizada y limpieza de caché selectiva (--update, --clean-cache).
# - Opciones CLI: --status, --config, --update, --clean-cache, --help.
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
    "python-mutagen"
    "atomicparsley"
    "python-pycryptodomex"
    "python-secretstorage"
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
# 2. DETECCIÓN DE USUARIO Y RUTAS
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
CACHE_DIR="$USER_HOME/.cache/yt-dlp"
MISE_BIN="$USER_HOME/.local/bin/mise"

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

run_as_user() {
    if [ "$EUID" -eq 0 ] && [ "$REAL_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" USER="$REAL_USER" PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/local/bin:/usr/bin:$PATH" "$@"
    else
        "$@"
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
    pacman -Q "$pkg" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# 3. FUNCIONES DE DETECCIÓN Y VERSIONES
# ------------------------------------------------------------------------------
get_ytdlp_version() {
    if command -v yt-dlp &>/dev/null; then
        yt-dlp --version 2>/dev/null || echo "Desconocida"
    elif is_pkg_installed yt-dlp; then
        pacman -Q yt-dlp 2>/dev/null | awk '{print $2}'
    else
        echo "No instalado"
    fi
}

get_ffmpeg_version() {
    if command -v ffmpeg &>/dev/null; then
        ffmpeg -version 2>/dev/null | head -n1 | awk '{print $3}' || echo "Desconocida"
    elif is_pkg_installed ffmpeg; then
        pacman -Q ffmpeg 2>/dev/null | awk '{print $2}'
    else
        echo "No instalado"
    fi
}

get_aria2_version() {
    if command -v aria2c &>/dev/null; then
        aria2c --version 2>/dev/null | head -n1 | awk '{print $3}' || echo "Desconocida"
    elif is_pkg_installed aria2; then
        pacman -Q aria2 2>/dev/null | awk '{print $2}'
    else
        echo "No instalado"
    fi
}

get_mutagen_version() {
    if is_pkg_installed python-mutagen; then
        pacman -Q python-mutagen 2>/dev/null | awk '{print $2}'
    else
        echo "No instalado"
    fi
}

get_atomicparsley_version() {
    if is_pkg_installed atomicparsley; then
        pacman -Q atomicparsley 2>/dev/null | awk '{print $2}'
    elif command -v AtomicParsley &>/dev/null; then
        echo "Instalado"
    else
        echo "No instalado"
    fi
}

get_deno_version() {
    local mise_cmd
    mise_cmd=$(get_mise_executable)
    if [ -n "$mise_cmd" ] && run_as_user "$mise_cmd" which deno &>/dev/null; then
        local deno_path
        deno_path=$(run_as_user "$mise_cmd" which deno 2>/dev/null)
        "$deno_path" --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "Instalado (Mise)"
    elif command -v deno &>/dev/null; then
        deno --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "Instalado (Sistema)"
    else
        echo "No instalado"
    fi
}

# ------------------------------------------------------------------------------
# 4. DIAGNÓSTICO Y AYUDA
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🎬 ${BOLD}DIAGNÓSTICO DEL ENTORNO YT-DLP - OMARCHY WORKSTATION${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    echo -n "• yt-dlp:                     "
    local yt_v
    yt_v=$(get_ytdlp_version)
    if [ "$yt_v" != "No instalado" ]; then
        echo -e "${GREEN}✔ Instalado ($yt_v)${NC}"
    else
        echo -e "${RED}✘ No instalado${NC}"
    fi

    echo -n "• FFmpeg:                     "
    local ff_v
    ff_v=$(get_ffmpeg_version)
    if [ "$ff_v" != "No instalado" ]; then
        echo -e "${GREEN}✔ Instalado ($ff_v)${NC}"
    else
        echo -e "${RED}✘ No instalado${NC}"
    fi

    echo -n "• aria2c:                     "
    local ar_v
    ar_v=$(get_aria2_version)
    if [ "$ar_v" != "No instalado" ]; then
        echo -e "${GREEN}✔ Instalado ($ar_v)${NC}"
    else
        echo -e "${YELLOW}✘ No instalado (opcional para descargas multi-hilo)${NC}"
    fi

    echo -n "• python-mutagen:             "
    local mu_v
    mu_v=$(get_mutagen_version)
    if [ "$mu_v" != "No instalado" ]; then
        echo -e "${GREEN}✔ Instalado ($mu_v)${NC}"
    else
        echo -e "${YELLOW}✘ No instalado${NC}"
    fi

    echo -n "• AtomicParsley:              "
    local ap_v
    ap_v=$(get_atomicparsley_version)
    if [ "$ap_v" != "No instalado" ]; then
        echo -e "${GREEN}✔ Instalado ($ap_v)${NC}"
    else
        echo -e "${YELLOW}✘ No instalado${NC}"
    fi

    echo -n "• Deno (JS Engine en Mise):   "
    local de_v
    de_v=$(get_deno_version)
    if [ "$de_v" != "No instalado" ]; then
        echo -e "${GREEN}✔ Configurado ($de_v)${NC}"
    else
        echo -e "${YELLOW}✘ No detectado${NC}"
    fi

    echo -n "• Archivo de configuración:   "
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}✔ Presente ($CONFIG_FILE)${NC}"
    else
        echo -e "${YELLOW}✘ No configurado${NC}"
    fi
    echo -e "${BOLD}=================================================================${NC}"
}

show_help() {
    cat << EOF
${BOLD}🎬 Gestor y Optimizador Multimedia yt-dlp - Omarchy Workstation (Hyprland)${NC}

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala dependencias con Pacman, motor Deno en Mise y despliega configuración.
  -c, --config           Genera o actualiza la configuración (~/.config/yt-dlp/config) en modo usuario.
  -s, --status           Muestra el estado detallado de herramientas multimedia y motor JavaScript.
  -u, --update           Actualiza los paquetes vía Pacman, el motor JS en Mise y limpia la caché.
  -k, --clean-cache      Limpia la caché de tokens y descifrado de yt-dlp (~/.cache/yt-dlp).
  -h, --help             Muestra este mensaje de ayuda.
EOF
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
        echo -e "${GREEN}✔ Paquetes multimedia ya instalados (${REQUIRED_PACKAGES[*]}).${NC}"
        return 0
    fi

    echo -e "${BLUE}📦 Instalando paquetes multimedia faltantes vía Pacman: ${missing_packages[*]}...${NC}"
    $SUDO pacman -S --needed --noconfirm "${missing_packages[@]}" 2>/dev/null || {
        for pkg in "${missing_packages[@]}"; do
            $SUDO pacman -S --needed --noconfirm "$pkg" 2>/dev/null || true
        done
    }
}

setup_deno_mise() {
    local mise_cmd
    mise_cmd=$(get_mise_executable)
    if [ -z "$mise_cmd" ]; then
        echo -e "${YELLOW}⚠️ Aviso: Mise no está instalado en el sistema. Omitiendo instalación de Deno.${NC}"
        return 0
    fi

    echo -e "${BLUE}⚡ Verificando motor de JavaScript (Deno) mediante Mise...${NC}"
    if ! run_as_user "$mise_cmd" which deno &>/dev/null; then
        echo -e "${BLUE}⬇️ Instalando runtime Deno vía Mise...${NC}"
        run_as_user "$mise_cmd" use -g deno@latest || true
    else
        echo -e "${GREEN}✔ Deno ya está configurado en Mise ($(get_deno_version)).${NC}"
    fi
}

deploy_config() {
    echo -e "${BLUE}⚙️ Desplegando archivo de configuración optimizado en $CONFIG_FILE...${NC}"
    run_as_user mkdir -p "$CONFIG_DIR"

    cat << 'EOF' | run_as_user tee "$CONFIG_FILE" > /dev/null
# =============================================================================
# CONFIGURACIÓN GLOBAL DE YT-DLP - OMARCHY WORKSTATION (Hyprland SHELL)
# =============================================================================

# Integración y ruta de descarga
--paths home:~/Descargas
--paths temp:/tmp

# Nombres legibles y ordenados
--output "%(title)s [%(id)s].%(ext)s"

# Selección de formatos (hasta 1080p con mejor audio)
--format "bestvideo[height<=1080]+bestaudio/best[height<=1080]/best"
--merge-output-format mkv

# Metadatos, miniaturas y subtítulos
--embed-metadata
--embed-thumbnail
--embed-subs
--sub-langs "es.*,en.*"

# Limpieza y compatibilidad
--no-mtime
--sponsorblock-mark all
--downloader-args "aria2c:-c -j 8 -x 8 -s 8 -k 1M"
EOF

    echo -e "${GREEN}✔ Configuración aplicada con éxito.${NC}"
}

clean_cache() {
    echo -e "${BLUE}🧹 Limpiando caché de yt-dlp...${NC}"
    if command -v yt-dlp &>/dev/null; then
        run_as_user yt-dlp --rm-cache-dir 2>/dev/null || true
    fi
    run_as_user rm -rf "$CACHE_DIR" 2>/dev/null || true
    echo -e "${GREEN}✔ Caché de yt-dlp limpiada correctamente.${NC}"
}

update_all() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔄 ACTUALIZACIÓN DE YT-DLP Y COMPONENTES MULTIMEDIA${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    echo -e "${BLUE}📦 Actualizando paquetes multimedia vía Pacman...${NC}"
    $SUDO pacman -S --needed --noconfirm "${REQUIRED_PACKAGES[@]}" 2>/dev/null || true

    local mise_cmd
    mise_cmd=$(get_mise_executable)
    if [ -n "$mise_cmd" ]; then
        echo -e "${BLUE}⚡ Actualizando motor JavaScript Deno vía Mise...${NC}"
        run_as_user "$mise_cmd" upgrade deno 2>/dev/null || true
    fi

    clean_cache
    echo -e "${GREEN}✅ Actualización de componentes multimedia completada.${NC}"
}

# ------------------------------------------------------------------------------
# 6. DESPACHADOR DE COMANDOS
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        ;;
    --config|-c|config)
        deploy_config
        ;;
    --update|-u|update)
        update_all
        show_status
        ;;
    --clean-cache|-k|clean-cache)
        clean_cache
        ;;
    --help|-h|help)
        show_help
        ;;
    "")
        echo -e "${CYAN}=================================================================${NC}"
        echo -e "${BOLD}🎬 CONFIGURADOR MULTIMEDIA YT-DLP - OMARCHY WORKSTATION${NC}"
        echo -e "${CYAN}=================================================================${NC}"
        install_packages
        setup_deno_mise
        deploy_config
        echo ""
        show_status
        ;;
    *)
        echo -e "${RED}❌ Opción desconocida: '$1'${NC}\n" >&2
        show_help
        exit 1
        ;;
esac
