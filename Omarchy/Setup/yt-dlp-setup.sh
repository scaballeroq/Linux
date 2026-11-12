#!/usr/bin/env bash
# ==============================================================================
# yt-dlp-setup.sh - Instalación, Optimización y Diagnóstico Multimedia yt-dlp
# Sistema: Omarchy 4.5 ("Quattro RS") / Arch Linux | Escritorio: Hyprland (Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)
# ==============================================================================
# Características:
# - Despliegue nativo de yt-dlp, FFmpeg, aria2 y librerías de aceleración vía Pacman.
# - Detección y soporte dual de motores JS (Node.js nativo de Omarchy + Deno en Mise).
# - Aceleración de red con 8 fragmentos concurrentes (8C/16T) y soporte Brotli / curl_cffi.
# - Configuración global optimizada (~/.config/yt-dlp/config) con detección XDG dinámica.
# - Integración multimedia con MPV (VA-API / Vulkan) y Wayland (wl-paste ytclip).
# - Diagnóstico exhaustivo (--status), test de descifrado JS (--test), actualización (--update)
#   y limpieza selectiva de caché de tokens (--clean-cache).
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y PAQUETES DEL SISTEMA
# ------------------------------------------------------------------------------
CONFIG_DIR_REL=".config/yt-dlp"
CONFIG_FILE_REL=".config/yt-dlp/config"
SYSTEM_CONFIG="/etc/yt-dlp.conf"

# Paquetes requeridos y extensiones recomendadas en Omarchy / Arch Linux
REQUIRED_PACKAGES=(
    "yt-dlp"
    "ffmpeg"
    "aria2"
    "python-mutagen"
    "atomicparsley"
    "python-pycryptodomex"
    "python-secretstorage"
    "python-curl_cffi"
    "python-brotlicffi"
    "python-websockets"
)

# Colores ANSI para terminal
BOLD=$'\e[1m'
GREEN=$'\e[0;32m'
BLUE=$'\e[0;34m'
YELLOW=$'\e[1;33m'
RED=$'\e[0;31m'
CYAN=$'\e[0;36m'
MAGENTA=$'\e[0;35m'
NC=$'\e[0m'

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

get_download_dir() {
    local dl_dir=""
    if command -v xdg-user-dir &>/dev/null; then
        dl_dir=$(run_as_user xdg-user-dir DOWNLOAD 2>/dev/null || true)
    fi
    if [ -z "$dl_dir" ] || [ ! -d "$dl_dir" ]; then
        if [ -d "$USER_HOME/Downloads" ]; then
            dl_dir="$USER_HOME/Downloads"
        elif [ -d "$USER_HOME/Descargas" ]; then
            dl_dir="$USER_HOME/Descargas"
        else
            dl_dir="$USER_HOME/Downloads"
        fi
    fi
    echo "$dl_dir"
}

notify_desktop() {
    local title="$1"
    local message="$2"
    if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
        if command -v notify-send &>/dev/null; then
            run_as_user notify-send -a "Omarchy Multimedia" -i "video-x-generic" "$title" "$message" 2>/dev/null || true
        fi
    fi
}

# ------------------------------------------------------------------------------
# 3. FUNCIONES DE DETECCIÓN DE VERSIONES Y ESTADO
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

get_vaapi_status() {
    if ffmpeg -hwaccels 2>/dev/null | grep -q "vaapi"; then
        if [ -e "/dev/dri/renderD128" ]; then
            echo "Activo (AMD Radeon Vega 8 / VA-API)"
        else
            echo "Soportado por FFmpeg"
        fi
    else
        echo "No disponible"
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

get_node_version() {
    if command -v node &>/dev/null; then
        node -v 2>/dev/null || echo "Instalado"
    elif is_pkg_installed nodejs; then
        pacman -Q nodejs 2>/dev/null | awk '{print $2}'
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

get_pkg_version_or_status() {
    local pkg="$1"
    if is_pkg_installed "$pkg"; then
        pacman -Q "$pkg" 2>/dev/null | awk '{print $2}'
    else
        echo "No instalado"
    fi
}

# ------------------------------------------------------------------------------
# 4. DIAGNÓSTICO DETALLADO (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🎬 ${BOLD}DIAGNÓSTICO MULTIMEDIA YT-DLP - OMARCHY 4.5 (\"QUATTRO RS\")${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    echo -e "${CYAN}${BOLD}[1] Herramientas Multimedia Principales:${NC}"
    echo -n "  • yt-dlp:                   "
    local yt_v
    yt_v=$(get_ytdlp_version)
    if [ "$yt_v" != "No instalado" ]; then
        echo -e "${GREEN}✔ Instalado ($yt_v)${NC}"
    else
        echo -e "${RED}✘ No instalado${NC}"
    fi

    echo -n "  • FFmpeg:                   "
    local ff_v
    ff_v=$(get_ffmpeg_version)
    if [ "$ff_v" != "No instalado" ]; then
        echo -e "${GREEN}✔ Instalado ($ff_v)${NC}"
    else
        echo -e "${RED}✘ No instalado${NC}"
    fi

    echo -n "  • Aceleración VA-API (GPU): "
    local va_v
    va_v=$(get_vaapi_status)
    if [[ "$va_v" =~ "Activo" ]]; then
        echo -e "${GREEN}✔ $va_v${NC}"
    else
        echo -e "${YELLOW}ℹ $va_v${NC}"
    fi

    echo -n "  • aria2c (Descarga rápida): "
    local ar_v
    ar_v=$(get_aria2_version)
    if [ "$ar_v" != "No instalado" ]; then
        echo -e "${GREEN}✔ Instalado ($ar_v)${NC}"
    else
        echo -e "${YELLOW}✘ No instalado (opcional para multi-conexión con aria2)${NC}"
    fi

    echo ""
    echo -e "${CYAN}${BOLD}[2] Motores JavaScript (YouTube n-sig / PO Token Challenges):${NC}"
    echo -n "  • Node.js (Omarchy Nativo): "
    local no_v
    no_v=$(get_node_version)
    if [ "$no_v" != "No instalado" ]; then
        echo -e "${GREEN}✔ Operativo ($no_v)${NC}"
    else
        echo -e "${RED}✘ No instalado${NC}"
    fi

    echo -n "  • Deno (Runtime en Mise):   "
    local de_v
    de_v=$(get_deno_version)
    if [ "$de_v" != "No instalado" ]; then
        echo -e "${GREEN}✔ Configurado ($de_v)${NC}"
    else
        echo -e "${YELLOW}ℹ No configurado en Mise (Node.js asume resolución activa)${NC}"
    fi

    echo ""
    echo -e "${CYAN}${BOLD}[3] Librerías de Metadatos, Red y Descifrado (Python):${NC}"
    local py_pkgs=(
        "python-mutagen:Incrustación de etiquetas y carátulas de audio"
        "atomicparsley:Incrustación de miniaturas en contenedores M4A/MP4"
        "python-pycryptodomex:Descifrado de flujos protegidos AES-128 / HLS"
        "python-secretstorage:Acceso seguro a cookies de navegadores vía Keyring"
        "python-curl_cffi:Impersonación de navegador TLS/JA3 (anti-bloqueos 403)"
        "python-brotlicffi:Aceleración de descompresión Brotli en peticiones web"
        "python-websockets:Descarga de transmisiones y eventos vía WebSockets"
    )

    for item in "${py_pkgs[@]}"; do
        local pkg_name="${item%%:*}"
        local pkg_desc="${item##*:}"
        printf "  • %-26s" "$pkg_name:"
        local st
        st=$(get_pkg_version_or_status "$pkg_name")
        if [ "$st" != "No instalado" ]; then
            echo -e "${GREEN}✔ ($st) - $pkg_desc${NC}"
        else
            echo -e "${YELLOW}✘ No instalado - $pkg_desc${NC}"
        fi
    done

    echo ""
    echo -e "${CYAN}${BOLD}[4] Rutas y Archivos de Configuración:${NC}"
    echo -n "  • Configuración de Usuario: "
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}✔ Presente ($CONFIG_FILE)${NC}"
    else
        echo -e "${YELLOW}✘ No configurado (ejecuta con --config para desplegar)${NC}"
    fi

    echo -n "  • Configuración del Sistema: "
    if [ -f "$SYSTEM_CONFIG" ]; then
        echo -e "${GREEN}✔ Presente ($SYSTEM_CONFIG)${NC}"
    else
        echo -e "${YELLOW}ℹ No presente (opcional)${NC}"
    fi

    echo -n "  • Carpeta de Descargas:     "
    local dl_path
    dl_path=$(get_download_dir)
    echo -e "${BLUE}$dl_path${NC}"

    echo ""
    echo -e "${CYAN}${BOLD}[5] Integración de Shell Wayland (Bash.Setup):${NC}"
    if [ -f "$USER_HOME/Projects/Linux/Omarchy/Bash.Setup/yt-dlp_aliases.sh" ] || [ -f "$USER_HOME/.bashrc.d/yt-dlp_aliases.sh" ]; then
        echo -e "  • ${GREEN}✔ Aliases multimedia activos:${NC} ytvideo, ytaudio, ytopus, ytclip (wl-paste), ytplay (MPV VA-API)"
    else
        echo -e "  • ${YELLOW}ℹ Aliases disponibles en Bash.Setup/yt-dlp_aliases.sh${NC}"
    fi
    echo -e "${BOLD}=================================================================${NC}"
}

show_help() {
    cat << EOF
${BOLD}🎬 Gestor y Optimizador Multimedia yt-dlp - Omarchy 4.5 ("Quattro RS")${NC}
Plataforma: Arch Linux | Hyprland (Wayland) | AMD Ryzen 7 7730U (Vega 8)

Uso:
  $0 [OPCIÓN]

Opciones Principales:
  (sin argumentos)       Instalación completa de dependencias, Deno en Mise, configuración y diagnóstico.
  -i, --install          Instala o actualiza paquetes requeridos y complementos Python con Pacman.
  -c, --config           Genera o regenera ~/.config/yt-dlp/config con optimizaciones para Omarchy 4.5.
  -s, --status           Muestra diagnóstico visual del entorno: yt-dlp, FFmpeg, runtimes JS y librerías.
  -t, --test             Ejecuta prueba de extracción en vivo para validar resolución de desafíos JS.
  -u, --update           Actualiza paquetes con Pacman, actualiza Deno en Mise y limpia la caché.
  -k, --clean-cache      Limpia selectivamente la caché de tokens y descifrado (~/.cache/yt-dlp).
  -h, --help             Muestra este mensaje de ayuda.

Aliases útiles en Hyprland / Bash:
  ytvideo <URL>          Descarga vídeo 1080p con 8 fragmentos concurrentes
  ytaudio <URL>          Extrae audio MP3 en máxima fidelidad
  ytclip                 Descarga automáticamente el enlace copiado en el portapapeles Wayland
  ytplay <URL>           Streaming directo en MPV con aceleración por hardware VA-API / Vulkan
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
        echo -e "${GREEN}✔ Todos los paquetes multimedia y librerías de aceleración están instalados.${NC}"
        return 0
    fi

    echo -e "${BLUE}📦 Instalando paquetes multimedia faltantes vía Pacman: ${missing_packages[*]}...${NC}"
    $SUDO pacman -S --needed --noconfirm "${missing_packages[@]}"
}

setup_deno_mise() {
    local mise_cmd
    mise_cmd=$(get_mise_executable)
    if [ -z "$mise_cmd" ]; then
        echo -e "${YELLOW}ℹ Aviso: Mise no está instalado en el sistema. Node.js nativo asumirá la ejecución JS.${NC}"
        return 0
    fi

    echo -e "${BLUE}⚡ Verificando motor de JavaScript (Deno) mediante Mise...${NC}"
    if ! run_as_user "$mise_cmd" which deno &>/dev/null; then
        echo -e "${BLUE}⬇️ Instalando runtime Deno vía Mise para respaldo de yt-dlp...${NC}"
        run_as_user "$mise_cmd" use -g deno@latest || true
    else
        echo -e "${GREEN}✔ Deno ya está configurado en Mise ($(get_deno_version)).${NC}"
    fi
}

deploy_config() {
    local target_download_dir
    target_download_dir=$(get_download_dir)

    echo -e "${BLUE}⚙️ Desplegando archivo de configuración optimizado en $CONFIG_FILE...${NC}"
    run_as_user mkdir -p "$CONFIG_DIR"
    run_as_user mkdir -p "$target_download_dir"

    cat << EOF | run_as_user tee "$CONFIG_FILE" > /dev/null
# =============================================================================
# CONFIGURACIÓN GLOBAL DE YT-DLP - OMARCHY 4.5 ("QUATTRO RS")
# Estación de Trabajo: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Vega 8)
# Entorno Gráfico: Hyprland (Wayland) | Shell: Kitty / Bash
# =============================================================================

# Integración y rutas del sistema
--paths home:$target_download_dir
--paths temp:/tmp

# Nombres legibles, sanitizados y seguros para el sistema de archivos (btrfs/ext4)
--output "%(title).200B [%(id)s].%(ext)s"
--windows-filenames

# Concurrencia y aceleración de red (Optimizado para 8C/16T)
--concurrent-fragments 8
--retries 10
--fragment-retries 10
--downloader-args "aria2c:-c -j 8 -x 8 -s 8 -k 1M"

# Motores JavaScript para resolución de desafíos (YouTube n-sig / PO Token)
--js-runtimes node,deno

# Selección de formatos (hasta 1080p FHD óptimo para triple pantalla 1080p)
--format "bestvideo[height<=1080]+bestaudio/best[height<=1080]/best"
--merge-output-format mkv

# Procesamiento multihilo con FFmpeg (8 hilos en CPU AMD Ryzen 7 7730U)
--postprocessor-args "ffmpeg:-threads 8"

# Metadatos completos, miniaturas embebidas y capítulos
--embed-metadata
--embed-thumbnail
--embed-chapters

# Subtítulos incrustados (Español e Inglés, ignorando chats en directo)
--embed-subs
--sub-langs "es.*,en.*"
--compat-options no-live-chat

# Integración con reproductor y control de tiempo
--no-mtime
--sponsorblock-mark all

# Interfaz de usuario en terminal Kitty (Wayland)
--progress
--console-title
EOF

    if [ "$EUID" -eq 0 ] && [ "$REAL_USER" != "root" ]; then
        chown -R "$REAL_USER:$REAL_USER" "$CONFIG_DIR"
    fi

    echo -e "${GREEN}✔ Configuración aplicada con éxito (Descargas: $target_download_dir).${NC}"
}

clean_cache() {
    echo -e "${BLUE}🧹 Limpiando caché de yt-dlp...${NC}"
    if command -v yt-dlp &>/dev/null; then
        run_as_user yt-dlp --rm-cache-dir 2>/dev/null || true
    fi
    run_as_user rm -rf "$CACHE_DIR" 2>/dev/null || true
    echo -e "${GREEN}✔ Caché de yt-dlp limpiada correctamente.${NC}"
}

test_ytdlp() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🧪 PRUEBA DE FUNCIONAMIENTO DE YT-DLP Y MOTOR JS${NC}"
    echo -e "${CYAN}=================================================================${NC}"
    if ! command -v yt-dlp &>/dev/null; then
        echo -e "${RED}✘ yt-dlp no está instalado. Ejecuta primero '$0 --install'.${NC}"
        return 1
    fi

    echo -e "${BLUE}🔍 Extrayendo metadatos de prueba (YouTube n-sig / JS Challenge)...${NC}"
    local test_url="https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    local test_result
    if test_result=$(run_as_user yt-dlp --simulate --no-warnings --print "%(title)s [%(resolution)s]" "$test_url" 2>&1); then
        echo -e "${GREEN}✔ Extracción y descifrado JS exitoso:${NC}"
        echo -e "  ${BOLD}$test_result${NC}"
        notify_desktop "yt-dlp Omarchy" "Prueba de extracción y descifrado JS completada con éxito."
        return 0
    else
        echo -e "${RED}✘ Fallo en la prueba de extracción:${NC}"
        echo "$test_result"
        return 1
    fi
}

update_all() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔄 ACTUALIZACIÓN DE YT-DLP Y COMPONENTES MULTIMEDIA${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    echo -e "${BLUE}📦 Actualizando paquetes multimedia vía Pacman...${NC}"
    $SUDO pacman -S --needed --noconfirm "${REQUIRED_PACKAGES[@]}"

    local mise_cmd
    mise_cmd=$(get_mise_executable)
    if [ -n "$mise_cmd" ] && run_as_user "$mise_cmd" which deno &>/dev/null; then
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
    --install|-i|install)
        install_packages
        setup_deno_mise
        deploy_config
        show_status
        ;;
    --test|-t|test)
        test_ytdlp
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
        echo -e "${BOLD}🎬 CONFIGURADOR MULTIMEDIA YT-DLP - OMARCHY 4.5 (\"QUATTRO RS\")${NC}"
        echo -e "${CYAN}=================================================================${NC}"
        install_packages
        setup_deno_mise
        deploy_config
        echo ""
        show_status
        echo ""
        test_ytdlp
        ;;
    *)
        echo -e "${RED}❌ Opción desconocida: '$1'${NC}\n" >&2
        show_help
        exit 1
        ;;
esac
