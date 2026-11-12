#!/usr/bin/env bash
# =============================================================================
# Script de Configuración Multi-Monitor para Omarchy 4.5 (Hyprland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U + Radeon Graphics Vega 8)
#
# Topología:
#   - DP-3:  LG 32" (Principal, 1920x1080 @ 60Hz, Pos: 0x0) -> Workspaces 1..5
#   - DP-4:  SONY 32" TV (Lateral derecha, 1920x1080 @ 60Hz, Pos: 1920x0) -> Workspaces 6, 7
#   - eDP-1: Portátil 15.6" (Inferior, 1920x1080 @ 60Hz, Pos: 0x1080) -> Workspaces 8, 9
# =============================================================================

set -euo pipefail

# Colores para mensajes de consola
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Rutas de configuración
readonly HYPR_DIR="${HOME}/.config/hypr"
readonly MONITORS_LUA="${HYPR_DIR}/monitors.lua"

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

show_help() {
    cat <<EOF
Uso: $(basename "$0") [OPCIÓN]

Opciones:
  --apply, -a    Aplica la configuración de monitores (predeterminado)
  --status, -s   Muestra el estado físico de los conectores y la sesión
  --help, -h     Muestra este mensaje de ayuda

Topología aplicada:
  [ LG 32" (DP-3) (0,0) ]       [ SONY 32" (DP-4) (1920,0) ]
  [ Portátil (eDP-1) (0,1080) ]
EOF
}

check_status() {
    echo -e "${CYAN}=== Diagnóstico de Monitores (DRM / Hyprland) ===${NC}"
    for mon in DP-3 DP-4 eDP-1; do
        local status_file="/sys/class/drm/card1-${mon}/status"
        if [[ -f "$status_file" ]]; then
            local st
            st=$(cat "$status_file")
            if [[ "$st" == "connected" ]]; then
                echo -e "  - Conector ${YELLOW}${mon}${NC}: ${GREEN}Conectado (${st})${NC}"
            else
                echo -e "  - Conector ${YELLOW}${mon}${NC}: ${RED}Desconectado (${st})${NC}"
            fi
        else
            echo -e "  - Conector ${YELLOW}${mon}${NC}: ${RED}No detectado en /sys/class/drm${NC}"
        fi
    done

    echo ""
    if command -v hyprctl &>/dev/null; then
        if hyprctl monitors &>/dev/null; then
            info "Sesión activa de Hyprland detectada. Monitores actuales reportados por hyprctl:"
            hyprctl monitors | grep -E "(Monitor|at |workspace)" || true
        else
            info "Hyprland instalado pero no hay sesión activa en este TTY."
        fi
    else
        warn "Comando hyprctl no disponible en PATH."
    fi
}

apply_monitors() {
    info "Configurando topología multi-monitor para Omarchy..."

    mkdir -p "${HYPR_DIR}"

    # Backup si el archivo ya existe
    if [[ -f "${MONITORS_LUA}" ]]; then
        local backup_file="${MONITORS_LUA}.bak.$(date +%Y%m%d%H%M%S)"
        cp "${MONITORS_LUA}" "${backup_file}"
        info "Backup creado en: ${backup_file}"
    fi

    info "Escribiendo configuración en ${MONITORS_LUA}..."
    cat > "${MONITORS_LUA}" << 'EOF'
-- ~/.config/hypr/monitors.lua
-- Topología Triple Monitor para HP ProBook 455 G10 en Omarchy 4.5
-- Generado automáticamente por Setup/monitors-setup.sh

-- Desactivar sobreescritura del panel GUI para respetar estrictamente las coordenadas Lua
omarchy_monitor_panel_settings = false

local omarchy_monitor_scale = 1
local omarchy_gdk_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- =============================================================================
-- 1. POSICIONAMIENTO DE MONITORES
-- =============================================================================

-- LG 32" FHD (Principal) - Coordenada (0, 0)
hl.monitor({
  output = "DP-3",
  mode = "1920x1080@60",
  position = "0x0",
  scale = omarchy_monitor_scale,
})

-- Sony 32" TV FHD (A la derecha de LG) - Coordenada (1920, 0)
hl.monitor({
  output = "DP-4",
  mode = "1920x1080@60",
  position = "1920x0",
  scale = omarchy_monitor_scale,
})

-- Pantalla Integrada Portátil 15.6" FHD (Debajo de LG) - Coordenada (0, 1080)
hl.monitor({
  output = "eDP-1",
  mode = "1920x1080@60",
  position = "0x1080",
  scale = omarchy_monitor_scale,
})

-- Fallback genérico para pantallas auxiliares
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- =============================================================================
-- 2. ASIGNACIÓN ESTRICTA DE WORKSPACES
-- =============================================================================

-- DP-3 (LG 32" Principal) -> Workspaces 1..5
hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-3", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-3", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-3", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-3", persistent = true })

-- DP-4 (Sony 32" Derecha) -> Workspaces 6 y 7
hl.workspace_rule({ workspace = "6", monitor = "DP-4", default = true, persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "DP-4", persistent = true })

-- eDP-1 (Portátil 15.6" Abajo) -> Workspaces 8 y 9
hl.workspace_rule({ workspace = "8", monitor = "eDP-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "eDP-1", persistent = true })
EOF

    success "Archivo ${MONITORS_LUA} actualizado con éxito."

    # Si Hyprland está en ejecución, recargar la configuración
    if command -v hyprctl &>/dev/null && hyprctl monitors &>/dev/null; then
        info "Recargando configuración en caliente en la sesión activa de Hyprland..."
        hyprctl reload >/dev/null 2>&1 || true
        success "Hyprland recargado correctamente."
    else
        info "Hyprland no tiene sesión gráfica activa en este shell. Los cambios se aplicarán al iniciar sesión o recargar con 'hyprctl reload'."
    fi
}

main() {
    local action="apply"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status|-s)
                action="status"
                shift
                ;;
            --apply|-a)
                action="apply"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Opción desconocida: $1"
                show_help
                exit 1
                ;;
        esac
    done

    case "$action" in
        status)
            check_status
            ;;
        apply)
            apply_monitors
            ;;
    esac
}

main "$@"
