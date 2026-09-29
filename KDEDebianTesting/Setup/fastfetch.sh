#!/usr/bin/env bash
# ==============================================================================
# fastfetch.sh - Instalación y Configuración Estética de Fastfetch
# Sistema: Debian Testing (Trixie/Sid) | Escritorio: KDE Plasma 6 (Wayland)
# ==============================================================================
# Características:
# - Detección inteligente y modo rootless: no ejecuta sudo ni APT si ya está instalado.
# - Soporte para múltiples temas estéticos:
#   * 'debian' (Predeterminado): Espiral oficial de Debian con acentos rubí y métricas completas.
#   * 'compact': Diseño de caja minimalista FastCat (sin logo ASCII) para paneles reducidos.
# - Respaldo automático (.bak) si el usuario ya tenía una configuración modificada.
# - Comandos CLI: --status, --run, --theme, --list-themes, --diff, --force, --help.
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

get_theme_path() {
    local theme_name="$1"
    case "$theme_name" in
        debian|default)
            if [ -f "$SCRIPT_DIR/config-debian.jsonc" ]; then
                echo "$SCRIPT_DIR/config-debian.jsonc"
            else
                echo "$SCRIPT_DIR/config.jsonc"
            fi
            ;;
        compact|fastcat|minimal)
            echo "$SCRIPT_DIR/config-compact.jsonc"
            ;;
        *)
            if [ -f "$SCRIPT_DIR/config-${theme_name}.jsonc" ]; then
                echo "$SCRIPT_DIR/config-${theme_name}.jsonc"
            elif [ -f "$theme_name" ]; then
                echo "$theme_name"
            else
                echo ""
            fi
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN E INSTALACIÓN DE DEPENDENCIAS
# ------------------------------------------------------------------------------
ensure_dependencies() {
    if command -v fastfetch &>/dev/null; then
        local version_str
        version_str=$(fastfetch --version 2>/dev/null | head -n 1 || echo "instalado")
        echo "  ✅ Fastfetch ya está instalado ($version_str)."
        return 0
    fi

    echo "📦 Fastfetch no está instalado en el sistema."
    echo "   Instalando paquete oficial vía APT..."
    export DEBIAN_FRONTEND=noninteractive
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo &>/dev/null; then
            echo "❌ Error: Se requiere 'sudo' para instalar Fastfetch."
            exit 1
        fi
        sudo apt-get update -qq
        sudo apt-get install -y fastfetch
    else
        apt-get update -qq
        apt-get install -y fastfetch
    fi
}

# ------------------------------------------------------------------------------
# 4. GESTIÓN DE CONFIGURACIÓN Y TEMAS
# ------------------------------------------------------------------------------
apply_config() {
    local theme_name="${1:-debian}"
    local force="${2:-false}"

    local source_config
    source_config=$(get_theme_path "$theme_name")

    if [ -z "$source_config" ] || [ ! -f "$source_config" ]; then
        echo "❌ Error: No se encontró la plantilla para el tema '$theme_name'."
        echo "   Usa '$(basename "$0") --list-themes' para consultar los temas disponibles."
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
        echo "  ℹ️ Creando respaldo de configuración previa en: $backup_file"
        run_as_user cp "$USER_CONFIG_FILE" "$backup_file"
    fi

    run_as_user cp "$source_config" "$USER_CONFIG_FILE"
    run_as_user chmod 644 "$USER_CONFIG_FILE"
    echo "  ✅ Tema '$theme_name' aplicado correctamente en $USER_CONFIG_FILE."
}

show_diff() {
    local theme_name="${1:-debian}"
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
        echo "✅ La configuración instalada es 100% idéntica a la plantilla del tema '$theme_name'."
    else
        echo "⚠️ Diferencias entre la plantilla '$theme_name' y ~/.config/fastfetch/config.jsonc:"
        diff -u --color=auto "$source_config" "$USER_CONFIG_FILE" || true
    fi
}

list_themes() {
    echo "================================================================="
    echo "🎨 TEMAS ESTÉTICOS DISPONIBLES DE FASTFETCH"
    echo "================================================================="
    echo "1) debian (Predeterminado / Activo)"
    echo "   🍥 Protagonista: Espiral oficial de Debian en arte ASCII"
    echo "   ✨ Diseño: Acentos rojo rubí y cian, métricas de CPU/GPU, Host, Red y Kernel"
    echo "   📁 Archivo: Setup/config-debian.jsonc"
    echo ""
    echo "2) compact (Minimalista)"
    echo "   📦 Protagonista: Caja minimalista FastCat con bordes redondeados (sin logo ASCII)"
    echo "   ✨ Diseño: Ideal para paneles divididos o ventanas pequeñas de terminal"
    echo "   📁 Archivo: Setup/config-compact.jsonc"
    echo "-----------------------------------------------------------------"
    echo "💡 Puedes alternar entre ellos fácilmente con:"
    echo "   just fastfetch --theme debian"
    echo "   just fastfetch --theme compact"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 5. DIAGNÓSTICO Y ESTADO
# ------------------------------------------------------------------------------
show_status() {
    echo "================================================================="
    echo "📊 ESTADO DE FASTFETCH (Debian Testing)"
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

    # Configuración de usuario y detección de tema
    echo "📁 Archivo de configuración: $USER_CONFIG_FILE"
    if [ -f "$USER_CONFIG_FILE" ]; then
        if [ -f "$SCRIPT_DIR/config-debian.jsonc" ] && cmp -s "$SCRIPT_DIR/config-debian.jsonc" "$USER_CONFIG_FILE"; then
            echo "🎨 Tema activo:            🍥 Debian Spiral (Debian Testing Hero Theme)"
        elif [ -f "$SCRIPT_DIR/config-compact.jsonc" ] && cmp -s "$SCRIPT_DIR/config-compact.jsonc" "$USER_CONFIG_FILE"; then
            echo "🎨 Tema activo:            📦 Compact FastCat (Minimalista sin logo)"
        else
            echo "🎨 Tema activo:            🛠️  Personalizado / Modificado manualmente"
        fi
    else
        echo "🎨 Tema activo:            ❌ No configurado (Usa 'just fastfetch' para aplicarlo)"
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
para Debian Testing (Trixie/Sid) y KDE Plasma 6.

OPCIONES:
  -s, --status              Muestra el estado de instalación, versión y tema activo.
  -r, --run                 Ejecuta Fastfetch con la configuración de usuario activa.
  -t, --theme <NOMBRE>      Aplica un tema específico ('debian' o 'compact').
  -l, --list-themes         Lista los temas disponibles y sus características.
  -d, --diff [TEMA]         Compara la configuración instalada con la plantilla del tema.
  -f, --force               Fuerza la reinstalación del tema (creando respaldo previo .bak).
  -h, --help                Muestra esta ayuda.

TEMAS SOPORTADOS:
  debian   (Predeterminado) Espiral oficial de Debian en arte ASCII con detalles completos.
  compact  (Minimalista) Caja redondeada FastCat sin logo ASCII.

EJEMPLOS:
  $(basename "$0")                     # Aplica el tema Debian y muestra el banner
  $(basename "$0") --status            # Diagnóstico de versión y tema activo
  $(basename "$0") --theme compact     # Cambia al diseño minimalista
  $(basename "$0") --theme debian      # Cambia al diseño del espiral de Debian
  $(basename "$0") --list-themes       # Información detallada de cada diseño
EOF
}

# ------------------------------------------------------------------------------
# 6. PARSEO DE ARGUMENTOS Y FLUJO PRINCIPAL
# ------------------------------------------------------------------------------
ACTION=""
THEME_NAME="debian"
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
        -l|--list-themes)
            ACTION="list-themes"
            shift
            ;;
        -t|--theme)
            shift
            if [ $# -gt 0 ]; then
                THEME_NAME="$1"
                shift
            else
                echo "❌ Error: Debes especificar el nombre de un tema ('debian' o 'compact')."
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
            echo "❌ Opción desconocida: $1"
            echo "Usa '$(basename "$0") --help' para ver las opciones disponibles."
            exit 1
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
    diff)
        show_diff "$THEME_NAME"
        exit 0
        ;;
esac

echo "================================================================="
echo "ℹ️  Configuración de Fastfetch para Debian Testing ($REAL_USER)..."
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
