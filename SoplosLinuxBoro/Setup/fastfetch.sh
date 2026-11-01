#!/usr/bin/env bash
# ==============================================================================
# fastfetch.sh - Instalación y Configuración Estética de Fastfetch
# Sistema: Soplos Linux Boro | Escritorio: GNOME Shell (Wayland)
# ==============================================================================
# Características:
# - Detección inteligente y modo rootless: no ejecuta sudo si ya está instalado.
# - Catálogo completo de temas disponibles en el repositorio:
#   * 'soplos' (Predeterminado / Oficial): Configuración nativa oficial de Soplos Linux
#     Boro con logo PNG branding, métricas detalladas por categorías y barras de color.
#   * 'soplos-ascii': Mismo diseño categorizado oficial con logo Soplos en ASCII art.
#   * 'compact' (FastCat): Caja minimalista con bordes redondeados (sin logo ASCII).
#   * 'modern' (Debian): Diseño condensado con logo Debian y acentos color rubí.
#   * Personalizado: Soporta cualquier archivo config-<nombre>.jsonc o ruta externa.
# - Selector interactivo (--menu / -i) para elegir e instalar temas en consola.
# - Modo vista previa (--preview / -p) para probar cualquier tema sin alterar config.
# - Respaldo automático (.bak) si el usuario ya tenía una configuración modificada.
# - Comandos CLI: --status, --run, --theme, --list-themes, --preview, --menu, --diff, --force, --help.
# - Integración completa con atajos y aliases de consola ('ff').
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
# 2. RUTAS Y ARCHIVOS
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_CONFIG_DIR="$USER_HOME/.config/fastfetch"
USER_CONFIG_FILE="$USER_CONFIG_DIR/config.jsonc"

# Resuelve el archivo de configuración a partir del nombre o ruta del tema
get_theme_path() {
    local theme_name="$1"

    # 1. Ruta absoluta o relativa directa existente
    if [ -f "$theme_name" ]; then
        echo "$theme_name"
        return 0
    fi

    # 2. Alias conocidos
    case "$theme_name" in
        soplos|official|default)
            if [ -f "$SCRIPT_DIR/config-soplos.jsonc" ]; then
                echo "$SCRIPT_DIR/config-soplos.jsonc"
            elif [ -f "$SCRIPT_DIR/config.jsonc" ]; then
                echo "$SCRIPT_DIR/config.jsonc"
            elif [ -f "/etc/skel/.config/fastfetch/config.jsonc" ]; then
                echo "/etc/skel/.config/fastfetch/config.jsonc"
            fi
            return 0
            ;;
        soplos-ascii|ascii)
            if [ -f "$SCRIPT_DIR/config-soplos-ascii.jsonc" ]; then
                echo "$SCRIPT_DIR/config-soplos-ascii.jsonc"
            fi
            return 0
            ;;
        compact|fastcat|minimal)
            if [ -f "$SCRIPT_DIR/config-compact.jsonc" ]; then
                echo "$SCRIPT_DIR/config-compact.jsonc"
            fi
            return 0
            ;;
        modern|debian)
            if [ -f "$SCRIPT_DIR/config-modern.jsonc" ]; then
                echo "$SCRIPT_DIR/config-modern.jsonc"
            fi
            return 0
            ;;
    esac

    # 3. Búsqueda por patrón de nombre en Setup/
    if [ -f "$SCRIPT_DIR/config-${theme_name}.jsonc" ]; then
        echo "$SCRIPT_DIR/config-${theme_name}.jsonc"
    elif [ -f "$SCRIPT_DIR/${theme_name}.jsonc" ]; then
        echo "$SCRIPT_DIR/${theme_name}.jsonc"
    elif [ -f "$SCRIPT_DIR/${theme_name}" ]; then
        echo "$SCRIPT_DIR/${theme_name}"
    else
        echo ""
    fi
}

# Obtiene una etiqueta legible y descriptiva para cada archivo de tema
get_theme_title() {
    local file_path="$1"
    local base_name
    base_name=$(basename "$file_path")

    case "$base_name" in
        config-soplos.jsonc|config.jsonc)
            echo "Soplos Linux Boro Oficial (Logo PNG Branding + Categorías y Barras)"
            ;;
        config-soplos-ascii.jsonc)
            echo "Soplos Linux Boro ASCII (Logo Soplos en ASCII Art para TTY/SSH)"
            ;;
        config-compact.jsonc)
            echo "Compact FastCat (Caja minimalista redondeada sin logo)"
            ;;
        config-modern.jsonc)
            echo "Modern Minimal (Logo Debian ASCII y paleta rubí condensada)"
            ;;
        *)
            echo "Tema personalizado (${base_name})"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN E INSTALACIÓN DE DEPENDENCIAS
# ------------------------------------------------------------------------------
ensure_dependencies() {
    local missing_pkgs=()

    if ! command -v fastfetch &>/dev/null; then
        missing_pkgs+=("fastfetch")
    fi

    # Chafa permite renderizar imágenes en terminales que no tienen soporte gráfico nativo
    if ! command -v chafa &>/dev/null; then
        missing_pkgs+=("chafa")
    fi

    if [ ${#missing_pkgs[@]} -eq 0 ]; then
        local version_str
        version_str=$(fastfetch --version 2>/dev/null | head -n 1 || echo "instalado")
        echo "  ✅ Fastfetch y utilidades gráficas listas ($version_str)."
        return 0
    fi

    echo "📦 Paquetes requeridos ausentes: ${missing_pkgs[*]}"
    echo "   Instalando vía APT..."
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo &>/dev/null; then
            echo "❌ Error: Se requiere 'sudo' para instalar ${missing_pkgs[*]}."
            exit 1
        fi
        sudo apt-get update -qq
        sudo apt-get install -y "${missing_pkgs[@]}"
    else
        apt-get update -qq
        apt-get install -y "${missing_pkgs[@]}"
    fi
}

# ------------------------------------------------------------------------------
# 4. GESTIÓN DE CONFIGURACIÓN Y TEMAS
# ------------------------------------------------------------------------------
apply_config() {
    local theme_name="${1:-soplos}"
    local force="${2:-false}"

    local source_config
    source_config=$(get_theme_path "$theme_name")

    if [ -z "$source_config" ] || [ ! -f "$source_config" ]; then
        echo "❌ Error: No se encontró la configuración para el tema '$theme_name'."
        echo "   Usa '$(basename "$0") --list-themes' para consultar las configuraciones disponibles."
        return 1
    fi

    run_as_user mkdir -p "$USER_CONFIG_DIR"

    if [ -f "$USER_CONFIG_FILE" ]; then
        if cmp -s "$source_config" "$USER_CONFIG_FILE" && [ "$force" != "true" ]; then
            echo "  ✅ La configuración activa en $USER_CONFIG_FILE ya corresponde al tema '$theme_name'."
            return 0
        fi

        # Si difiere y no se forzó, crear copia de respaldo
        local backup_file="${USER_CONFIG_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
        echo "  ℹ️ Creando respaldo de la configuración previa en: $backup_file"
        run_as_user cp "$USER_CONFIG_FILE" "$backup_file"
    fi

    run_as_user cp "$source_config" "$USER_CONFIG_FILE"
    run_as_user chmod 644 "$USER_CONFIG_FILE"
    echo "  ✅ Tema '$theme_name' aplicado correctamente en $USER_CONFIG_FILE."
}

preview_theme() {
    local theme_name="${1:-soplos}"
    local source_config
    source_config=$(get_theme_path "$theme_name")

    if [ -z "$source_config" ] || [ ! -f "$source_config" ]; then
        echo "❌ Error: No se encontró la configuración para '$theme_name'."
        return 1
    fi

    echo "👁️  Vista previa de Fastfetch con el tema: $(get_theme_title "$source_config")"
    echo "📁 Archivo fuente: $source_config"
    echo "-----------------------------------------------------------------"
    run_as_user fastfetch -c "$source_config"
}

show_diff() {
    local theme_name="${1:-soplos}"
    local source_config
    source_config=$(get_theme_path "$theme_name")

    if [ ! -f "$USER_CONFIG_FILE" ]; then
        echo "ℹ️ El archivo de configuración de usuario ($USER_CONFIG_FILE) aún no existe."
        return 0
    fi
    if [ -z "$source_config" ] || [ ! -f "$source_config" ]; then
        echo "❌ Plantilla fuente no encontrada para el tema '$theme_name'."
        return 1
    fi

    if cmp -s "$source_config" "$USER_CONFIG_FILE"; then
        echo "✅ La configuración instalada es 100% idéntica a la plantilla de '$theme_name'."
    else
        echo "⚠️ Diferencias entre la plantilla '$theme_name' y ~/.config/fastfetch/config.jsonc:"
        diff -u --color=auto "$source_config" "$USER_CONFIG_FILE" || true
    fi
}

list_themes() {
    echo "================================================================="
    echo "🎨 TEMAS ESTÉTICOS DISPONIBLES DE FASTFETCH"
    echo "================================================================="
    echo "Directorio de plantillas: $SCRIPT_DIR"
    echo ""

    local count=1
    local current_active=""
    local theme_key=""

    for file in "$SCRIPT_DIR"/config-*.jsonc; do
        [ -e "$file" ] || continue
        local base
        base=$(basename "$file")
        theme_key="${base#config-}"
        theme_key="${theme_key%.jsonc}"

        local status_indicator="  "
        if [ -f "$USER_CONFIG_FILE" ] && cmp -s "$file" "$USER_CONFIG_FILE"; then
            status_indicator="🟢 [ACTIVO]"
            current_active="$theme_key"
        fi

        echo "$count) $theme_key $status_indicator"
        echo "   ✨ Descripción: $(get_theme_title "$file")"
        echo "   📁 Archivo:     Setup/$base"
        echo "   🚀 Aplicar:     $(basename "$0") --theme $theme_key"
        echo "   👁️  Previsualizar: $(basename "$0") --preview $theme_key"
        echo ""
        ((count++))
    done

    echo "-----------------------------------------------------------------"
    echo "💡 Atajos rápidos con Justfile:"
    echo "   just fastfetch --theme soplos"
    echo "   just fastfetch --theme soplos-ascii"
    echo "   just fastfetch --theme compact"
    echo "   just fastfetch --theme modern"
    echo "   just fastfetch --menu"
    echo "================================================================="
}

interactive_menu() {
    echo "================================================================="
    echo "🎛️  SELECTOR INTERACTIVO DE TEMAS FASTFETCH"
    echo "================================================================="

    local theme_keys=()
    local theme_files=()
    local index=1

    for file in "$SCRIPT_DIR"/config-*.jsonc; do
        [ -e "$file" ] || continue
        local base
        base=$(basename "$file")
        local key="${base#config-}"
        key="${key%.jsonc}"

        theme_keys+=("$key")
        theme_files+=("$file")

        local active_tag=""
        if [ -f "$USER_CONFIG_FILE" ] && cmp -s "$file" "$USER_CONFIG_FILE"; then
            active_tag=" (🟢 Actualmente Activo)"
        fi

        echo "  $index) $key - $(get_theme_title "$file")$active_tag"
        ((index++))
    done

    if [ ${#theme_keys[@]} -eq 0 ]; then
        echo "❌ No se encontraron archivos de configuración en $SCRIPT_DIR."
        return 1
    fi

    echo "  0) Cancelar y salir"
    echo "-----------------------------------------------------------------"
    read -rp "Selecciona el número del tema que deseas instalar [1-${#theme_keys[@]}]: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#theme_keys[@]}" ]; then
        local chosen_key="${theme_keys[$((choice - 1))]}"
        echo ""
        apply_config "$chosen_key" true
        echo ""
        echo "🚀 Mostrando Fastfetch con el tema '$chosen_key':"
        run_as_user fastfetch 2>/dev/null || true
    else
        echo "ℹ️ Operación cancelada. No se modificó la configuración."
    fi
}

# ------------------------------------------------------------------------------
# 5. DIAGNÓSTICO Y ESTADO
# ------------------------------------------------------------------------------
show_status() {
    echo "================================================================="
    echo "📊 ESTADO DE FASTFETCH (Soplos Linux Boro GNOME Wayland)"
    echo "================================================================="
    echo "👤 Usuario:                $REAL_USER"

    # Binario y versión
    if command -v fastfetch &>/dev/null; then
        local version_str bin_path
        version_str=$(fastfetch --version 2>/dev/null | head -n 1 || echo "Desconocida")
        bin_path=$(command -v fastfetch)
        echo "📦 Estado de instalación:   ✅ Instalado ($version_str en $bin_path)"
    else
        echo "📦 Estado de instalación:   ❌ No instalado"
    fi

    # Dependencia gráfica Chafa
    if command -v chafa &>/dev/null; then
        local chafa_ver
        chafa_ver=$(chafa --version 2>/dev/null | head -n 1 || echo "Instalado")
        echo "🖼️  Soporte Chafa (PNG):    ✅ Disponible ($chafa_ver)"
    else
        echo "🖼️  Soporte Chafa (PNG):    ⚠️  No instalado (Recomendado para visualización PNG)"
    fi

    # Configuración de usuario y detección de tema
    echo "📁 Archivo de configuración: $USER_CONFIG_FILE"
    if [ -f "$USER_CONFIG_FILE" ]; then
        local detected_theme=""
        for file in "$SCRIPT_DIR"/config-*.jsonc; do
            [ -e "$file" ] || continue
            if cmp -s "$file" "$USER_CONFIG_FILE"; then
                detected_theme="$(get_theme_title "$file") ($(basename "$file"))"
                break
            fi
        done

        if [ -n "$detected_theme" ]; then
            echo "🎨 Tema activo:            🟢 $detected_theme"
        elif [ -f "/etc/skel/.config/fastfetch/config.jsonc" ] && cmp -s "/etc/skel/.config/fastfetch/config.jsonc" "$USER_CONFIG_FILE"; then
            echo "🎨 Tema activo:            🟢 Soplos Linux Boro Oficial (/etc/skel)"
        else
            echo "🎨 Tema activo:            🛠️  Personalizado / Modificado manualmente"
        fi
    else
        echo "🎨 Tema activo:            ❌ No configurado (Usa 'just fastfetch' para aplicarlo)"
    fi

    # Comprobación de assets de branding
    local branding_png="/usr/share/branding-soplos/menusoplos.png"
    local branding_txt="/usr/share/branding-soplos/logo.txt"
    if [ -f "$branding_png" ]; then
        echo "🏷️  Branding Oficial PNG:   ✅ $branding_png presente"
    else
        echo "🏷️  Branding Oficial PNG:   ⚠️  $branding_png ausente (Usando fallback local)"
    fi

    if [ -f "$branding_txt" ]; then
        echo "🏷️  Branding Oficial ASCII: ✅ $branding_txt presente"
    fi

    # Alias en shell
    if [ -f "$USER_HOME/.bashrc.d/aliases.sh" ] && grep -q "alias ff=" "$USER_HOME/.bashrc.d/aliases.sh" 2>/dev/null; then
        echo "⌨️  Alias de terminal:      ✅ 'ff' configurado en ~/.bashrc.d/aliases.sh"
    elif [ -f "$SCRIPT_DIR/../Bash.Setup/aliases.sh" ] && grep -q "alias ff=" "$SCRIPT_DIR/../Bash.Setup/aliases.sh" 2>/dev/null; then
        echo "⌨️  Alias de terminal:      ✅ 'ff' disponible en el repositorio (Bash.Setup/aliases.sh)"
    else
        echo "⌨️  Alias de terminal:      ℹ️ Puedes añadir 'alias ff=fastfetch' para acceso rápido"
    fi

    echo "================================================================="
}

show_help() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES]

Instalación, diagnóstico y gestión de la configuración estética de Fastfetch
para Soplos Linux Boro y GNOME Shell (Wayland).

OPCIONES:
  -s, --status              Muestra el estado de instalación, versión y tema activo.
  -r, --run                 Ejecuta Fastfetch con la configuración de usuario activa.
  -t, --theme <NOMBRE|RUTA> Aplica un tema específico o un archivo .jsonc personalizado.
  -p, --preview [TEMA]      Previsualiza un tema temporalmente sin modificar tu configuración.
  -i, --menu, --select      Abre el selector interactivo numerado para elegir e instalar un tema.
  -l, --list-themes         Lista todos los temas disponibles en el repositorio.
  -d, --diff [TEMA]         Compara la configuración instalada con la plantilla del tema.
  -f, --force               Fuerza la reinstalación del tema (creando respaldo previo .bak).
  -h, --help                Muestra esta ayuda.

TEMAS PREDEFINIDOS DISPONIBLES:
  soplos        (Predeterminado) Tema oficial Soplos Linux Boro con logo PNG y métricas completas.
  soplos-ascii  Tema oficial con logo Soplos renderizado en ASCII Art (ideal para TTY o SSH).
  compact       Caja minimalista redondeada FastCat sin logo, ideal para ventanas pequeñas.
  modern        Diseño condensado con logo Debian ASCII y acentos de color rubí.
  <ruta.jsonc>  Cualquier ruta a un archivo de configuración Fastfetch personalizado.

EJEMPLOS:
  $(basename "$0")                         # Instala/Aplica el tema oficial de Soplos Linux Boro
  $(basename "$0") --menu                  # Selector interactivo de temas
  $(basename "$0") --list-themes           # Muestra todos los temas disponibles con detalles
  $(basename "$0") --preview compact       # Previsualiza el diseño minimalista sin aplicarlo
  $(basename "$0") --theme soplos-ascii    # Aplica la versión con logo Soplos en ASCII Art
  $(basename "$0") --theme compact         # Aplica la caja minimalista FastCat
  $(basename "$0") --status                # Diagnóstico del entorno, tema activo y branding
EOF
}

# ------------------------------------------------------------------------------
# 6. PARSEO DE ARGUMENTOS Y FLUJO PRINCIPAL
# ------------------------------------------------------------------------------
ACTION=""
THEME_NAME="soplos"
FORCE_APPLY=false

while [ $# -gt 0 ]; do
    case "$1" in
        -s|--status)
            ACTION="status"
            shift
            ;;
        -r|--run)
            ACTION="run"
            shift
            ;;
        -l|--list-themes|--list)
            ACTION="list-themes"
            shift
            ;;
        -i|--menu|--select)
            ACTION="menu"
            shift
            ;;
        -p|--preview)
            ACTION="preview"
            shift
            if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
                THEME_NAME="$1"
                shift
            fi
            ;;
        -t|--theme)
            shift
            if [ $# -gt 0 ]; then
                THEME_NAME="$1"
                shift
            else
                echo "❌ Error: Debes especificar el nombre o archivo de un tema."
                exit 1
            fi
            ;;
        -d|--diff)
            ACTION="diff"
            shift
            if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
                THEME_NAME="$1"
                shift
            fi
            ;;
        -f|--force)
            FORCE_APPLY=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            # Si el argumento no empieza con -, asumimos que es el nombre de un tema
            if [[ ! "$1" =~ ^- ]]; then
                THEME_NAME="$1"
                shift
            else
                echo "❌ Opción desconocida: $1"
                echo "Usa '$(basename "$0") --help' para ver las opciones disponibles."
                exit 1
            fi
            ;;
    esac
done

case "$ACTION" in
    status)
        show_status
        exit 0
        ;;
    run)
        run_as_user fastfetch
        exit 0
        ;;
    list-themes)
        list_themes
        exit 0
        ;;
    menu)
        interactive_menu
        exit 0
        ;;
    preview)
        preview_theme "$THEME_NAME"
        exit 0
        ;;
    diff)
        show_diff "$THEME_NAME"
        exit 0
        ;;
esac

echo "================================================================="
echo "ℹ️  Configuración de Fastfetch para Soplos Linux Boro ($REAL_USER)..."
echo "   Tema seleccionado: '$THEME_NAME'"
echo "================================================================="

ensure_dependencies
apply_config "$THEME_NAME" "$FORCE_APPLY"

echo "================================================================="
echo "✅ Fastfetch configurado con el tema '$THEME_NAME'."
echo "💡 Puedes ejecutar 'fastfetch' o el alias 'ff' para visualizarlo."
echo "================================================================="
echo ""
run_as_user fastfetch 2>/dev/null || true
