#!/usr/bin/env bash
# ==============================================================================
# fonts.sh - Instalación, Verificación y Gestión de Fuentes de Desarrollo (Nerd Fonts)
# Sistema: openSUSE Tumbleweed | Escritorio: KDE Plasma 6 (Wayland)
# ==============================================================================
# Características:
# - Soporte para fuentes de desarrollo con ligaduras y glifos Nerd Fonts:
#   * JetBrainsMono (predeterminada en Kitty, Neovim e IDEs)
#   * FiraCode (ligaduras completas de programación)
#   * CascadiaCode / CaskaydiaCove (estilo moderno con ligaduras)
#   * Meslo (optimizada para prompts CLI: Starship, Powerlevel10k)
#   * Hack (monoespacio clásico de alta legibilidad)
# - Detección inteligente tanto en estructura plana como en subdirectorios.
# - Corrección de coincidencia para CascadiaCode (CaskaydiaCove Nerd Font).
# - Comandos CLI: --status, --list, --force, --clean, --update-cache, --help.
# - Modo de usuario rootless: no invoca sudo ni zypper a menos que falten binarios.
# - Descargas resilientes con reintentos y barra de progreso.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PERMISOS
# ------------------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 2. DIRECTORIOS Y RECURSOS TEMPORALES
# ------------------------------------------------------------------------------
FONT_DIR="$USER_HOME/.local/share/fonts"
TMP_DIR=""
INSTALLED_ANY=false

cleanup() {
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT INT TERM

ensure_tmp_dir() {
    if [ -z "$TMP_DIR" ] || [ ! -d "$TMP_DIR" ]; then
        TMP_DIR=$(run_as_user mktemp -d "/tmp/nerd-fonts-XXXXXX")
    fi
}

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN DE DEPENDENCIAS
# ------------------------------------------------------------------------------
ensure_dependencies() {
    local missing=()
    for cmd in curl unzip fc-cache; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "📦 Dependencias faltantes: ${missing[*]}"
        echo "   Instalando dependencias necesarias con Zypper..."
        if [ "$EUID" -ne 0 ]; then
            if ! command -v sudo &>/dev/null; then
                echo "❌ Error: Se requiere 'sudo' para instalar las dependencias faltantes."
                exit 1
            fi
            sudo zypper --non-interactive install -y curl unzip fontconfig
        else
            zypper --non-interactive install -y curl unzip fontconfig
        fi
    fi
}

# ------------------------------------------------------------------------------
# 4. CONFIGURACIÓN Y METADATOS DE FUENTES
# ------------------------------------------------------------------------------
DEFAULT_FONTS=("JetBrainsMono" "FiraCode" "CascadiaCode" "Meslo" "Hack")

get_font_meta() {
    local font="$1"
    case "$font" in
        JetBrainsMono)
            FONT_ARCHIVE="JetBrainsMono.zip"
            FONT_PATTERNS=("*JetBrainsMono*")
            FONT_FC_FAMILY="JetBrainsMono Nerd Font"
            FONT_DESC="Predeterminada para Kitty, Neovim e IDEs (ligaduras completas)"
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
    get_font_meta "$font"
    local total=0

    # 1. Verificar subdirectorio específico si existe
    if [ -d "$FONT_DIR/$font" ]; then
        local count_sub
        count_sub=$(find "$FONT_DIR/$font" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | wc -l)
        total=$((total + count_sub))
    fi

    # 2. Verificar archivos planos en el directorio base (evitando duplicar conteo de subdirectorios)
    for pat in "${FONT_PATTERNS[@]}"; do
        local count_flat
        count_flat=$(find "$FONT_DIR" -maxdepth 1 -type f -name "$pat" 2>/dev/null | wc -l)
        total=$((total + count_flat))
    done

    echo "$total"
}

fc_list_has_family() {
    local family="$1"
    if command -v fc-list &>/dev/null; then
        fc-list ":family=$family" family 2>/dev/null | grep -i "$family" >/dev/null 2>&1
        return $?
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 5. TAREAS DE INSTALACIÓN Y LIMPIEZA
# ------------------------------------------------------------------------------
install_font() {
    local font="$1"
    local force="${2:-false}"
    get_font_meta "$font"

    local existing_count
    existing_count=$(count_font_files "$font")

    if [ "$existing_count" -gt 0 ] && [ "$force" != "true" ]; then
        echo "  ✅ $font ya está instalada ($existing_count variantes detectadas). Omitiendo."
        return 0
    fi

    echo "⬇️  Descargando $font Nerd Font..."
    ensure_tmp_dir

    local target_dir="$FONT_DIR/$font"
    run_as_user mkdir -p "$target_dir"

    local tmp_zip="$TMP_DIR/${FONT_ARCHIVE}"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_ARCHIVE}"

    if ! curl --proto '=https' --tlsv1.2 -fL --retry 3 --retry-delay 2 --progress-bar "$download_url" -o "$tmp_zip"; then
        echo "❌ Error: Falló la descarga de $font desde $download_url"
        return 1
    fi

    if ! unzip -tq "$tmp_zip" &>/dev/null; then
        echo "❌ Error: El archivo descargado para $font no es un ZIP válido."
        rm -f "$tmp_zip"
        return 1
    fi

    echo "📦 Extrayendo variantes de $font en $target_dir..."
    run_as_user unzip -qo "$tmp_zip" -d "$target_dir"
    rm -f "$tmp_zip"

    # Limpiar archivos no tipográficos en el subdirectorio recién instalado
    run_as_user find "$target_dir" -type f \( -name "*.txt" -o -name "*.md" -o -name "LICENSE*" \) -delete 2>/dev/null || true

    local new_count
    new_count=$(find "$target_dir" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | wc -l)
    echo "  ✅ $font instalada con éxito ($new_count variantes en $target_dir)."
    INSTALLED_ANY=true
}

clean_font_artifacts() {
    echo "🧹 Verificando archivos residuales no tipográficos (*.txt, *.md, LICENSE*)..."
    local count
    count=$(find "$FONT_DIR" -type f \( -name "*.txt" -o -name "*.md" -o -name "LICENSE*" \) 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
        run_as_user find "$FONT_DIR" -type f \( -name "*.txt" -o -name "*.md" -o -name "LICENSE*" \) -delete 2>/dev/null || true
        echo "  ✅ $count archivo(s) residual(es) eliminado(s) de $FONT_DIR."
    else
        echo "  ℹ️ No se encontraron archivos residuales en $FONT_DIR."
    fi
}

update_cache() {
    echo "ℹ️  Actualizando caché de fuentes de usuario con fc-cache..."
    run_as_user fc-cache -f "$FONT_DIR"
    echo "  ✅ Caché de fuentes actualizada correctamente."
}

# ------------------------------------------------------------------------------
# 6. REPORTES Y DIAGNÓSTICO
# ------------------------------------------------------------------------------
show_status() {
    echo "================================================================="
    echo "🔤 ESTADO DE FUENTES NERD FONTS (openSUSE Tumbleweed)"
    echo "================================================================="
    echo "👤 Usuario:         $REAL_USER"
    echo "📁 Directorio:      $FONT_DIR"
    if [ -d "$FONT_DIR" ]; then
        local disk_usage total_files
        disk_usage=$(du -sh "$FONT_DIR" 2>/dev/null | cut -f1)
        total_files=$(find "$FONT_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | wc -l)
        echo "💾 Uso en disco:    $disk_usage ($total_files variantes tipográficas)"
    else
        echo "💾 Uso en disco:    Directorio no creado aún"
    fi
    echo "-----------------------------------------------------------------"
    printf "%-15s | %-12s | %-10s | %-12s | %s\n" "FUENTE" "ESTADO" "ARCHIVOS" "FONTCONFIG" "USO RECOMENDADO"
    echo "--------------------------------------------------------------------------------------------------"

    for font in "${DEFAULT_FONTS[@]}"; do
        get_font_meta "$font"
        local count
        count=$(count_font_files "$font")
        local fc_status="❌ Inactiva"
        if fc_list_has_family "$FONT_FC_FAMILY"; then
            fc_status="✅ Activa"
        fi

        if [ "$count" -gt 0 ]; then
            printf "%-15s | %-12s | %-10s | %-12s | %s\n" "$font" "✅ Instalada" "$count" "$fc_status" "$FONT_DESC"
        else
            printf "%-15s | %-12s | %-10s | %-12s | %s\n" "$font" "⚠️ Faltante" "0" "$fc_status" "$FONT_DESC"
        fi
    done
    echo "================================================================="
}

show_list() {
    echo "================================================================="
    echo "🔤 FUENTES NERD FONTS RECOMENDADAS Y DISPONIBLES"
    echo "================================================================="
    printf "%-15s | %s\n" "NOMBRE" "DESCRIPCIÓN Y USO RECOMENDADO"
    echo "-----------------------------------------------------------------"
    for f in "${DEFAULT_FONTS[@]}" GeistMono CommitMono VictorMono SourceCodePro; do
        get_font_meta "$f"
        printf "%-15s | %s\n" "$f" "$FONT_DESC"
    done
    echo "-----------------------------------------------------------------"
    echo "💡 Puedes instalar cualquiera de forma individual con:"
    echo "   ./Setup/fonts.sh <NombreFuente>"
    echo "   Ejemplo: ./Setup/fonts.sh GeistMono"
    echo "================================================================="
}

show_help() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES] [FUENTES...]

Instalación, verificación y gestión optimizada de fuentes de desarrollo (Nerd Fonts)
para openSUSE Tumbleweed y KDE Plasma 6.

OPCIONES:
  -s, --status         Muestra el estado detallado de las fuentes instaladas y fontconfig.
  -l, --list           Muestra la lista de fuentes recomendadas disponibles.
  -f, --force          Fuerza la descarga e instalación aunque ya existan.
  -c, --clean          Elimina archivos no tipográficos residuales (*.txt, *.md, LICENSE*).
  -u, --update-cache   Fuerza la regeneración de la caché de fuentes de usuario.
  -h, --help           Muestra esta ayuda.

EJEMPLOS:
  $(basename "$0")                     # Verifica e instala fuentes predeterminadas faltantes
  $(basename "$0") --status            # Diagnóstico del estado de fuentes y caché
  $(basename "$0") CascadiaCode        # Descarga e instala únicamente CascadiaCode
  $(basename "$0") -f JetBrainsMono    # Reinstala forzosamente JetBrainsMono
  $(basename "$0") --clean             # Limpia archivos no tipográficos residuales

FUENTES PREDETERMINADAS:
  JetBrainsMono, FiraCode, CascadiaCode, Meslo, Hack
EOF
}

# ------------------------------------------------------------------------------
# 7. PARSEO DE ARGUMENTOS Y FLUJO PRINCIPAL
# ------------------------------------------------------------------------------
FORCE_INSTALL=false
ACTION=""
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
        -u|--update-cache)
            ACTION="update-cache"
            shift
            ;;
        -f|--force)
            FORCE_INSTALL=true
            shift
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

# Despachar acciones exclusivas
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
elif [ "$ACTION" = "update-cache" ]; then
    update_cache
    exit 0
fi

# Flujo de instalación/verificación
ensure_dependencies
run_as_user mkdir -p "$FONT_DIR"

if [ ${#TARGET_FONTS[@]} -eq 0 ]; then
    TARGET_FONTS=("${DEFAULT_FONTS[@]}")
fi

echo "================================================================="
echo "🔤 Verificando fuentes de desarrollo (Nerd Fonts) para $REAL_USER..."
echo "================================================================="

for font in "${TARGET_FONTS[@]}"; do
    if [ "$font" = "all" ]; then
        for df in "${DEFAULT_FONTS[@]}"; do
            install_font "$df" "$FORCE_INSTALL"
        done
    else
        install_font "$font" "$FORCE_INSTALL"
    fi
done

# Limpieza preventiva de archivos no tipográficos
clean_font_artifacts

# Actualizar caché de fuentes sólo si se instaló alguna fuente o se forzó
if [ "$INSTALLED_ANY" = "true" ] || [ "$FORCE_INSTALL" = "true" ]; then
    update_cache
else
    echo "ℹ️  Todas las fuentes solicitadas ya están presentes y listas para usar."
fi

echo "================================================================="
echo "✅ Gestión de fuentes completada exitosamente."
echo "================================================================="
