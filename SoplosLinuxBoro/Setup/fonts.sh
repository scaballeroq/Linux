#!/usr/bin/env bash
# ==============================================================================
# fonts.sh - Instalación, Verificación y Gestión de Fuentes de Desarrollo (Nerd Fonts)
# Sistema: Soplos Linux Boro | Escritorio: GNOME Shell (Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# ==============================================================================
# Características y Optimizaciones:
# - Soporte para fuentes de desarrollo con ligaduras y glifos Nerd Fonts:
#   * JetBrainsMono (predeterminada en Ghostty, Neovim, GNOME Shell e IDEs)
#   * FiraCode (ligaduras completas de programación)
#   * CascadiaCode / CaskaydiaCove (estilo moderno con ligaduras)
#   * Meslo (optimizada para prompts CLI: Starship, Powerlevel10k)
#   * Hack (monoespacio clásico de alta legibilidad)
#   * GeistMono, CommitMono, VictorMono, SourceCodePro, Monaspace, Iosevka.
# - Detección inteligente recursiva y resiliente en $XDG_DATA_HOME/fonts (~/.local/share/fonts).
# - Descargas seguras atómicas: staging en directorio temporal antes de aplicar en destino.
# - Purga automática de artefactos no tipográficos (*.txt, *.md, LICENSE*) y variantes
#   redundantes de Windows para ahorrar hasta 50% de espacio en disco.
# - Integración con GNOME Shell Wayland (--set-gnome) para configurar tipografía monospace.
# - Soporte completo de banderas CLI: --status, --list, --clean, --clean-windows,
#   --update-cache, --remove, --dry-run, --set-gnome, --force, --help.
# - Modo rootless estricto: ejecución con privilegios de usuario real, invocando sudo
#   únicamente si faltan paquetes esenciales de sistema (curl, unzip, fontconfig).
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO, ENTORNO Y PERMISOS
# ------------------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")
XDG_DATA_HOME="${XDG_DATA_HOME:-$USER_HOME/.local/share}"
FONT_DIR="$XDG_DATA_HOME/fonts"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="/usr/local/bin:/usr/bin:/bin:$USER_HOME/.local/bin:$PATH" \
            XDG_DATA_HOME="$XDG_DATA_HOME" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 2. COLORES Y UTILIDADES DE SALIDA
# ------------------------------------------------------------------------------
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    NC=''
fi

log_info()    { echo -e "${CYAN}ℹ️  $*${NC}"; }
log_success() { echo -e "${GREEN}✅ $*${NC}"; }
log_warn()    { echo -e "${YELLOW}⚠️  $*${NC}"; }
log_error()   { echo -e "${RED}❌ $*${NC}"; }
log_step()    { echo -e "${BLUE}▶  $*${NC}"; }

# ------------------------------------------------------------------------------
# 3. RECURSOS TEMPORALES Y LIMPIEZA
# ------------------------------------------------------------------------------
TMP_DIR=""
INSTALLED_ANY=false

cleanup() {
    if [ -n "${TMP_DIR:-}" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR" 2>/dev/null || run_as_user rm -rf "$TMP_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

ensure_tmp_dir() {
    if [ -z "$TMP_DIR" ] || [ ! -d "$TMP_DIR" ]; then
        TMP_DIR=$(run_as_user mktemp -d "/tmp/nerd-fonts-XXXXXX")
    fi
}

# ------------------------------------------------------------------------------
# 4. VERIFICACIÓN DE DEPENDENCIAS DEL SISTEMA
# ------------------------------------------------------------------------------
ensure_dependencies() {
    local missing=()
    for cmd in curl unzip fc-cache fc-list; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_warn "Dependencias faltantes detectadas: ${missing[*]}"
        log_info "Instalando paquetes requeridos (curl, unzip, fontconfig) vía APT..."
        if [ "$EUID" -ne 0 ]; then
            if ! command -v sudo &>/dev/null; then
                log_error "Se requiere 'sudo' para instalar las dependencias faltantes."
                exit 1
            fi
            sudo apt-get update -qq
            sudo apt-get install -y curl unzip fontconfig
        else
            apt-get update -qq
            apt-get install -y curl unzip fontconfig
        fi
    fi
}

# ------------------------------------------------------------------------------
# 5. METADATOS Y NORMALIZACIÓN DE FUENTES
# ------------------------------------------------------------------------------
DEFAULT_FONTS=("JetBrainsMono" "FiraCode" "CascadiaCode" "Meslo" "Hack")
EXTENDED_FONTS=("GeistMono" "CommitMono" "VictorMono" "SourceCodePro" "Monaspace" "Iosevka")

normalize_font_name() {
    local input="$1"
    local lower="${input,,}"
    lower="${lower//[-_]/}"
    case "$lower" in
        jetbrains|jetbrainsmono|jbm)
            echo "JetBrainsMono"
            ;;
        fira|firacode)
            echo "FiraCode"
            ;;
        cascadia|cascadiacode|caskaydia|caskaydiacove)
            echo "CascadiaCode"
            ;;
        meslo|meslolgs|meslolg)
            echo "Meslo"
            ;;
        hack)
            echo "Hack"
            ;;
        geist|geistmono)
            echo "GeistMono"
            ;;
        victor|victormono)
            echo "VictorMono"
            ;;
        commit|commitmono)
            echo "CommitMono"
            ;;
        sourcecode|sourcecodepro|saucecode|saucecodepro)
            echo "SourceCodePro"
            ;;
        monaspace|monaspice)
            echo "Monaspace"
            ;;
        iosevka)
            echo "Iosevka"
            ;;
        *)
            echo "$input"
            ;;
    esac
}

get_font_meta() {
    local font="$1"
    case "$font" in
        JetBrainsMono)
            FONT_ARCHIVE="JetBrainsMono.zip"
            FONT_PATTERNS=("*JetBrainsMono*")
            FONT_FC_FAMILY="JetBrainsMono Nerd Font"
            FONT_DESC="Predeterminada para Ghostty, Neovim e IDEs (ligaduras completas)"
            ;;
        FiraCode)
            FONT_ARCHIVE="FiraCode.zip"
            FONT_PATTERNS=("*FiraCode*")
            FONT_FC_FAMILY="FiraCode Nerd Font"
            FONT_DESC="Diseño con ricas ligaduras de programación avanzadas"
            ;;
        CascadiaCode|CaskaydiaCove)
            FONT_ARCHIVE="CascadiaCode.zip"
            FONT_PATTERNS=("*Caskaydia*" "*Cascadia*")
            FONT_FC_FAMILY="CaskaydiaCove Nerd Font"
            FONT_DESC="Estilo Windows Terminal / VS Code moderno con ligaduras"
            ;;
        Meslo)
            FONT_ARCHIVE="Meslo.zip"
            FONT_PATTERNS=("*Meslo*")
            FONT_FC_FAMILY="MesloLGS Nerd Font"
            FONT_DESC="Optimizada para prompts CLI (Starship, Powerlevel10k)"
            ;;
        Hack)
            FONT_ARCHIVE="Hack.zip"
            FONT_PATTERNS=("*Hack*")
            FONT_FC_FAMILY="Hack Nerd Font"
            FONT_DESC="Monoespaciada de alta legibilidad para terminal"
            ;;
        GeistMono)
            FONT_ARCHIVE="GeistMono.zip"
            FONT_PATTERNS=("*GeistMono*")
            FONT_FC_FAMILY="GeistMono Nerd Font"
            FONT_DESC="Diseño geométrico limpio y moderno (Vercel)"
            ;;
        VictorMono)
            FONT_ARCHIVE="VictorMono.zip"
            FONT_PATTERNS=("*VictorMono*")
            FONT_FC_FAMILY="VictorMono Nerd Font"
            FONT_DESC="Monoespacio elegante con cursiva caligráfica para comentarios"
            ;;
        CommitMono)
            FONT_ARCHIVE="CommitMono.zip"
            FONT_PATTERNS=("*CommitMono*")
            FONT_FC_FAMILY="CommitMono Nerd Font"
            FONT_DESC="Monoespacio neutral altamente optimizado para código"
            ;;
        SourceCodePro)
            FONT_ARCHIVE="SourceCodePro.zip"
            FONT_PATTERNS=("*SauceCodePro*" "*SourceCodePro*")
            FONT_FC_FAMILY="SauceCodePro Nerd Font"
            FONT_DESC="Clásica monoespaciada profesional diseñada por Adobe"
            ;;
        Monaspace)
            FONT_ARCHIVE="Monaspace.zip"
            FONT_PATTERNS=("*Monaspace*" "*Monaspice*")
            FONT_FC_FAMILY="MonaspiceNe Nerd Font"
            FONT_DESC="Superfamilia de GitHub (Neon, Argon, Radon, Krypton) con ligaduras"
            ;;
        Iosevka)
            FONT_ARCHIVE="Iosevka.zip"
            FONT_PATTERNS=("*Iosevka*")
            FONT_FC_FAMILY="Iosevka Nerd Font"
            FONT_DESC="Monoespacio ultra condensado de alta densidad para código"
            ;;
        *)
            FONT_ARCHIVE="${font}.zip"
            FONT_PATTERNS=("*${font}*")
            FONT_FC_FAMILY="${font} Nerd Font"
            FONT_DESC="Fuente Nerd Font adicional"
            ;;
    esac
}

count_font_files() {
    local font="$1"
    if [ ! -d "$FONT_DIR" ]; then
        echo "0"
        return 0
    fi

    get_font_meta "$font"

    local find_args=()
    for pat in "${FONT_PATTERNS[@]}"; do
        if [ ${#find_args[@]} -gt 0 ]; then
            find_args+=("-o")
        fi
        find_args+=("-iname" "$pat")
    done

    local count
    count=$(find "$FONT_DIR" -type f \( -iname "*.ttf" -o -iname "*.otf" \) \( "${find_args[@]}" \) 2>/dev/null | wc -l)
    echo "${count:-0}"
}

fc_list_has_family() {
    local family="$1"
    local cache="${2:-}"
    if [ -n "$cache" ]; then
        echo "$cache" | grep -qi "$family"
        return $?
    fi

    if command -v fc-list &>/dev/null; then
        fc-list ":family=$family" family 2>/dev/null | grep -qi "$family"
        return $?
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 6. TAREAS DE INSTALACIÓN, DESINSTALACIÓN Y MANTENIMIENTO
# ------------------------------------------------------------------------------
clean_font_artifacts_in_dir() {
    local target="$1"
    if [ -d "$target" ]; then
        run_as_user find "$target" -type f \( -iname "*.txt" -o -iname "*.md" -o -iname "LICENSE*" \) -delete 2>/dev/null || true
    fi
}

clean_windows_variants_in_dir() {
    local target="$1"
    if [ -d "$target" ]; then
        run_as_user find "$target" -type f -iname "*Windows Compatible*" -delete 2>/dev/null || true
    fi
}

install_font() {
    local font="$1"
    local force="${2:-false}"
    local dry_run="${3:-false}"
    local clean_windows="${4:-true}"

    local normalized
    normalized=$(normalize_font_name "$font")
    get_font_meta "$normalized"

    local existing_count
    existing_count=$(count_font_files "$normalized")

    if [ "$existing_count" -gt 0 ] && [ "$force" != "true" ]; then
        log_success "$normalized ya está instalada ($existing_count variantes detectadas). Omitiendo."
        return 0
    fi

    if [ "$dry_run" = "true" ]; then
        log_info "[DRY-RUN] Se descargaría e instalaría $normalized Nerd Font ($FONT_ARCHIVE)."
        return 0
    fi

    log_step "Descargando $normalized Nerd Font..."
    ensure_tmp_dir

    local tmp_zip="$TMP_DIR/${FONT_ARCHIVE}"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_ARCHIVE}"

    local curl_progress=(--progress-bar)
    if [ ! -t 1 ]; then
        curl_progress=(-s -S)
    fi

    if ! run_as_user curl --proto '=https' --tlsv1.2 -fL --connect-timeout 10 --max-time 180 --retry 3 --retry-delay 2 "${curl_progress[@]}" "$download_url" -o "$tmp_zip"; then
        log_error "Falló la descarga de $normalized desde $download_url"
        rm -f "$tmp_zip" 2>/dev/null || true
        return 1
    fi

    if ! unzip -tq "$tmp_zip" &>/dev/null; then
        log_error "El archivo descargado para $normalized no es un archivo ZIP válido."
        rm -f "$tmp_zip" 2>/dev/null || true
        return 1
    fi

    local extract_tmp="$TMP_DIR/extract_${normalized}"
    run_as_user rm -rf "$extract_tmp" 2>/dev/null || true
    run_as_user mkdir -p "$extract_tmp"

    log_step "Extrayendo y optimizando variantes de $normalized..."
    run_as_user unzip -qo "$tmp_zip" -d "$extract_tmp"
    rm -f "$tmp_zip" 2>/dev/null || true

    clean_font_artifacts_in_dir "$extract_tmp"
    if [ "$clean_windows" = "true" ]; then
        clean_windows_variants_in_dir "$extract_tmp"
    fi

    local extracted_count
    extracted_count=$(find "$extract_tmp" -type f \( -iname "*.ttf" -o -iname "*.otf" \) 2>/dev/null | wc -l)
    if [ "$extracted_count" -eq 0 ]; then
        log_error "No se encontraron archivos .ttf o .otf válidos en el paquete de $normalized."
        run_as_user rm -rf "$extract_tmp" 2>/dev/null || true
        return 1
    fi

    local target_dir="$FONT_DIR/$normalized"
    run_as_user mkdir -p "$target_dir"

    if [ "$force" = "true" ] && [ -d "$target_dir" ]; then
        run_as_user rm -rf "${target_dir:?}"/* 2>/dev/null || true
    fi

    run_as_user cp -rf "$extract_tmp"/* "$target_dir"/
    run_as_user rm -rf "$extract_tmp" 2>/dev/null || true

    log_success "$normalized instalada con éxito ($extracted_count variantes en $target_dir)."
    INSTALLED_ANY=true
}

remove_font() {
    local font="$1"
    local dry_run="${2:-false}"

    local normalized
    normalized=$(normalize_font_name "$font")
    get_font_meta "$normalized"

    if [ "$dry_run" = "true" ]; then
        log_info "[DRY-RUN] Se desinstalaría $normalized de $FONT_DIR."
        return 0
    fi

    log_step "Desinstalando $normalized Nerd Font..."
    local initial_count
    initial_count=$(count_font_files "$normalized")

    if [ "$initial_count" -eq 0 ]; then
        log_info "No se encontraron variantes instaladas de $normalized en $FONT_DIR."
        return 0
    fi

    # 1. Eliminar subdirectorio específico si existe
    if [ -d "$FONT_DIR/$normalized" ]; then
        run_as_user rm -rf "$FONT_DIR/$normalized"
    fi

    # 2. Eliminar variantes sueltas que coincidan con los patrones
    if [ -d "$FONT_DIR" ]; then
        for pat in "${FONT_PATTERNS[@]}"; do
            run_as_user find "$FONT_DIR" -maxdepth 1 -type f -iname "$pat" -delete 2>/dev/null || true
        done
    fi

    log_success "$normalized desinstalada correctamente ($initial_count variantes eliminadas)."
    INSTALLED_ANY=true
}

clean_font_artifacts() {
    if [ ! -d "$FONT_DIR" ]; then
        log_info "Directorio de fuentes ($FONT_DIR) no existe aún. Nada que limpiar."
        return 0
    fi

    log_step "Buscando archivos residuales no tipográficos (*.txt, *.md, LICENSE*)..."
    local count
    count=$(find "$FONT_DIR" -type f \( -iname "*.txt" -o -iname "*.md" -o -iname "LICENSE*" \) 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
        run_as_user find "$FONT_DIR" -type f \( -iname "*.txt" -o -iname "*.md" -o -iname "LICENSE*" \) -delete 2>/dev/null || true
        log_success "$count archivo(s) residual(es) eliminado(s) de $FONT_DIR."
    else
        log_info "No se encontraron archivos residuales en $FONT_DIR."
    fi
}

clean_windows_fonts() {
    if [ ! -d "$FONT_DIR" ]; then
        log_info "Directorio de fuentes ($FONT_DIR) no existe aún."
        return 0
    fi

    log_step "Buscando variantes 'Windows Compatible' redundantes en $FONT_DIR..."
    local count
    count=$(find "$FONT_DIR" -type f -iname "*Windows Compatible*" 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
        run_as_user find "$FONT_DIR" -type f -iname "*Windows Compatible*" -delete 2>/dev/null || true
        log_success "$count archivo(s) redundante(s) de Windows eliminado(s). Espacio recuperado."
        INSTALLED_ANY=true
    else
        log_info "No se detectaron archivos redundantes 'Windows Compatible'."
    fi
}

update_cache() {
    if [ ! -d "$FONT_DIR" ]; then
        log_info "Directorio de fuentes ($FONT_DIR) no existe aún. Omitiendo regeneración de caché."
        return 0
    fi
    log_info "Actualizando caché de fuentes de usuario con fc-cache..."
    run_as_user fc-cache -f "$FONT_DIR"
    log_success "Caché de fuentes fontconfig actualizada correctamente."
}

set_gnome_monospace() {
    local font_choice="${1:-JetBrainsMono}"
    local size="${2:-11}"
    local normalized
    normalized=$(normalize_font_name "$font_choice")
    get_font_meta "$normalized"

    local target_font="$FONT_FC_FAMILY $size"
    if command -v gsettings &>/dev/null; then
        run_as_user gsettings set org.gnome.desktop.interface monospace-font-name "$target_font" 2>/dev/null || true
        log_success "Tipografía monoespaciada de GNOME Shell configurada a: '$target_font'"
    else
        log_warn "'gsettings' no está disponible en este entorno para configurar GNOME."
    fi
}

# ------------------------------------------------------------------------------
# 7. REPORTES Y DIAGNÓSTICO
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}${BLUE}=================================================================${NC}"
    echo -e "${BOLD}🔤 ESTADO DE FUENTES NERD FONTS (Soplos Linux Boro GNOME Wayland)${NC}"
    echo -e "${BOLD}${BLUE}=================================================================${NC}"
    echo -e "👤 Usuario:         ${CYAN}$REAL_USER${NC}"
    echo -e "📁 Directorio:      ${CYAN}$FONT_DIR${NC}"

    if [ -d "$FONT_DIR" ]; then
        local disk_usage total_files
        disk_usage=$(du -sh "$FONT_DIR" 2>/dev/null | cut -f1)
        total_files=$(find "$FONT_DIR" -type f \( -iname "*.ttf" -o -iname "*.otf" \) 2>/dev/null | wc -l)
        echo -e "💾 Uso en disco:    ${GREEN}$disk_usage${NC} ($total_files variantes tipográficas en total)"
    else
        echo -e "💾 Uso en disco:    ${YELLOW}Directorio no creado aún (0 fuentes locales)${NC}"
    fi

    if command -v gsettings &>/dev/null; then
        local gnome_mono
        gnome_mono=$(run_as_user gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || echo "Desconocida")
        echo -e "🖥️  GNOME Monospace: ${GREEN}$gnome_mono${NC}"
    fi

    echo -e "${BLUE}-----------------------------------------------------------------${NC}"
    printf "%-15s | %-12s | %-10s | %-12s | %s\n" "FUENTE" "ESTADO" "ARCHIVOS" "FONTCONFIG" "USO RECOMENDADO"
    echo -e "${BLUE}--------------------------------------------------------------------------------------------------${NC}"

    local fc_cache_all=""
    if command -v fc-list &>/dev/null; then
        fc_cache_all=$(fc-list : family 2>/dev/null || true)
    fi

    for font in "${DEFAULT_FONTS[@]}"; do
        get_font_meta "$font"
        local count
        count=$(count_font_files "$font")
        local fc_status="${RED}❌ Inactiva${NC}"
        if fc_list_has_family "$FONT_FC_FAMILY" "$fc_cache_all"; then
            fc_status="${GREEN}✅ Activa${NC}"
        fi

        if [ "$count" -gt 0 ]; then
            printf "%-15s | ${GREEN}%-12s${NC} | %-10s | %-12b | %s\n" "$font" "Instalada" "$count" "$fc_status" "$FONT_DESC"
        else
            printf "%-15s | ${YELLOW}%-12s${NC} | %-10s | %-12b | %s\n" "$font" "Faltante" "0" "$fc_status" "$FONT_DESC"
        fi
    done
    echo -e "${BOLD}${BLUE}=================================================================${NC}"
}

show_list() {
    echo -e "${BOLD}${BLUE}=================================================================${NC}"
    echo -e "${BOLD}🔤 FUENTES NERD FONTS DISPONIBLES EN EL CATÁLOGO${NC}"
    echo -e "${BOLD}${BLUE}=================================================================${NC}"
    printf "%-15s | %-12s | %s\n" "NOMBRE" "TIPO" "DESCRIPCIÓN Y USO RECOMENDADO"
    echo -e "${BLUE}-----------------------------------------------------------------${NC}"
    for f in "${DEFAULT_FONTS[@]}"; do
        get_font_meta "$f"
        printf "%-15s | %-12s | %s\n" "$f" "Predeterminada" "$FONT_DESC"
    done
    echo -e "${BLUE}-----------------------------------------------------------------${NC}"
    for f in "${EXTENDED_FONTS[@]}"; do
        get_font_meta "$f"
        printf "%-15s | %-12s | %s\n" "$f" "Opcional" "$FONT_DESC"
    done
    echo -e "${BLUE}-----------------------------------------------------------------${NC}"
    echo -e "💡 Instala fuentes específicas de forma individual o múltiple con:"
    echo -e "   ${CYAN}./Setup/fonts.sh <NombreFuente>${NC}"
    echo -e "   Ejemplo: ${CYAN}./Setup/fonts.sh GeistMono Monaspace${NC}"
    echo -e "${BOLD}${BLUE}=================================================================${NC}"
}

show_help() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES] [FUENTES...]

Instalación, verificación y gestión optimizada de fuentes de desarrollo (Nerd Fonts)
para Soplos Linux Boro y GNOME Shell (Wayland).

OPCIONES:
  -s, --status            Muestra el estado detallado de las fuentes instaladas, fontconfig y GNOME.
  -l, --list              Muestra el catálogo completo de fuentes disponibles.
  -f, --force             Fuerza la descarga e instalación aunque ya existan.
  -n, --dry-run           Simula las acciones sin descargar ni modificar archivos en disco.
  -c, --clean             Elimina archivos no tipográficos residuales (*.txt, *.md, LICENSE*).
  --clean-windows         Elimina variantes redundantes 'Windows Compatible' para ahorrar ~50% de espacio.
  -r, --remove <FUENTE>   Desinstala la fuente especificada y actualiza la caché fontconfig.
  -g, --set-gnome [FNT]   Configura la fuente monoespaciada de GNOME Shell (predeterminada: JetBrainsMono 11).
  -u, --update-cache      Fuerza la regeneración de la caché de fuentes fontconfig.
  -h, --help              Muestra esta ayuda.

EJEMPLOS:
  $(basename "$0")                      # Verifica e instala fuentes predeterminadas faltantes
  $(basename "$0") --status             # Diagnóstico de estado de fuentes, caché y GNOME
  $(basename "$0") CascadiaCode         # Descarga e instala únicamente CascadiaCode
  $(basename "$0") -f JetBrainsMono     # Reinstala forzosamente JetBrainsMono
  $(basename "$0") --set-gnome          # Configura JetBrainsMono Nerd Font 11 en GNOME Shell
  $(basename "$0") --remove Meslo       # Desinstala Meslo y refresca la caché
  $(basename "$0") --clean              # Limpia archivos no tipográficos residuales
  $(basename "$0") --clean-windows      # Pone al día el espacio eliminando variantes Windows

FUENTES PREDETERMINADAS:
  ${DEFAULT_FONTS[*]}
EOF
}

# ------------------------------------------------------------------------------
# 8. PARSEO DE ARGUMENTOS Y FLUJO PRINCIPAL
# ------------------------------------------------------------------------------
FORCE_INSTALL=false
DRY_RUN=false
CLEAN_WINDOWS=true
ACTION=""
GNOME_FONT_ARG=""
REMOVE_FONTS=()
TARGET_FONTS=()

while [ $# -gt 0 ]; do
    case "$1" in
        -s|--status)
            ACTION="status"
            shift
            ;;
        -l|--list)
            ACTION="list"
            shift
            ;;
        -c|--clean)
            ACTION="clean"
            shift
            ;;
        --clean-windows)
            ACTION="clean-windows"
            shift
            ;;
        -u|--update-cache)
            ACTION="update-cache"
            shift
            ;;
        -f|--force)
            FORCE_INSTALL=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -r|--remove|--uninstall)
            shift
            if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
                REMOVE_FONTS+=("$1")
                shift
            else
                log_error "La opción --remove requiere el nombre de la fuente a desinstalar."
                exit 1
            fi
            ;;
        -g|--set-gnome)
            ACTION="set-gnome"
            shift
            if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
                GNOME_FONT_ARG="$1"
                shift
            fi
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            TARGET_FONTS+=("$1")
            shift
            ;;
    esac
done

# Flujos de acción directa inmediata
if [ "$ACTION" = "status" ]; then
    show_status
    exit 0
elif [ "$ACTION" = "list" ]; then
    show_list
    exit 0
elif [ "$ACTION" = "clean" ]; then
    clean_font_artifacts
    update_cache
    exit 0
elif [ "$ACTION" = "clean-windows" ]; then
    clean_windows_fonts
    update_cache
    exit 0
elif [ "$ACTION" = "update-cache" ]; then
    update_cache
    exit 0
elif [ "$ACTION" = "set-gnome" ]; then
    set_gnome_monospace "${GNOME_FONT_ARG:-JetBrainsMono}"
    exit 0
fi

# Flujo de desinstalación
if [ ${#REMOVE_FONTS[@]} -gt 0 ]; then
    for rf in "${REMOVE_FONTS[@]}"; do
        remove_font "$rf" "$DRY_RUN"
    done
    if [ "$INSTALLED_ANY" = "true" ] && [ "$DRY_RUN" = "false" ]; then
        update_cache
    fi
    exit 0
fi

# Flujo principal de instalación / verificación
ensure_dependencies
if [ "$DRY_RUN" = "false" ]; then
    run_as_user mkdir -p "$FONT_DIR"
fi

if [ ${#TARGET_FONTS[@]} -eq 0 ]; then
    TARGET_FONTS=("${DEFAULT_FONTS[@]}")
fi

echo -e "${BOLD}${BLUE}=================================================================${NC}"
echo -e "${BOLD}🔤 Verificando fuentes de desarrollo (Nerd Fonts) para $REAL_USER...${NC}"
echo -e "${BOLD}${BLUE}=================================================================${NC}"

for font in "${TARGET_FONTS[@]}"; do
    if [ "$font" = "all" ]; then
        for df in "${DEFAULT_FONTS[@]}"; do
            install_font "$df" "$FORCE_INSTALL" "$DRY_RUN" "$CLEAN_WINDOWS"
        done
    else
        install_font "$font" "$FORCE_INSTALL" "$DRY_RUN" "$CLEAN_WINDOWS"
    fi
done

if [ "$DRY_RUN" = "false" ]; then
    clean_font_artifacts
    if [ "$INSTALLED_ANY" = "true" ] || [ "$FORCE_INSTALL" = "true" ]; then
        update_cache
    else
        log_info "Todas las fuentes solicitadas ya están presentes y listas para usar."
    fi
fi

echo -e "${BOLD}${BLUE}=================================================================${NC}"
log_success "Gestión de fuentes completada exitosamente."
echo -e "${BOLD}${BLUE}=================================================================${NC}"
