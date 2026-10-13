#!/usr/bin/env bash
# ==============================================================================
# angular.sh - Instalación de Angular CLI vía Mise para Fedora 44
# Optimizado para KDE Plasma 6 y Bash / Zsh (Node.js LTS)
# ==============================================================================

set -euo pipefail

# Colores ANSI para terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PRIVILEGIOS
# ------------------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export NG_CLI_ANALYTICS=false

# Exportar PATH para este proceso
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/bin:$PATH"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" COREPACK_ENABLE_DOWNLOAD_PROMPT=0 NG_CLI_ANALYTICS=false PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        COREPACK_ENABLE_DOWNLOAD_PROMPT=0 NG_CLI_ANALYTICS=false PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    fi
}

show_help() {
    cat <<EOF
🅰️ Gestor e Instalador de Angular CLI (Latest) - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala la última versión oficial de Angular CLI vía Mise,
                      desactiva telemetría interactiva y configura autocompletados.
  --status, -s        Muestra el diagnóstico de Angular CLI, Node.js y autocompletado.
  --update, -u        Actualiza Angular CLI (@angular/cli@latest) y refresca shims.
  --help, -h          Muestra este mensaje de ayuda.

Características configuradas:
  • Angular CLI Latest: Gestionado de forma aislada e independiente con Mise.
  • Rendimiento:        NG_CLI_ANALYTICS=false para eliminar bloqueos interactivos.
  • Integración KDE:    Variables en ~/.bashrc.d/angular.sh y completado nativo Bash/Zsh.
EOF
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 ESTADO DE ANGULAR CLI - FEDORA 44 (KDE PLASMA 6)${NC}"
    echo -e "${CYAN}=================================================================${NC}"
    if command -v ng &>/dev/null || run_as_user mise which ng &>/dev/null; then
        local ng_ver
        ng_ver=$(run_as_user mise exec node@lts -- ng version 2>/dev/null | grep -E "Angular CLI:" | awk '{print $3}' || echo "Instalado")
        echo -e "• ${BOLD}Angular CLI:${NC}         ${GREEN}✅ v$ng_ver${NC}"
        echo -e "• ${BOLD}Ruta binario ng:${NC}     $(run_as_user which ng 2>/dev/null || echo 'vía mise shims')"
        echo -e "• ${BOLD}Node.js asociado:${NC}    $(run_as_user node --version 2>/dev/null || echo 'No detectado')"
        echo -e "• ${BOLD}Telemetría:${NC}          Desactivada (NG_CLI_ANALYTICS=false)"
        echo -e "• ${BOLD}Autocompletado Bash:${NC} $([ -f "$USER_HOME/.local/share/bash-completion/completions/ng" ] && echo -e "${GREEN}✅ Activo${NC}" || echo -e "${YELLOW}ℹ️ Pendiente${NC}")"
    else
        echo -e "• ${BOLD}Angular CLI:${NC}         ${RED}❌ No instalado en el sistema${NC}"
    fi
    echo -e "${CYAN}=================================================================${NC}"
}

ensure_node() {
    if ! command -v mise &> /dev/null && [ ! -x "$USER_HOME/.local/bin/mise" ]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -f "$script_dir/../mise.sh" ]; then
            echo -e "${BLUE}ℹ️ Mise no encontrado. Ejecutando $script_dir/../mise.sh...${NC}"
            bash "$script_dir/../mise.sh"
        else
            echo -e "${RED}❌ Error: 'mise' no está instalado. Ejecuta ./mise.sh primero.${NC}"
            exit 1
        fi
    fi

    if ! run_as_user mise list node 2>/dev/null | grep -q "node" && ! command -v node &> /dev/null; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -f "$script_dir/../nodejs.sh" ]; then
            echo -e "${BLUE}ℹ️ Node.js LTS no encontrado. Ejecutando $script_dir/../nodejs.sh...${NC}"
            bash "$script_dir/../nodejs.sh"
        else
            echo -e "${BLUE}ℹ️ Instalando Node.js LTS vía Mise...${NC}"
            run_as_user mise use --global node@lts
        fi
    fi
}

update_angular() {
    echo -e "${BLUE}🔄 Actualizando Angular CLI a la última versión vía Mise...${NC}"
    ensure_node
    run_as_user mise install npm:@angular/cli@latest
    run_as_user mise use --global npm:@angular/cli@latest
    run_as_user mise exec node@lts -- ng config -g cli.analytics false 2>/dev/null || true
    run_as_user mise reshim 2>/dev/null || true
    echo -e "${GREEN}✅ Angular CLI actualizado con éxito.${NC}"
    show_status
}

install_angular() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🅰️ INSTALANDO ANGULAR CLI (LATEST) - FEDORA 44 (KDE PLASMA 6)${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    ensure_node

    # 1. Instalación de Angular CLI global en Mise
    echo -e "${BLUE}ℹ️ [1/3] Instalando última versión de Angular CLI vía Mise...${NC}"
    run_as_user mise use --global npm:@angular/cli@latest

    # 2. Desactivar telemetría interactiva de Angular CLI para evitar bloqueos
    echo -e "${BLUE}ℹ️ [2/3] Desactivando telemetría interactiva de Angular CLI...${NC}"
    run_as_user mise exec node@lts -- ng config -g cli.analytics false 2>/dev/null || true
    run_as_user mise reshim 2>/dev/null || true

    # 3. Integración en Shells y Autocompletados
    echo -e "${BLUE}ℹ️ [3/3] Configurando variables y autocompletados en Bash y Zsh...${NC}"
    local bashrc_d="$USER_HOME/.bashrc.d"
    run_as_user mkdir -p "$bashrc_d"

    cat << 'EOF' | run_as_user tee "$bashrc_d/angular.sh" > /dev/null
# Angular CLI Analytics Opt-Out
export NG_CLI_ANALYTICS=false
EOF

    if [ -f "$USER_HOME/.zshrc" ]; then
        local zshrc_d="$USER_HOME/.zshrc.d"
        run_as_user mkdir -p "$zshrc_d"
        cat << 'EOF' | run_as_user tee "$zshrc_d/angular.zsh" > /dev/null
# Angular CLI Analytics Opt-Out
export NG_CLI_ANALYTICS=false
EOF
    fi

    # Autocompletado nativo para Bash
    local bash_comp_dir="$USER_HOME/.local/share/bash-completion/completions"
    run_as_user mkdir -p "$bash_comp_dir"
    if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
        run_as_user mise exec node@lts -- ng completion script > "$bash_comp_dir/ng" 2>/dev/null || true
    fi

    # Autocompletado para Zsh (si existe ~/.zshrc)
    if [ -f "$USER_HOME/.zshrc" ]; then
        local zsh_comp_dir="$USER_HOME/.local/share/zsh/site-functions"
        local zfunc_dir="$USER_HOME/.zfunc"
        run_as_user mkdir -p "$zsh_comp_dir" "$zfunc_dir"

        if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
            run_as_user mise exec node@lts -- ng completion script > "$zsh_comp_dir/_ng" 2>/dev/null || true
            run_as_user mise exec node@lts -- ng completion script > "$zfunc_dir/_ng" 2>/dev/null || true
        fi
    fi

    local ng_ver
    ng_ver=$(run_as_user mise exec node@lts -- ng version 2>/dev/null | grep -E "Angular CLI:" | awk '{print $3}' || echo "instalado")

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${GREEN}✅ Angular CLI configurado con éxito para Fedora 44 y KDE Plasma 6:${NC}"
    echo -e "  • Angular CLI: v$ng_ver"
    echo -e "  • Node Runtime: Node.js LTS (~/.local/share/mise/shims)"
    echo -e "  • Telemetría:  Desactivada (sin prompts interactivos)"
    echo -e "  • Shells:      Autocompletado habilitado para Bash$([ -f "$USER_HOME/.zshrc" ] && echo " y Zsh")"
    echo -e "${CYAN}=================================================================${NC}"
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    --update|-u|update)
        update_angular
        exit 0
        ;;
    "")
        install_angular
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida:${NC} ${1}"
        show_help
        exit 1
        ;;
esac
