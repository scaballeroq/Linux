#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  fastfetch.sh - Instalador y Gestor de Temas de Fastfetch
#  Sistema: CachyOS Workstation (GNOME Shell Wayland)
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

if [[ $EUID -eq 0 ]]; then
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
else
    REAL_USER="${USER:-$(whoami)}"
fi
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

DEST_DIR="$USER_HOME/.config/fastfetch"
DEST_FILE="$DEST_DIR/config.jsonc"

THEME="cachyos"
FORCE=false
ACTION="install"

resolve_theme_file() {
    local t="$1"
    case "$t" in
        cachyos|hero|default) echo "$SCRIPT_DIR/config-cachyos.jsonc" ;;
        cachyos-simple|simple) echo "$SCRIPT_DIR/config-cachyos-simple.jsonc" ;;
        modern) echo "$SCRIPT_DIR/config-modern.jsonc" ;;
        compact|fastcat) echo "$SCRIPT_DIR/config-compact.jsonc" ;;
        *)
            log_err "Tema desconocido: '$t'. Usa: cachyos, cachyos-simple, modern o compact."
            exit 1
            ;;
    esac
}

show_help() {
    cat << EOF
${BOLD}📊 Gestor e Instalador de Fastfetch - CachyOS Workstation (GNOME Wayland)${NC}

Instala Fastfetch mediante Pacman y despliega temas personalizados para CachyOS
con paleta oficial ${BOLD}CachyOS Cyan/Emerald${NC}, barras de progreso y telemetría Wayland.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)           Instala Fastfetch y aplica el tema 'cachyos' (Hero categorizado)
  -t, --theme <nombre>       Selecciona el tema: cachyos | cachyos-simple | modern | compact
  -p, --preview [tema]       Previsualiza un tema en consola sin modificar ~/.config/fastfetch
  -m, --menu                 Selector interactivo con previsualización en vivo
  -l, --list-themes          Lista todos los temas disponibles en el repositorio
  -r, --run                  Ejecuta fastfetch con la configuración actual
  -d, --diff                 Compara el archivo activo con la plantilla del repositorio
  -f, --force                Sobrescribe ~/.config/fastfetch/config.jsonc sin preguntar
  -s, --status               Muestra el estado actual de Fastfetch y el tema activo
  -h, --help                 Muestra esta ayuda
EOF
}

list_themes() {
    echo -e "${BOLD}🎨 Temas disponibles para Fastfetch (CachyOS Workstation):${NC}"
    echo -e "  • ${CYAN}cachyos${NC}         -> Tema Hero categorizado (HARDWARE / SYSTEM / THEMING & DESKTOP) con barras y CachyOS Cyan [Por defecto]"
    echo -e "  • ${CYAN}cachyos-simple${NC}  -> Tema minimalista limpio con logo pequeño de CachyOS"
    echo -e "  • ${CYAN}modern${NC}         -> Tema amplio con logo completo y flechas Nerd Font"
    echo -e "  • ${CYAN}compact${NC}        -> Tema compacto horizontal de lectura rápida"
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  📊 ${BOLD}ESTADO DE FASTFETCH - CACHYOS WORKSTATION (GNOME WAYLAND)${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if command -v fastfetch &>/dev/null; then
        echo -e "  • Binario Fastfetch:         ${GREEN}$(fastfetch --version)${NC}"
    else
        echo -e "  • Binario Fastfetch:         ${RED}No instalado${NC}"
    fi

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
        echo -e "  • Configuración activa:      ${GREEN}${DEST_FILE}${NC}"
        echo -e "  • Tema detectado:            ${CYAN} ${active_theme} (CachyOS GNOME Wayland)${NC}"
    else
        echo -e "  • Configuración activa:      ${YELLOW}No configurada${NC}"
    fi
    echo -e "${BOLD}======================================================================${NC}"
}

run_interactive_menu() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🎨 ${BOLD}SELECTOR INTERACTIVO DE TEMAS FASTFETCH - CACHYOS WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"
    list_themes
    echo ""
    echo "  1) cachyos (Hero categorizado con barras)"
    echo "  2) cachyos-simple (Minimalista)"
    echo "  3) modern (Logo grande)"
    echo "  4) compact (Compacto)"
    read -rp "Selecciona el tema a aplicar [1]: " choice
    case "${choice:-1}" in
        2) THEME="cachyos-simple" ;;
        3) THEME="modern" ;;
        4) THEME="compact" ;;
        *) THEME="cachyos" ;;
    esac
    FORCE=true
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)      ACTION="status"; shift ;;
        -l|--list-themes) ACTION="list"; shift ;;
        -r|--run)         ACTION="run"; shift ;;
        -d|--diff)        ACTION="diff"; shift ;;
        -m|--menu)        ACTION="menu"; shift ;;
        -f|--force)       FORCE=true; shift ;;
        -t|--theme)       THEME="${2:-cachyos}"; FORCE=true; shift 2 ;;
        -p|--preview)
            if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                THEME="$2"
                shift 2
            else
                shift
            fi
            ACTION="preview"
            ;;
        -h|--help)        show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

case "$ACTION" in
    status) show_status; exit 0 ;;
    list)   list_themes; exit 0 ;;
    run)    exec fastfetch ;;
    preview)
        SRC_FILE=$(resolve_theme_file "$THEME")
        log_info "Previsualizando tema '$THEME' ($SRC_FILE)..."
        exec fastfetch --config "$SRC_FILE"
        ;;
    diff)
        SRC_FILE=$(resolve_theme_file "$THEME")
        if [[ -f "$DEST_FILE" ]]; then
            diff -u "$DEST_FILE" "$SRC_FILE" || true
        else
            log_warn "No existe $DEST_FILE todavía."
        fi
        exit 0
        ;;
    menu)
        run_interactive_menu
        ;;
esac

if ! command -v fastfetch &>/dev/null; then
    log_info "Instalando fastfetch en CachyOS (Pacman)..."
    sudo pacman -S --needed --noconfirm fastfetch
fi

# Mantener sincronizado config.jsonc por defecto en el repositorio con config-cachyos.jsonc
cp "$SCRIPT_DIR/config-cachyos.jsonc" "$SCRIPT_DIR/config.jsonc" 2>/dev/null || true

SRC_FILE=$(resolve_theme_file "$THEME")
mkdir -p "$DEST_DIR"

if [[ -f "$DEST_FILE" && "$FORCE" == false ]]; then
    if cmp -s "$SRC_FILE" "$DEST_FILE"; then
        log_ok "El tema '$THEME' ya está activo y actualizado en $DEST_FILE."
    else
        cp "$DEST_FILE" "${DEST_FILE}.bak"
        cp "$SRC_FILE" "$DEST_FILE"
        log_ok "Tema '$THEME' aplicado en $DEST_FILE (backup en ${DEST_FILE}.bak)."
    fi
else
    cp "$SRC_FILE" "$DEST_FILE"
    log_ok "Tema '$THEME' instalado en $DEST_FILE."
fi

if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
    chown -R "$REAL_USER:$REAL_USER" "$DEST_DIR"
fi

echo ""
fastfetch --config "$DEST_FILE" || true
