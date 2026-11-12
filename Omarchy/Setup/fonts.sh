#!/usr/bin/env bash
# ==============================================================================
# fonts.sh - Gestión e Instalación de Fuentes Nerd Fonts en Omarchy 4.5+
# Sistema: Omarchy Workstation | Escritorio: Hyprland (Wayland)
# Integración: omarchy install font, omarchy font set, omarchy font list
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CATÁLOGO DE FUENTES COMPATIBLES CON OMARCHY
# ------------------------------------------------------------------------------
DEFAULT_FONTS=("JetBrainsMono" "FiraCode" "CascadiaCode" "Meslo" "Hack")

get_font_info() {
    local key="$1"
    case "$key" in
        JetBrainsMono|jetbrains)
            FONT_KEY="JetBrainsMono"
            FONT_NAME="JetBrains Mono"
            FONT_PKG="ttf-jetbrains-mono-nerd"
            FONT_PKG_ALT="ttf-jetbrains-mono-nerd-basic"
            FONT_FAMILY="JetBrainsMono Nerd Font"
            FONT_DESC="Predeterminada para Kitty, Neovim e IDEs (ligaduras completas)"
            ;;
        FiraCode|firacode)
            FONT_KEY="FiraCode"
            FONT_NAME="Fira Code"
            FONT_PKG="ttf-firacode-nerd"
            FONT_PKG_ALT=""
            FONT_FAMILY="FiraCode Nerd Font"
            FONT_DESC="Ligaduras avanzadas de programación altamente legibles"
            ;;
        CascadiaCode|cascadia|CaskaydiaCove)
            FONT_KEY="CascadiaCode"
            FONT_NAME="Cascadia Code"
            FONT_PKG="ttf-cascadia-code-nerd"
            FONT_PKG_ALT="ttf-cascadia-mono-nerd"
            FONT_FAMILY="CaskaydiaCove Nerd Font"
            FONT_DESC="Estilo Windows Terminal / VS Code moderno con ligaduras"
            ;;
        Meslo|meslo)
            FONT_KEY="Meslo"
            FONT_NAME="Meslo LG"
            FONT_PKG="ttf-meslo-nerd"
            FONT_PKG_ALT=""
            FONT_FAMILY="MesloLGS Nerd Font"
            FONT_DESC="Optimizada para prompts CLI (Starship, Powerlevel10k)"
            ;;
        Hack|hack)
            FONT_KEY="Hack"
            FONT_NAME="Hack"
            FONT_PKG="ttf-hack-nerd"
            FONT_PKG_ALT=""
            FONT_FAMILY="Hack Nerd Font"
            FONT_DESC="Monoespaciada clásica de alta legibilidad en terminal"
            ;;
        GeistMono|geist)
            FONT_KEY="GeistMono"
            FONT_NAME="Geist Mono"
            FONT_PKG="otf-geist-mono-nerd"
            FONT_PKG_ALT=""
            FONT_FAMILY="GeistMono Nerd Font"
            FONT_DESC="Diseño geométrico limpio y moderno (Vercel)"
            ;;
        VictorMono|victor)
            FONT_KEY="VictorMono"
            FONT_NAME="Victor Mono"
            FONT_PKG="ttf-victor-mono-nerd"
            FONT_PKG_ALT=""
            FONT_FAMILY="VictorMono Nerd Font"
            FONT_DESC="Monoespacio elegante con cursiva caligráfica para comentarios"
            ;;
        CommitMono|commit)
            FONT_KEY="CommitMono"
            FONT_NAME="Commit Mono"
            FONT_PKG="otf-commit-mono-nerd"
            FONT_PKG_ALT=""
            FONT_FAMILY="CommitMono Nerd Font"
            FONT_DESC="Monoespacio neutral altamente optimizado para código"
            ;;
        SourceCodePro|sourcecode)
            FONT_KEY="SourceCodePro"
            FONT_NAME="Source Code Pro"
            FONT_PKG="ttf-sourcecodepro-nerd"
            FONT_PKG_ALT=""
            FONT_FAMILY="SauceCodePro Nerd Font"
            FONT_DESC="Clásica monoespaciada profesional diseñada por Adobe"
            ;;
        *)
            echo "❌ Error: Fuente '$key' no reconocida en el catálogo." >&2
            echo "   Ejecuta: $(basename "$0") --list para ver las opciones soportadas." >&2
            return 1
            ;;
    esac
}

is_package_installed() {
    local pkg="$1"
    local alt="${2:-}"
    if pacman -Q "$pkg" &>/dev/null; then
        return 0
    fi
    if [ -n "$alt" ] && pacman -Q "$alt" &>/dev/null; then
        return 0
    fi
    return 1
}

is_family_active() {
    local family="$1"
    if command -v fc-list &>/dev/null; then
        fc-list ":family=$family" family 2>/dev/null | grep -i "$family" >/dev/null 2>&1
        return $?
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 2. ACCIONES
# ------------------------------------------------------------------------------
show_status() {
    echo "================================================================="
    echo "🔤 ESTADO DE FUENTES (Omarchy 4.5 / Hyprland)"
    echo "================================================================="
    local current_font="Desconocida"
    if command -v omarchy-font-current &>/dev/null; then
        current_font=$(omarchy-font-current)
    elif command -v omarchy &>/dev/null; then
        current_font=$(omarchy font current 2>/dev/null || echo "Desconocida")
    fi
    echo "🎯 Fuente actual del sistema: $current_font"
    echo "-----------------------------------------------------------------"
    printf "%-15s | %-26s | %-12s | %-12s\n" "FUENTE" "PAQUETE ARCH" "INSTALADO" "FONTCONFIG"
    echo "-----------------------------------------------------------------------------------------"

    local all_fonts=("${DEFAULT_FONTS[@]}" "GeistMono" "VictorMono" "CommitMono" "SourceCodePro")
    for f in "${all_fonts[@]}"; do
        get_font_info "$f"
        local status_pkg="❌ No"
        local status_fc="❌ Inactiva"

        if is_package_installed "$FONT_PKG" "$FONT_PKG_ALT"; then
            status_pkg="✅ Sí"
        fi

        if is_family_active "$FONT_FAMILY"; then
            status_fc="✅ Activa"
        fi

        printf "%-15s | %-26s | %-12s | %-12s\n" "$FONT_KEY" "$FONT_PKG" "$status_pkg" "$status_fc"
    done
    echo "================================================================="
}

show_list() {
    echo "================================================================="
    echo "🔤 CATÁLOGO DE FUENTES NERD FONTS EN OMARCHY 4.5"
    echo "================================================================="
    printf "%-15s | %-26s | %s\n" "NOMBRE" "PAQUETE OFICIAL" "DESCRIPCIÓN"
    echo "-----------------------------------------------------------------"
    local all_fonts=("${DEFAULT_FONTS[@]}" "GeistMono" "VictorMono" "CommitMono" "SourceCodePro")
    for f in "${all_fonts[@]}"; do
        get_font_info "$f"
        printf "%-15s | %-26s | %s\n" "$FONT_KEY" "$FONT_PKG" "$FONT_DESC"
    done
    echo "-----------------------------------------------------------------"
    echo "💡 Puedes instalar cualquiera con Omarchy usando:"
    echo "   $(basename "$0") <NombreFuente>"
    echo "   Ejemplo: $(basename "$0") FiraCode"
    echo "   Comando nativo equivalente:"
    echo "   omarchy install font 'Fira Code' ttf-firacode-nerd 'FiraCode Nerd Font'"
    echo "================================================================="
}

install_with_omarchy() {
    local key="$1"
    local no_gui="${2:-false}"
    get_font_info "$key"

    if is_package_installed "$FONT_PKG" "$FONT_PKG_ALT"; then
        echo "  ✅ $FONT_NAME ($FONT_PKG) ya está instalado."
        return 0
    fi

    echo "🚀 Instalando $FONT_NAME vía Omarchy ($FONT_PKG)..."

    if [ "$no_gui" = "true" ]; then
        if command -v omarchy-pkg-add &>/dev/null; then
            omarchy-pkg-add "$FONT_PKG"
        else
            sudo pacman -S --noconfirm --needed "$FONT_PKG"
        fi
        echo "  ✅ Paquete $FONT_PKG instalado."
    else
        # Invocación oficial de Omarchy (lanza terminal flotante con presentación y configura la fuente)
        if command -v omarchy &>/dev/null; then
            omarchy install font "$FONT_NAME" "$FONT_PKG" "$FONT_FAMILY"
        elif command -v omarchy-install-font &>/dev/null; then
            omarchy-install-font "$FONT_NAME" "$FONT_PKG" "$FONT_FAMILY"
        else
            echo "⚠️ Advertencia: Comando 'omarchy install font' no encontrado. Usando pacman..."
            sudo pacman -S --noconfirm --needed "$FONT_PKG"
        fi
    fi
}

set_system_font() {
    local key="$1"
    get_font_info "$key"

    if ! is_family_active "$FONT_FAMILY"; then
        echo "⚠️  La fuente '$FONT_FAMILY' no parece estar instalada todavía."
        echo "   Instálala primero con: $(basename "$0") $key"
        exit 1
    fi

    echo "🔄 Cambiando fuente global del sistema a '$FONT_FAMILY'..."
    if command -v omarchy &>/dev/null; then
        omarchy font set "$FONT_FAMILY"
    elif command -v omarchy-font-set &>/dev/null; then
        omarchy-font-set "$FONT_FAMILY"
    else
        echo "❌ Error: 'omarchy font set' no está disponible en el sistema."
        exit 1
    fi
    echo "✅ Fuente establecida correctamente."
}

show_help() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES] [FUENTES...]

Gestión e instalación de fuentes de desarrollo (Nerd Fonts) integradas de forma
nativa con Omarchy 4.5+ mediante 'omarchy install font' y 'omarchy font set'.

OPCIONES:
  -s, --status         Muestra el estado de instalación de paquetes y fuentes activas.
  -l, --list           Lista el catálogo de fuentes soportadas y sus paquetes Arch.
  -S, --set <FUENTE>   Aplica la fuente seleccionada como la activa del sistema.
  --cli, --no-gui      Instala directamente en la terminal actual sin abrir ventana flotante.
  -h, --help           Muestra esta ayuda.

EJEMPLOS:
  $(basename "$0")                     # Verifica e instala las fuentes predeterminadas faltantes
  $(basename "$0") FiraCode            # Instala FiraCode con: omarchy install font
  $(basename "$0") --set JetBrainsMono # Cambia la fuente activa con: omarchy font set
  $(basename "$0") --status            # Muestra el estado del sistema
  $(basename "$0") --cli FiraCode Hack # Instala vía CLI sin terminal emergente

FUENTES PREDETERMINADAS:
  ${DEFAULT_FONTS[*]}
EOF
}

# ------------------------------------------------------------------------------
# 3. PARSEO DE ARGUMENTOS Y FLUJO PRINCIPAL
# ------------------------------------------------------------------------------
ACTION=""
NO_GUI=false
SET_TARGET=""
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
        -S|--set)
            ACTION="set"
            SET_TARGET="${2:-}"
            if [ -z "$SET_TARGET" ]; then
                echo "❌ Error: Se requiere especificar la fuente para --set." >&2
                exit 1
            fi
            shift 2
            ;;
        --cli|--no-gui)
            NO_GUI=true
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

if [ "$ACTION" = "status" ]; then
    show_status
    exit 0
elif [ "$ACTION" = "list" ]; then
    show_list
    exit 0
elif [ "$ACTION" = "set" ]; then
    set_system_font "$SET_TARGET"
    exit 0
fi

# Si no se indicaron fuentes específicas, procesar el lote predeterminado
if [ ${#TARGET_FONTS[@]} -eq 0 ]; then
    TARGET_FONTS=("${DEFAULT_FONTS[@]}")
fi

echo "================================================================="
echo "🔤 Verificando fuentes de desarrollo con Omarchy 4.5..."
echo "================================================================="

for font in "${TARGET_FONTS[@]}"; do
    if [ "$font" = "all" ]; then
        for df in "${DEFAULT_FONTS[@]}" "GeistMono" "VictorMono" "CommitMono" "SourceCodePro"; do
            install_with_omarchy "$df" "$NO_GUI"
        done
    else
        install_with_omarchy "$font" "$NO_GUI"
    fi
done

echo "================================================================="
echo "✅ Proceso completado exitosamente."
echo "================================================================="
