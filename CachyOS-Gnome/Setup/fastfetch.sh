#!/usr/bin/env bash
# ==============================================================================
# fastfetch.sh - Instalador y Gestor de Temas de Fastfetch
# Sistema: CachyOS Workstation (GNOME Shell Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8)
# ==============================================================================
# Características:
#   - Instalación nativa mediante Pacman (CachyOS x86-64-v3).
#   - Soporte para telemetría de hardware AMD Ryzen 7 7730U (temp CPU/GPU, ZRAM, batería y NVMe).
#   - 4 temas optimizados: cachyos (Hero), cachyos-simple, modern, compact (FastCat).
#   - Previsualización en vivo, menú interactivo, diff de plantillas y diagnóstico --status.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES, RUTAS Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# 2. PRIVILEGIOS Y DETECCIÓN DE USUARIO REAL
# ------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    if ! command -v sudo &>/dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible en este sistema.${NC}" >&2
        exit 1
    fi
    SUDO="sudo"
    REAL_USER="${USER:-$(whoami)}"
else
    SUDO=""
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
fi

USER_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6 || echo "${HOME:-/home/$REAL_USER}")
DEST_DIR="$USER_HOME/.config/fastfetch"
DEST_FILE="$DEST_DIR/config.jsonc"

THEME="cachyos"
FORCE=false
ACTION="install"

# ------------------------------------------------------------------------------
# 3. RESOLUCIÓN Y VALIDACIÓN DE TEMAS
# ------------------------------------------------------------------------------
resolve_theme_file() {
    local t="${1:-cachyos}"
    case "$t" in
        cachyos|hero|default) echo "$SCRIPT_DIR/config-cachyos.jsonc" ;;
        cachyos-simple|simple) echo "$SCRIPT_DIR/config-cachyos-simple.jsonc" ;;
        modern)               echo "$SCRIPT_DIR/config-modern.jsonc" ;;
        compact|fastcat)      echo "$SCRIPT_DIR/config-compact.jsonc" ;;
        *)
            log_err "Tema desconocido: '$t'."
            echo -e "Temas válidos: ${CYAN}cachyos${NC}, ${CYAN}cachyos-simple${NC}, ${CYAN}modern${NC}, ${CYAN}compact${NC}."
            exit 1
            ;;
    esac
}

validate_theme_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_err "No se encuentra el archivo de tema: $file"
        return 1
    fi

    if command -v fastfetch &>/dev/null; then
        if ! fastfetch --config "$file" >/dev/null 2>&1; then
            log_err "Error de sintaxis en el archivo JSONC: $file"
            return 1
        fi
    fi
    return 0
}

# ------------------------------------------------------------------------------
# 4. AYUDA Y LISTADO DE TEMAS
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}📊 Gestor e Instalador de Fastfetch - CachyOS Workstation (GNOME Wayland)${NC}

Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U, Radeon Graphics Vega 8, ZRAM y GNOME Mutter).
Instala Fastfetch vía Pacman y despliega temas personalizados con paleta oficial CachyOS Cyan/Emerald.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)           Instala Fastfetch y aplica el tema 'cachyos' (Hero categorizado)
  -t, --theme <nombre>       Aplica el tema especificado: cachyos | cachyos-simple | modern | compact
  -p, --preview [tema]       Previsualiza un tema en consola sin modificar ~/.config/fastfetch
  -m, --menu                 Selector interactivo de temas con opción de prueba previa
  -l, --list-themes          Lista todos los temas disponibles con sus características
  -r, --run                  Ejecuta fastfetch con la configuración activa actual
  -d, --diff [tema]          Compara el archivo activo actual con la plantilla del repositorio
  -b, --backup               Crea una copia de seguridad manual en ~/.config/fastfetch/config.jsonc.bak
  -f, --force                Sobrescribe ~/.config/fastfetch/config.jsonc sin confirmación
  -s, --status               Diagnóstico completo de Fastfetch y telemetría de la estación de trabajo
  -h, --help                 Muestra esta ayuda

${BOLD}Ejemplos:${NC}
  $0                         # Aplica tema CachyOS Hero por defecto
  $0 --preview modern        # Previsualiza el tema moderno con logo amplio
  $0 --theme compact         # Instala el tema ultra-compacto estilo FastCat
  $0 --status                # Muestra el estado del binario, tema activo y hardware
EOF
}

list_themes() {
    echo -e "${BOLD}🎨 Temas disponibles para Fastfetch (CachyOS Workstation):${NC}"
    echo -e "  • ${CYAN}cachyos${NC}         -> ${BOLD}Hero Categorizado${NC} (HARDWARE / SYSTEM / THEMING) con barras de progreso,"
    echo -e "                           temperaturas CPU/GPU AMD, batería HP ProBook y acento CachyOS Cyan [Por defecto]"
    echo -e "  • ${CYAN}cachyos-simple${NC}  -> ${BOLD}Minimalista Limpio${NC} con logo compacto CachyOS y telemetría clave"
    echo -e "  • ${CYAN}modern${NC}         -> ${BOLD}Logo Amplio Moderno${NC} con flechas Nerd Font y acento Catppuccin Sapphire"
    echo -e "  • ${CYAN}compact${NC}        -> ${BOLD}Ultra-compacto FastCat${NC} con recuadro enmarcado, ideal para splits y ventanas reducidas"
}

# ------------------------------------------------------------------------------
# 5. DIAGNÓSTICO DEL SISTEMA Y TELEMETRÍA (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  📊 ${BOLD}ESTADO DE FASTFETCH - CACHYOS WORKSTATION (GNOME WAYLAND)${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    # 1. Binario Fastfetch
    if command -v fastfetch &>/dev/null; then
        local ff_ver
        ff_ver=$(fastfetch --version 2>/dev/null || echo "Desconocida")
        echo -e "  • Binario Fastfetch:         ${GREEN}${ff_ver}${NC}"
        local pkg_info
        pkg_info=$(pacman -Q fastfetch 2>/dev/null || echo "Nativo")
        echo -e "  • Paquete Pacman:            ${CYAN}${pkg_info}${NC}"
    else
        echo -e "  • Binario Fastfetch:         ${RED}No instalado${NC}"
    fi

    # 2. Configuración activa y tema detectado
    if [[ -f "$DEST_FILE" ]]; then
        local active_theme="Personalizado"
        for t in cachyos cachyos-simple modern compact; do
            local tf
            tf=$(resolve_theme_file "$t")
            if [[ -f "$tf" ]] && cmp -s "$DEST_FILE" "$tf"; then
                active_theme="$t"
                break
            fi
        done
        local file_size
        file_size=$(stat -c%s "$DEST_FILE" 2>/dev/null || echo "0")
        echo -e "  • Configuración activa:      ${GREEN}${DEST_FILE}${NC} (${file_size} bytes)"
        echo -e "  • Tema activo detectado:     ${CYAN} ${active_theme}${NC}"
    else
        echo -e "  • Configuración activa:      ${YELLOW}No configurada (~/.config/fastfetch/config.jsonc no existe)${NC}"
    fi

    # 3. Telemetría del Hardware HP ProBook 455 G10
    echo -e "\n  ${BOLD}🖥️  Telemetría de la Estación de Trabajo HP ProBook 455 G10:${NC}"
    
    # CPU
    if [[ -f /proc/cpuinfo ]]; then
        local cpu_model
        cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
        local cpu_cores
        cpu_cores=$(nproc 2>/dev/null || echo "16")
        echo -e "  • CPU:                       ${CYAN}${cpu_model} (${cpu_cores} hilos Zen 3)${NC}"
    fi

    # GPU
    if command -v lspci &>/dev/null; then
        local gpu_info
        gpu_info=$(lspci | grep -iE 'vga|3d|display' | cut -d: -f3 | xargs || echo "AMD Radeon Graphics")
        echo -e "  • GPU:                       ${CYAN}${gpu_info}${NC}"
    fi

    # RAM y ZRAM
    if command -v free &>/dev/null; then
        local ram_total swap_total
        ram_total=$(LC_ALL=C free -h | awk '/^Mem:/ {print $2}')
        swap_total=$(LC_ALL=C free -h | awk '/^Swap:/ {print $2}')
        echo -e "  • Memoria / Swap:            ${CYAN}${ram_total} RAM DDR4 / ${swap_total} ZRAM Swap (zstd)${NC}"
    fi

    # Pantalla y Wayland
    local wm_session="${XDG_SESSION_TYPE:-wayland}"
    local de_name="${XDG_CURRENT_DESKTOP:-GNOME}"
    echo -e "  • Entorno de Escritorio:     ${CYAN}${de_name} sobre ${wm_session} (Mutter)${NC}"

    # Batería
    if [[ -d /sys/class/power_supply ]]; then
        local bat
        bat=$(ls /sys/class/power_supply/ 2>/dev/null | grep -E '^BAT' | head -n1 || true)
        if [[ -n "$bat" ]]; then
            local capacity
            capacity=$(cat "/sys/class/power_supply/$bat/capacity" 2>/dev/null || echo "?")
            local status
            status=$(cat "/sys/class/power_supply/$bat/status" 2>/dev/null || echo "?")
            echo -e "  • Batería ($bat):            ${CYAN}${capacity}% [${status}]${NC}"
        fi
    fi

    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 6. MENÚ INTERACTIVO
# ------------------------------------------------------------------------------
run_interactive_menu() {
    while true; do
        echo -e "\n${BOLD}======================================================================${NC}"
        echo -e "  🎨 ${BOLD}SELECTOR INTERACTIVO DE TEMAS FASTFETCH - CACHYOS WORKSTATION${NC}"
        echo -e "${BOLD}======================================================================${NC}"
        echo -e "  1) ${CYAN}cachyos${NC}        - Hero categorizado con barras CachyOS Cyan [Recomendado]"
        echo -e "  2) ${CYAN}cachyos-simple${NC} - Minimalista limpio con logo compacto"
        echo -e "  3) ${CYAN}modern${NC}         - Logo amplio con flechas Nerd Font y acento Sapphire"
        echo -e "  4) ${CYAN}compact${NC}        - Ultra-compacto enmarcado estilo FastCat"
        echo -e "  p) Previsualizar un tema antes de aplicar"
        echo -e "  q) Salir sin aplicar cambios"
        echo -e "${BOLD}----------------------------------------------------------------------${NC}"
        read -rp "Selecciona una opción [1-4 / p / q]: " choice

        case "${choice:-1}" in
            1) THEME="cachyos"; FORCE=true; break ;;
            2) THEME="cachyos-simple"; FORCE=true; break ;;
            3) THEME="modern"; FORCE=true; break ;;
            4) THEME="compact"; FORCE=true; break ;;
            p|P)
                read -rp "Tema a previsualizar (cachyos/cachyos-simple/modern/compact) [cachyos]: " prev_choice
                local ptheme="${prev_choice:-cachyos}"
                local pfile
                pfile=$(resolve_theme_file "$ptheme")
                echo ""
                log_info "Previsualizando tema '$ptheme'..."
                fastfetch --config "$pfile" || true
                ;;
            q|Q)
                log_info "Operación cancelada por el usuario."
                exit 0
                ;;
            *)
                log_warn "Opción no reconocida: '$choice'. Selecciona 1, 2, 3, 4, p o q."
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# 7. PROCESAMIENTO DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)      ACTION="status"; shift ;;
        -l|--list-themes) ACTION="list"; shift ;;
        -r|--run)         ACTION="run"; shift ;;
        -b|--backup)      ACTION="backup"; shift ;;
        -m|--menu)        ACTION="menu"; shift ;;
        -f|--force)       FORCE=true; shift ;;
        -t|--theme)
            if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                THEME="$2"
                FORCE=true
                shift 2
            else
                log_err "Falta el nombre del tema para --theme."
                exit 1
            fi
            ;;
        -p|--preview)
            if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                THEME="$2"
                shift 2
            else
                THEME="cachyos"
                shift
            fi
            ACTION="preview"
            ;;
        -d|--diff)
            if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                THEME="$2"
                shift 2
            else
                THEME="cachyos"
                shift
            fi
            ACTION="diff"
            ;;
        -h|--help)        show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

# ------------------------------------------------------------------------------
# 8. EJECUCIÓN DE ACCIONES INMEDIATAS
# ------------------------------------------------------------------------------
case "$ACTION" in
    status)
        show_status
        exit 0
        ;;
    list)
        list_themes
        exit 0
        ;;
    run)
        if [[ -f "$DEST_FILE" ]]; then
            exec fastfetch --config "$DEST_FILE"
        else
            exec fastfetch
        fi
        ;;
    backup)
        if [[ -f "$DEST_FILE" ]]; then
            cp "$DEST_FILE" "${DEST_FILE}.bak"
            log_ok "Copia de seguridad creada en: ${DEST_FILE}.bak"
        else
            log_warn "No existe ${DEST_FILE} para respaldar."
        fi
        exit 0
        ;;
    diff)
        SRC_FILE=$(resolve_theme_file "$THEME")
        if [[ -f "$DEST_FILE" ]]; then
            echo -e "${BOLD}Comparando configuración activa con plantilla '${THEME}':${NC}"
            diff -u --color=always "$DEST_FILE" "$SRC_FILE" || true
        else
            log_warn "No existe ${DEST_FILE} todavía."
        fi
        exit 0
        ;;
    preview)
        SRC_FILE=$(resolve_theme_file "$THEME")
        validate_theme_file "$SRC_FILE"
        log_info "Previsualizando tema '${THEME}' (${SRC_FILE})..."
        exec fastfetch --config "$SRC_FILE"
        ;;
    menu)
        run_interactive_menu
        ;;
esac

# ------------------------------------------------------------------------------
# 9. INSTALACIÓN DE FASTFETCH (PACMAN CACHYOS)
# ------------------------------------------------------------------------------
if ! pacman -Q fastfetch &>/dev/null; then
    log_info "Instalando Fastfetch en CachyOS mediante Pacman..."
    $SUDO pacman -S --needed --noconfirm fastfetch
    log_ok "Fastfetch instalado correctamente."
fi

# ------------------------------------------------------------------------------
# 10. SINCRONIZACIÓN Y DESPLIEGUE DEL TEMA SELECCIONADO
# ------------------------------------------------------------------------------
# Mantener sincronizado config.jsonc en el repositorio con config-cachyos.jsonc
if [[ -f "$SCRIPT_DIR/config-cachyos.jsonc" && -w "$SCRIPT_DIR" ]]; then
    cp "$SCRIPT_DIR/config-cachyos.jsonc" "$SCRIPT_DIR/config.jsonc" 2>/dev/null || true
fi

SRC_FILE=$(resolve_theme_file "$THEME")
validate_theme_file "$SRC_FILE"

mkdir -p "$DEST_DIR"

if [[ -f "$DEST_FILE" && "$FORCE" == false ]]; then
    if cmp -s "$SRC_FILE" "$DEST_FILE"; then
        log_ok "El tema '$THEME' ya está activo y actualizado en $DEST_FILE."
    else
        cp "$DEST_FILE" "${DEST_FILE}.bak"
        cp "$SRC_FILE" "$DEST_FILE"
        log_ok "Tema '$THEME' aplicado en $DEST_FILE (copia previa en ${DEST_FILE}.bak)."
    fi
else
    if [[ -f "$DEST_FILE" ]]; then
        cp "$DEST_FILE" "${DEST_FILE}.bak"
    fi
    cp "$SRC_FILE" "$DEST_FILE"
    log_ok "Tema '$THEME' desplegado con éxito en $DEST_FILE."
fi

# Ajustar permisos si fue ejecutado mediante sudo
if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
    chown -R "$REAL_USER:$REAL_USER" "$DEST_DIR"
fi

# ------------------------------------------------------------------------------
# 11. VERIFICACIÓN Y PREVISUALIZACIÓN FINAL
# ------------------------------------------------------------------------------
echo ""
fastfetch --config "$DEST_FILE" || true
